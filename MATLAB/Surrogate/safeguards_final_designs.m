% Step 4: the final designs of the benchmark (robust objective, free and tripped) through the safeguards of the
% population study, with the repo code: xfoil_sensitivity_check (exact / rounded coordinates, 160 / 200 nodes,
% friction floor on / off; rerun rule) and collect_population_results (consensus polars at the seven conditions,
% gains against the original). Surrogate and current GA separately, so that the tags do not clash.
% Final designs: surrogate seeds 1-3 = v3 (v4 for the runs that fall back: NACA_0012 s3, S1223 s1-3), seeds 4-10
% = v5 (NACA_2412 s4: v4, same code path); GA seeds 1-3 = benchmark (v1 code), 4-10 = benchmark_v4.
% The runs are staged as <AIRFOIL>_robusttrip_s<k> (the naming of the population study).
W = getenv('AIRFOIL_WORK');                         % work folder with the logged runs (MATLAB/Surrogate/README.md)
if isempty(W), error('Surrogate:work', 'Set the environment variable AIRFOIL_WORK (MATLAB/Surrogate/README.md).'); end
here = fileparts(mfilename('fullpath'));  ML = fileparts(here);  repo = fileparts(ML);   % MATLAB/Surrogate, MATLAB, repo
B = fullfile(W, 'surrogate');
addpath(fullfile(ML, 'Paper'));
setenv('XFOIL_EXE', fullfile(W, 'tools', 'xfoil.exe'));
airfoils = {'NACA_2412', 'NACA_0012', 'NACA_4415', 'CLARK_Y', 'SD7062', 'S1223'};
fallback = {'NACA_0012_3', 'S1223_1', 'S1223_2', 'S1223_3'};
for method = {'surrogate', 'ga'}
    stage = fullfile(B, 'step4', [method{1} '_runs']);
    out = fullfile(B, 'step4', method{1});
    if isfile(fullfile(out, 'conditions.csv')), fprintf('[SKIP] %s\n', out); continue; end
    if ~exist(stage, 'dir'), mkdir(stage); end
    for a = airfoils
        seeds = 1:3;
        if any(strcmp(a{1}, {'NACA_2412', 'S1223'})), seeds = 1:10; end
        for s = seeds
            if strcmp(method{1}, 'ga')
                if s <= 3, src = 'benchmark'; else, src = 'benchmark_v4'; end
            elseif s <= 3
                if any(strcmp(sprintf('%s_%d', a{1}, s), fallback)), src = 'benchmark_v4'; else, src = 'benchmark_v3'; end
            elseif strcmp(a{1}, 'NACA_2412') && s == 4
                src = 'benchmark_v4';
            else
                src = 'benchmark_v5';
            end
            from = fullfile(B, src, sprintf('%s_%s_s%d', a{1}, method{1}, s));
            to = fullfile(stage, sprintf('%s_robusttrip_s%d', a{1}, s));
            if ~isfile(fullfile(from, 'result.mat')), error('step4:missing', 'missing %s', from); end
            if ~exist(to, 'dir'), mkdir(to); end
            copyfile(fullfile(from, 'result.mat'), to);
            copyfile(fullfile(from, 'run_info.json'), to);
            copyfile(fullfile(from, '*_optimized.dat'), to);
            fid = fopen(fullfile(to, 'source.txt'), 'w');  fprintf(fid, '%s\n', from);  fclose(fid);
        end
    end
    fprintf('[STEP 4] %s: %d runs staged\n', method{1}, numel(dir(fullfile(stage, '*_robusttrip_s*'))));
    try
        xfoil_sensitivity_check(stage, out, 8);
        collect_population_results(stage, out, fullfile(W, 'refs', 'uiuc'), 8);
        fprintf('[STEP 4 DONE] %s\n', method{1});
    catch err
        fprintf('[FAILED] step 4 %s: %s\n', method{1}, err.message);
    end
    close all force;
end
