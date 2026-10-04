function [T, H] = run_fluent_cases(meshFile, alphas, varargin)
%RUN_FLUENT_CASES  Runs Fluent in batch mode for several angles of attack.
%   T = RUN_FLUENT_CASES(meshFile, alphas) writes one journal per angle
%   (fluentJournal), runs Fluent (2-D, double precision, 4 processes) in
%   the folder of the mesh and reads the force coefficients from the
%   transcript. T has one row per angle: alpha, CL and CD after the last
%   block, their change over the last block, the number of force reports
%   read, the run time, the transcript file, and the mean and the range
%   (maximum minus minimum) of CL and CD over the last second-order reports
%   (a convergence measure: a converged steady solution has a range near
%   zero). The table is also written next to the mesh
%   (<Tag><mesh name>_forces.csv).
%
%   [T, H] = RUN_FLUENT_CASES(...) also returns the history H with one row
%   per force report: alpha, iteration, order (1 or 2), CL, CD and the
%   transcript (written as <Tag><mesh name>_history.csv).
%
%   Options (name, value): 'Fluent' path of fluent.exe (default: environment
%   variable FLUENT_EXE), 'Processes' (4), 'Tag' (prefix of the file names,
%   ''), 'Sweep' (false; true runs all angles in one session, each angle
%   continuing from the solution of the previous one), 'Tail' (10, number of
%   reports for the mean and the range); all other options are passed to
%   fluentJournal ('Model', 'Re', 'Mach', ...).

ip = inputParser;
ip.KeepUnmatched = true;
ip.addParameter('Fluent', getenv('FLUENT_EXE'));
ip.addParameter('Processes', 4);
ip.addParameter('Tag', '');
ip.addParameter('Sweep', false);
ip.addParameter('Tail', 10);
ip.parse(varargin{:});
o = ip.Results;
jopts = reshape([fieldnames(ip.Unmatched)'; struct2cell(ip.Unmatched)'], 1, []);
if isempty(o.Fluent) || ~isfile(o.Fluent)
    error('run_fluent_cases:fluent', 'fluent.exe not found; set FLUENT_EXE or pass ''Fluent''.');
end
[folder, meshName, ext] = fileparts(meshFile);
answers = fullfile(folder, 'fluent_exit.txt');
fid = fopen(answers, 'w');  fprintf(fid, '/exit yes\n');  fclose(fid);   % stdin: never wait for input

alphas = alphas(:).';
if o.Sweep, sessions = {alphas}; else, sessions = num2cell(alphas); end
rows = {};
hist = {};
for k = 1:numel(sessions)
    a = sessions{k};
    if o.Sweep, name = 'sweep'; else, name = sprintf('a%g', a); end
    tag = strrep(sprintf('%s%s_%s', o.Tag, meshName, name), '-', 'm');
    tag = strrep(tag, '.', 'p');
    plan = fluentJournal(fullfile(folder, [tag '.jou']), [meshName ext], a, jopts{:});
    cmd = sprintf('cd /d "%s" && "%s" 2ddp -g -t%d -wait -i "%s.jou" < "%s" > "%s.out" 2>&1', ...
        folder, o.Fluent, o.Processes, tag, answers, tag);
    t0 = tic;
    system(cmd);
    [cd, cl] = readForces(fullfile(folder, [tag '.out']));
    if isempty(cd)                        % e.g. the licence of the previous session was not free yet
        pause(120);
        system(cmd);
        [cd, cl] = readForces(fullfile(folder, [tag '.out']));
    end
    secs = toc(t0);
    n = min(numel(cd), height(plan));
    h = plan(1:n, :);
    h.CL = reshape(cl(1:n), n, 1);
    h.CD = reshape(cd(1:n), n, 1);
    h.transcript = repmat({[tag '.out']}, n, 1);
    hist{end+1} = h; %#ok<AGROW>
    for a1 = a
        ha = h(h.alpha == a1, :);
        if any(ha.order == 2), tail = ha(ha.order == 2, :); else, tail = ha; end
        tail = tail(max(1, end - o.Tail + 1):end, :);
        m = height(ha);
        if m == 0
            rows(end+1, :) = {a1, NaN, NaN, NaN, NaN, 0, secs, [tag '.out'], NaN, NaN, NaN, NaN, 0}; %#ok<AGROW>
            continue
        end
        if m == 1, dcl = NaN; dcd = NaN; else, dcl = ha.CL(end) - ha.CL(end-1); dcd = ha.CD(end) - ha.CD(end-1); end
        rows(end+1, :) = {a1, ha.CL(end), ha.CD(end), dcl, dcd, m, secs, [tag '.out'], ...
            mean(tail.CL), mean(tail.CD), max(tail.CL) - min(tail.CL), max(tail.CD) - min(tail.CD), height(tail)}; %#ok<AGROW>
        fprintf('%s alpha %g: CL %.4f, CD %.5f; last %d reports: CL range %.1e, CD range %.1e (%d reports, %.0f s)\n', ...
            tag, a1, ha.CL(end), ha.CD(end), height(tail), rows{end, 11}, rows{end, 12}, m, secs);
    end
    if n == 0, fprintf('%s: no force reports in the transcript (%.0f s)\n', tag, secs); end
end
T = cell2table(rows, 'VariableNames', {'alpha', 'CL', 'CD', 'dCL_last_block', 'dCD_last_block', ...
    'blocks', 'seconds', 'transcript', 'CL_mean', 'CD_mean', 'CL_range', 'CD_range', 'tail'});
H = vertcat(hist{:});
writetable(T, fullfile(folder, [o.Tag meshName '_forces.csv']));
writetable(H, fullfile(folder, [o.Tag meshName '_history.csv']));
end

function [cd, cl] = readForces(transcript)
if isfile(transcript), [cd, cl] = fluentForces(transcript); else, cd = [];  cl = []; end
end
