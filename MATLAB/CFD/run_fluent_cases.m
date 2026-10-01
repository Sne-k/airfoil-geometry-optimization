function T = run_fluent_cases(meshFile, alphas, varargin)
%RUN_FLUENT_CASES  Runs Fluent in batch mode for several angles of attack.
%   T = RUN_FLUENT_CASES(meshFile, alphas) writes one journal per angle
%   (fluentJournal), runs Fluent (2-D, double precision, 4 processes) in
%   the folder of the mesh and reads the force coefficients from the
%   transcript. T has one row per angle: alpha, CL and CD after the last
%   block, their change over the last block (a convergence measure), the
%   number of blocks read, the run time and the transcript file. The table
%   is also written next to the mesh (<Tag><mesh name>_forces.csv).
%
%   Options (name, value): 'Fluent' path of fluent.exe (default: environment
%   variable FLUENT_EXE), 'Processes' (4), 'Tag' (prefix of the file names,
%   ''); all other options are passed to fluentJournal ('Model', 'Re',
%   'Mach', ...).

ip = inputParser;
ip.KeepUnmatched = true;
ip.addParameter('Fluent', getenv('FLUENT_EXE'));
ip.addParameter('Processes', 4);
ip.addParameter('Tag', '');
ip.parse(varargin{:});
o = ip.Results;
jopts = reshape([fieldnames(ip.Unmatched)'; struct2cell(ip.Unmatched)'], 1, []);
if isempty(o.Fluent) || ~isfile(o.Fluent)
    error('run_fluent_cases:fluent', 'fluent.exe not found; set FLUENT_EXE or pass ''Fluent''.');
end
[folder, meshName, ext] = fileparts(meshFile);
answers = fullfile(folder, 'fluent_exit.txt');
fid = fopen(answers, 'w');  fprintf(fid, '/exit yes\n');  fclose(fid);   % stdin: never wait for input

rows = cell(numel(alphas), 1);
for k = 1:numel(alphas)
    a = alphas(k);
    tag = strrep(sprintf('%s%s_a%g', o.Tag, meshName, a), '-', 'm');
    tag = strrep(tag, '.', 'p');
    fluentJournal(fullfile(folder, [tag '.jou']), [meshName ext], a, jopts{:});
    cmd = sprintf('cd /d "%s" && "%s" 2ddp -g -t%d -wait -i "%s.jou" < "%s" > "%s.out" 2>&1', ...
        folder, o.Fluent, o.Processes, tag, answers, tag);
    t0 = tic;
    system(cmd);
    secs = toc(t0);
    [cd, cl] = fluentForces(fullfile(folder, [tag '.out']));
    if isempty(cd)
        rows{k} = {a, NaN, NaN, NaN, NaN, 0, secs, [tag '.out']};
    elseif numel(cd) == 1
        rows{k} = {a, cl(end), cd(end), NaN, NaN, 1, secs, [tag '.out']};
    else
        rows{k} = {a, cl(end), cd(end), cl(end) - cl(end-1), cd(end) - cd(end-1), numel(cd), secs, [tag '.out']};
    end
    fprintf('%s: CL %.4f, CD %.5f (%d blocks, %.0f s)\n', tag, rows{k}{2}, rows{k}{3}, rows{k}{6}, secs);
end
T = cell2table(vertcat(rows{:}), 'VariableNames', {'alpha', 'CL', 'CD', 'dCL_last_block', ...
    'dCD_last_block', 'blocks', 'seconds', 'transcript'});
writetable(T, fullfile(folder, [o.Tag meshName '_forces.csv']));
end
