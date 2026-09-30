function run_paper_batch(outDir)
%RUN_PAPER_BATCH  The optimisation runs behind the results in results/paper.
%   RUN_PAPER_BATCH runs optimize_airfoil for every case below, with three
%   random seeds each (one for 'KeepCLmax'), and writes each run to
%   outDir/<tag> (default MATLAB/output/paper). Runs whose result.mat and
%   run_info.json already exist are skipped, so the batch can be stopped and
%   started again. The 37 runs took 20.7 h on an 8-core laptop with 6
%   parallel workers. collect_paper_results.m makes the tables and figures.
%
%   All cases use the default limits of optimize_airfoil (thickness kept,
%   |CM at 0 deg| may grow by 0.05, curvature limits) unless stated:
%     NACA_2412                 peak CL/CD
%     NACA_2412_nocurv          peak CL/CD without curvature limits
%     NACA_2412_weighted        CL/CD at CL = 0.4 (weight 0.2) and 1.0 (weight
%                               0.8), the task of the Xoptfoil2 benchmark
%     cmp_ga, cmp_pso, cmp_bayesopt   NACA 2412 peak CL/CD, global search only,
%                               40 x 16 = 640 evaluations each (optimiser
%                               comparison at equal budget)
%     NACA_0012, NACA_4412, NACA_23012, CLARK_Y   peak CL/CD
%     NACA_2412_cruise          CL/CD at CL = 0.4
%     NACA_2412_loiter          peak CL^1.5/CD
%     NACA_2412_keepclmax       peak CL/CD without losing maximum lift

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'Optimization'));
if nargin < 1 || isempty(outDir), outDir = fullfile(root, 'output', 'paper'); end
if ~exist(outDir, 'dir'), mkdir(outDir); end
clarky = fullfile(root, 'airfoils', 'clarky.dat');
weighted = {'Objective', 'LDatCL', 'DesignCL', [0.4 1.0], 'Weights', [0.2 0.8]};
cmp = {'LocalSearch', false, 'Population', 40, 'Generations', 15};

runs = {};
for s = 1:3, runs(end+1, :) = {sprintf('NACA_2412_s%d', s), {'NACA 2412', 'Seed', s}}; end %#ok<*AGROW>
for s = 1:3, runs(end+1, :) = {sprintf('NACA_2412_nocurv_s%d', s), {'NACA 2412', 'Seed', s, 'Curvature', false}}; end
for s = 1:3, runs(end+1, :) = {sprintf('NACA_2412_weighted_s%d', s), [{'NACA 2412', 'Seed', s}, weighted]}; end
for alg = {'ga', 'pso', 'bayesopt'}
    for s = 1:3, runs(end+1, :) = {sprintf('cmp_%s_s%d', alg{1}, s), [{'NACA 2412', 'Seed', s, 'Algorithm', alg{1}}, cmp]}; end
end
for foil = {'NACA 0012', 'NACA 4412', 'NACA 23012', clarky}
    if contains(foil{1}, '.dat'), name = 'CLARK_Y'; else, name = strrep(foil{1}, ' ', '_'); end
    for s = 1:3, runs(end+1, :) = {sprintf('%s_s%d', name, s), {foil{1}, 'Seed', s}}; end
end
for s = 1:3, runs(end+1, :) = {sprintf('NACA_2412_cruise_s%d', s), {'NACA 2412', 'Seed', s, 'Objective', 'LDatCL', 'DesignCL', 0.4}}; end
for s = 1:3, runs(end+1, :) = {sprintf('NACA_2412_loiter_s%d', s), {'NACA 2412', 'Seed', s, 'Objective', 'endurance'}}; end
runs(end+1, :) = {'NACA_2412_keepclmax_s1', {'NACA 2412', 'Seed', 1, 'KeepCLmax', true}};

if isempty(gcp('nocreate')), parpool('Processes', 6); end
fprintf('[BATCH] %d runs\n', size(runs, 1));
t0 = tic;
for k = 1:size(runs, 1)
    tag = runs{k, 1};
    out = fullfile(outDir, tag);
    if isfile(fullfile(out, 'result.mat')) && isfile(fullfile(out, 'run_info.json'))
        fprintf('[SKIP %s] already done\n', tag);
        continue;
    end
    try
        r = optimize_airfoil(runs{k, 2}{:}, 'OutputDir', out);
        i = r.runInfo;
        fprintf('[RUN %s] objective %.2f -> %.2f | peak CL/CD %.1f -> %.1f | %.0f s | total %.1f h\n', ...
            tag, i.objectiveOriginalFit, i.objectiveFinal, r.original.LDmax, r.optimized.LDmax, ...
            i.runTimeSeconds, toc(t0)/3600);
    catch err
        fprintf('[FAIL %s] %s\n', tag, getReport(err, 'extended', 'hyperlinks', 'off'));
    end
    close all;
end
fprintf('[BATCH DONE] %.1f h\n', toc(t0)/3600);
end
