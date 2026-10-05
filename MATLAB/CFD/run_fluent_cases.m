function [T, H] = run_fluent_cases(meshFile, alphas, varargin)
%RUN_FLUENT_CASES  Runs Fluent in batch mode for several angles of attack.
%   T = RUN_FLUENT_CASES(meshFile, alphas) writes one journal per angle
%   (fluentJournal), runs Fluent (2-D, double precision, 4 processes) in
%   the folder of the mesh and reads the force coefficients from the
%   transcript. T has one row per angle: alpha, CL and CD after the last
%   block, their change over the last block, the number of force reports
%   read, the run time, the transcript file, the mean and the range
%   (maximum minus minimum) of CL and CD over the last second-order reports
%   (a convergence measure: a converged steady solution has a range near
%   zero), the scaled residuals at the last iteration (NaN for equations
%   that the model does not have), and the number of force reports that the
%   journal plans (blocks_planned). A session that ends with fewer reports
%   than planned, for example because Fluent ran out of memory, is run once
%   more; if it is still incomplete, a message says so and the row keeps the
%   smaller number of reports. The table is also written next to the mesh
%   (<Tag><mesh name>_forces.csv).
%
%   [T, H] = RUN_FLUENT_CASES(...) also returns the history H with one row
%   per force report: alpha, iteration (the last iteration before the
%   report, as printed by Fluent), order (1 or 2), CL, CD and the
%   transcript (written as <Tag><mesh name>_history.csv).
%
%   Options (name, value): 'Fluent' path of fluent.exe (default: environment
%   variable FLUENT_EXE), 'Processes' (4), 'Tag' (prefix of the file names,
%   ''), 'Sweep' (false; true runs all angles in one session, each angle
%   continuing from the solution of the previous one), 'Tail' (10, number of
%   reports for the mean and the range), 'Reuse' (false; true does not run
%   a session whose journal is unchanged and whose transcript already has
%   all force reports, so an interrupted batch can be started again; the
%   run time is then NaN), 'WriteTables' (true; false does not write the
%   two CSV files), 'Surface' (false; true also writes the pressure
%   coefficient and the wall shear stress on the airfoil to <tag>.prof, see
%   fluentSurface); all other options are passed to
%   fluentJournal ('Model', 'Re', 'Mach', ...). With the option 'Probes' of
%   fluentJournal, T and H also have the turbulence intensity (percent of
%   the free-stream speed), the turbulent viscosity ratio and the speed
%   (m/s) at the probe points (one column per probe; T has the values of
%   the last report).

ip = inputParser;
ip.KeepUnmatched = true;
ip.PartialMatching = false;       % 'Re' must not be taken for 'Reuse'
ip.addParameter('Fluent', getenv('FLUENT_EXE'));
ip.addParameter('Processes', 4);
ip.addParameter('Tag', '');
ip.addParameter('Sweep', false);
ip.addParameter('Tail', 10);
ip.addParameter('Reuse', false);
ip.addParameter('WriteTables', true);
ip.addParameter('Surface', false);
ip.parse(varargin{:});
o = ip.Results;
jopts = reshape([fieldnames(ip.Unmatched)'; struct2cell(ip.Unmatched)'], 1, []);
if isempty(o.Fluent) || ~isfile(o.Fluent)
    error('run_fluent_cases:fluent', 'fluent.exe not found; set FLUENT_EXE or pass ''Fluent''.');
end
nProbes = 0;
if isfield(ip.Unmatched, 'Probes'), nProbes = numel(ip.Unmatched.Probes); end
[folder, meshName, ext] = fileparts(meshFile);
answers = fullfile(folder, 'fluent_exit.txt');
fid = fopen(answers, 'w');  fprintf(fid, '/exit yes\n');  fclose(fid);   % stdin: never wait for input
resNames = {'continuity', 'x_velocity', 'y_velocity', 'energy', 'k', 'omega', 'intermit', 'retheta'};
probeFields = {'Turbulent Intensity', 'Turbulent Viscosity Ratio', 'Velocity Magnitude'};

alphas = alphas(:).';
if o.Sweep, sessions = {alphas}; else, sessions = num2cell(alphas); end
rows = {};
hist = {};
for k = 1:numel(sessions)
    a = sessions{k};
    if o.Sweep, name = 'sweep'; else, name = sprintf('a%g', a); end
    tag = strrep(sprintf('%s%s_%s', o.Tag, meshName, name), '-', 'm');
    tag = strrep(tag, '.', 'p');
    transcript = fullfile(folder, [tag '.out']);
    journal = fullfile(folder, [tag '.jou']);
    if isfile(journal), previous = fileread(journal); else, previous = ''; end
    if o.Surface, surf = {'Surface', tag}; else, surf = {}; end
    plan = fluentJournal(journal, [meshName ext], a, jopts{:}, surf{:});
    [cd, cl, it] = readForces(transcript);
    if o.Reuse && strcmp(previous, fileread(journal)) && numel(cd) >= height(plan)
        secs = NaN;                       % complete run with the same journal
    else
        cmd = sprintf('cd /d "%s" && "%s" 2ddp -g -t%d -wait -i "%s.jou" < "%s" > "%s.out" 2>&1', ...
            folder, o.Fluent, o.Processes, tag, answers, tag);
        t0 = tic;
        system(cmd);
        [cd, cl, it] = readForces(transcript);
        if numel(cd) < height(plan)       % the licence was not free yet, or the session broke off
            fprintf('%s: %d of %d force reports; the session is run once more\n', tag, numel(cd), height(plan));
            pause(120);
            system(cmd);
            [cd, cl, it] = readForces(transcript);
        end
        secs = toc(t0);
    end
    n = min(numel(cd), height(plan));
    h = plan(1:n, :);
    h.iteration = reshape(it(1:n), n, 1);
    h.CL = reshape(cl(1:n), n, 1);
    h.CD = reshape(cd(1:n), n, 1);
    h.transcript = repmat({[tag '.out']}, n, 1);
    if isfile(transcript), R = fluentResiduals(transcript);  P = fluentProbes(transcript); else, R = table();  P = table(); end
    if nProbes > 0                        % three fields at every probe after every force report
        V = nan(nProbes, numel(probeFields), n);
        m = min(n, floor(height(P) / (nProbes * numel(probeFields))));
        V(:, :, 1:m) = reshape(P.value(1:m * nProbes * numel(probeFields)), nProbes, numel(probeFields), m);
        h.Tu_probe = reshape(permute(V(:, 1, :), [3 1 2]), n, nProbes);
        h.visc_ratio_probe = reshape(permute(V(:, 2, :), [3 1 2]), n, nProbes);
        h.speed_probe = reshape(permute(V(:, 3, :), [3 1 2]), n, nProbes);
    end
    hist{end+1} = h; %#ok<AGROW>
    for i = 1:numel(a)
        ha = h(h.alpha == a(i), :);
        m = height(ha);
        res = nan(1, numel(resNames));
        probe = nan(numel(probeFields), nProbes);
        if nProbes > 0 && m > 0
            probe = [ha.Tu_probe(end, :); ha.visc_ratio_probe(end, :); ha.speed_probe(end, :)];
        end
        planned = sum(plan.alpha == a(i));
        if m < planned
            fprintf('%s alpha %g: INCOMPLETE, %d of %d force reports\n', tag, a(i), m, planned);
        end
        if m == 0
            row = {a(i), NaN, NaN, NaN, NaN, 0, secs, [tag '.out'], NaN, NaN, NaN, NaN, 0};
        else
            if any(ha.order == 2), tail = ha(ha.order == 2, :); else, tail = ha; end
            tail = tail(max(1, end - o.Tail + 1):end, :);
            if m == 1, dcl = NaN; dcd = NaN; else, dcl = ha.CL(end) - ha.CL(end-1); dcd = ha.CD(end) - ha.CD(end-1); end
            row = {a(i), ha.CL(end), ha.CD(end), dcl, dcd, m, secs, [tag '.out'], ...
                mean(tail.CL), mean(tail.CD), max(tail.CL) - min(tail.CL), max(tail.CD) - min(tail.CD), height(tail)};
            if ~isempty(R)
                j = find(R.iter == ha.iteration(end), 1, 'last');
                for c = 1:numel(resNames)
                    if ~isempty(j) && ismember(resNames{c}, R.Properties.VariableNames), res(c) = R.(resNames{c})(j); end
                end
            end
            fprintf('%s alpha %g: CL %.4f, CD %.5f; last %d reports: CL range %.1e, CD range %.1e (%d reports, %.0f s)\n', ...
                tag, a(i), ha.CL(end), ha.CD(end), height(tail), row{11}, row{12}, m, secs);
        end
        row = [row, num2cell(res), {planned}]; %#ok<AGROW>
        if nProbes > 0, row = [row, {probe(1, :), probe(2, :), probe(3, :)}]; end %#ok<AGROW>
        rows(end+1, :) = row; %#ok<AGROW>
    end
    if n == 0, fprintf('%s: no force reports in the transcript (%.0f s)\n', tag, secs); end
end
vars = [{'alpha', 'CL', 'CD', 'dCL_last_block', 'dCD_last_block', 'blocks', 'seconds', 'transcript', ...
    'CL_mean', 'CD_mean', 'CL_range', 'CD_range', 'tail'}, strcat('res_', resNames), {'blocks_planned'}];
if nProbes > 0, vars = [vars, {'Tu_probe', 'visc_ratio_probe', 'speed_probe'}]; end
T = cell2table(rows, 'VariableNames', vars);
H = vertcat(hist{:});
if o.WriteTables
    writetable(T, fullfile(folder, [o.Tag meshName '_forces.csv']));
    writetable(H, fullfile(folder, [o.Tag meshName '_history.csv']));
end
end

function [cd, cl, it] = readForces(transcript)
if isfile(transcript), [cd, cl, it] = fluentForces(transcript); else, cd = [];  cl = [];  it = []; end
end
