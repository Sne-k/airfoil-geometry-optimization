function run_population_study(outDir, airfoilDir, workers, pilot)
%RUN_POPULATION_STUDY  The same optimisation on a population of airfoils.
%   RUN_POPULATION_STUDY runs optimize_airfoil (XFOIL, Re = 1e6, the default
%   limits of the paper batch) for 30 baseline airfoils and writes each run
%   to outDir/<tag> (default MATLAB/output/population). Runs whose result.mat
%   and run_info.json already exist are skipped, so the batch can be stopped
%   and started again.
%
%   Baselines: 18 NACA 4- and 5-digit sections, Clark Y, and 11 airfoils of
%   other families whose coordinate files must be in airfoilDir (default
%   MATLAB/airfoils/uiuc; from the UIUC Airfoil Coordinates Database,
%   https://m-selig.ae.illinois.edu/ads/coord_database.html): e387, s1223,
%   sd7062, sg6043, fx63137, nlf416, rg15, e423, mh32, ah79100b, goe398.
%   Missing files are skipped with a message.
%
%   Runs, in this order (188 for 30 airfoils):
%     robust   NACA 2412 only: peak CL/CD averaged over Ncrit = 5 and 9
%              (seeds 1-3) and its worst case over the two (seed 1); and the
%              same for free transition (Ncrit 9) together with transition
%              fixed at 5 % chord on both surfaces (seeds 1-3; worst case
%              seed 1)
%     peak     peak CL/CD, seed 1                          (every airfoil)
%     alpha2   CL/CD at alpha = 2 deg, seed 1              (every airfoil)
%     cldes    CL/CD at the lift coefficient at which the original has
%              its peak CL/CD, rounded to 0.05, seed 1     (every airfoil)
%     nocurv   peak CL/CD without curvature limits, seed 1 (every airfoil)
%     peak     seeds 2 and 3                               (every airfoil)
%   A lift coefficient common to all airfoils does not work: the highly
%   cambered ones do not fly at CL = 0.5 within the angle range of the
%   analysis. The design lift coefficients are written to baselines.csv in
%   outDir (and read from there when the batch is started again).
%   collect_population_results.m analyses the designs off their design
%   condition and makes the tables.
%
%   RUN_POPULATION_STUDY(outDir, airfoilDir, workers) sets the number of
%   parallel workers (default 6; a run takes about 35 minutes with 6).
%   RUN_POPULATION_STUDY(outDir, airfoilDir, workers, true) runs six very
%   short searches (a check of the set-up).

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'Optimization'));
if nargin < 1 || isempty(outDir), outDir = fullfile(root, 'output', 'population'); end
if nargin < 2 || isempty(airfoilDir), airfoilDir = fullfile(root, 'airfoils', 'uiuc'); end
if nargin < 3 || isempty(workers), workers = 6; end
if nargin < 4, pilot = false; end
if ~exist(outDir, 'dir'), mkdir(outDir); end

naca = {'0009', '0012', '0015', '1408', '1412', '2408', '2412', '2415', '2418', '4409', '4412', '4415', ...
        '4418', '6409', '6412', '23012', '23015', '23018'};
A = cell(0, 2);                                      % {tag, airfoil}
for k = 1:numel(naca), A(end+1, :) = {['NACA_' naca{k}], ['NACA ' naca{k}]}; end %#ok<AGROW>
A(end+1, :) = {'CLARK_Y', fullfile(root, 'airfoils', 'clarky.dat')};
for f = {'e387', 's1223', 'sd7062', 'sg6043', 'fx63137', 'nlf416', 'rg15', 'e423', 'mh32', 'ah79100b', 'goe398'}
    file = fullfile(airfoilDir, [f{1} '.dat']);
    if isfile(file), A(end+1, :) = {upper(f{1}), file}; else, fprintf('[MISSING] %s\n', file); end %#ok<AGROW>
end

short = {};
if pilot, short = {'Population', 8, 'Generations', 1, 'NLPIterations', 1}; end
if isempty(gcp('nocreate')), parpool('Processes', workers); end

% Original airfoils: peak CL/CD and the lift coefficient where it occurs
baseFile = fullfile(outDir, 'baselines.csv');
if isfile(baseFile)
    B = readtable(baseFile, 'TextType', 'char');
else
    addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'NACA2412'));
    exe = getenv('XFOIL_EXE');
    if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end
    files = A(:, 2);
    v = nan(numel(files), 4);
    parfor k = 1:numel(files)
        [xu, yu, xl, yl] = readAirfoil(files{k});
        m = efficiencyMetrics(xfoilPolar(xu, yu, xl, yl, 1e6, [-2 18 0.5], exe));
        v(k, :) = [m.LDmax, m.alphaLD, m.CL_LD, m.CLmax];
    end
    B = table(A(:, 1), v(:, 1), v(:, 2), v(:, 3), v(:, 4), round(v(:, 3) / 0.05) * 0.05, 'VariableNames', ...
        {'airfoil', 'LDmax', 'alpha_LDmax', 'CL_LDmax', 'CLmax', 'design_CL'});
    writetable(B, baseFile);
end
runs = cell(0, 2);                                   % {tag, options}
for s = 1:3
    runs(end+1, :) = {sprintf('NACA_2412_robustmean_s%d', s), {'NACA 2412', 'Seed', s, 'Ncrit', [5 9]}}; %#ok<AGROW>
end
runs(end+1, :) = {'NACA_2412_robustworst_s1', {'NACA 2412', 'Seed', 1, 'Ncrit', [5 9], 'Aggregate', 'worst'}};
trip = {struct('Ncrit', 9), struct('Xtr', [0.05 0.05])};         % free transition and tripped at 5 % chord
for s = 1:3
    runs(end+1, :) = {sprintf('NACA_2412_robusttrip_s%d', s), {'NACA 2412', 'Seed', s, 'Conditions', trip}}; %#ok<AGROW>
end
runs(end+1, :) = {'NACA_2412_robusttripworst_s1', {'NACA 2412', 'Seed', 1, 'Conditions', trip, 'Aggregate', 'worst'}};
forms = {'peak', {}; 'alpha2', {'Objective', 'LDatAlpha', 'DesignAlpha', 2}; ...
         'cldes', {'Objective', 'LDatCL'}; 'nocurv', {'Curvature', false}};
for f = 1:size(forms, 1)
    for k = 1:size(A, 1)
        opts = forms{f, 2};
        if strcmp(forms{f, 1}, 'cldes')
            cl = B.design_CL(strcmp(B.airfoil, A{k, 1}));
            if isempty(cl) || isnan(cl), continue; end
            opts = [opts, {'DesignCL', cl}]; %#ok<AGROW>
        end
        runs(end+1, :) = {sprintf('%s_%s_s1', A{k, 1}, forms{f, 1}), [{A{k, 2}, 'Seed', 1}, opts]}; %#ok<AGROW>
    end
end
for s = 2:3
    for k = 1:size(A, 1)
        runs(end+1, :) = {sprintf('%s_peak_s%d', A{k, 1}, s), {A{k, 2}, 'Seed', s}}; %#ok<AGROW>
    end
end
if pilot                                             % one run of every kind
    last = A{end, 1};
    keep = {'NACA_2412_robustmean_s1', 'NACA_2412_robusttrip_s1', 'NACA_2412_peak_s1', [last '_alpha2_s1'], ...
        [last '_cldes_s1'], [last '_nocurv_s1']};
    runs = runs(ismember(runs(:, 1), keep), :);
end
fprintf('[BATCH] %d runs, %d airfoils\n', size(runs, 1), size(A, 1));
t0 = tic;

for k = 1:size(runs, 1)
    dirK = fullfile(outDir, runs{k, 1});
    if isfile(fullfile(dirK, 'result.mat')) && isfile(fullfile(dirK, 'run_info.json'))
        fprintf('[SKIP %s] already done\n', runs{k, 1});
        continue;
    end
    try
        r = optimize_airfoil(runs{k, 2}{:}, short{:}, 'OutputDir', dirK);
        i = r.runInfo;
        fprintf('[RUN %d of %d: %s] objective %.2f -> %.2f | peak CL/CD %.1f -> %.1f | %.0f s | total %.1f h\n', ...
            k, size(runs, 1), runs{k, 1}, i.objectiveOriginalFit, i.objectiveFinal, r.original.LDmax, ...
            r.optimized.LDmax, i.runTimeSeconds, toc(t0)/3600);
    catch err
        fprintf('[FAIL %s] %s\n', runs{k, 1}, getReport(err, 'extended', 'hyperlinks', 'off'));
    end
    close all;
end
fprintf('[POPULATION STUDY DONE] %.1f h\n', toc(t0)/3600);
end
