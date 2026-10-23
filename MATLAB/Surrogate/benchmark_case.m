function result = benchmark_case(airfoilTag, seed, algorithm, outRoot)
%BENCHMARK_CASE  One benchmark run: free and tripped transition (mean), the settings of the population study.
%   airfoilTag: tag as in the population study (e.g. 'NACA_2412', 'CLARK_Y', 'SD7062');
%   algorithm: 'surrogate' (new) or 'ga' (current optimiser). The surrogate run is warm-started with the
%   robusttrip optima of the three training airfoils whose seed CST fits are closest to this one.
W = getenv('AIRFOIL_WORK');                         % work folder with the logged runs (MATLAB/Surrogate/README.md)
if isempty(W), error('Surrogate:work', 'Set the environment variable AIRFOIL_WORK (MATLAB/Surrogate/README.md).'); end
here = fileparts(mfilename('fullpath'));  ML = fileparts(here);  repo = fileparts(ML);   % MATLAB/Surrogate, MATLAB, repo
addpath(fullfile(ML, 'Optimization'), fullfile(ML, 'Paper'));   % the code of this repository (the runs: commit in run_info.json)
setenv('XFOIL_EXE', fullfile(W, 'tools', 'xfoil.exe'));
if nargin < 4, outRoot = fullfile(W, 'surrogate', 'benchmark_v5'); end
trip = {struct('Ncrit', 9), struct('Xtr', [0.05 0.05])};
R = readtable(fullfile(W, 'feasibility', 'runs_seed_fit.csv'), 'TextType', 'char');
seedOf = @(t) R{find(startsWith(R.tag, [t '_']), 1), [compose('Au%d', 0:6), compose('Al%d', 0:6)]};
if startsWith(airfoilTag, 'NACA_'), src = strrep(airfoilTag, '_', ' ');
elseif strcmp(airfoilTag, 'CLARK_Y'), src = fullfile(ML, 'airfoils', 'clarky.dat');
else, src = fullfile(W, 'refs', 'uiuc', [lower(airfoilTag) '.dat']); end
opts = {'Seed', seed, 'Conditions', trip, 'Algorithm', algorithm, ...
    'OutputDir', fullfile(outRoot, sprintf('%s_%s_s%d', airfoilTag, algorithm, seed))};
if strcmp(algorithm, 'surrogate')
    m = jsondecode(fileread(fullfile(here, 'models', 'model_B.json')));
    train = setdiff(unique(cellfun(@(t) regexprep(t, '_[a-z0-9]+_s\d+$', ''), R.tag, 'UniformOutput', false)), m.held_out);
    C = readtable(fullfile(repo, 'results', 'population', 'cst_coefficients.csv'), 'TextType', 'char');
    s0 = seedOf(airfoilTag);
    dist = cellfun(@(t) norm(seedOf(t) - s0), train);
    [~, k] = sort(dist);
    warm = zeros(0, 14);
    for t = train(k(1:3)).'
        row = C(strcmp(C.tag, [t{1} '_robusttrip_s1']), :);
        if ~isempty(row), warm(end+1, :) = row{1, [compose('Au%d', 0:6), compose('Al%d', 0:6)]}; end %#ok<AGROW>
    end
    fprintf('[WARM START] %s from %s\n', airfoilTag, strjoin(train(k(1:3)), ', '));
    opts = [opts, {'SurrogateModel', fullfile(here, 'models', 'model_B.json'), 'WarmStart', warm}];
end
t0 = tic;
result = optimize_airfoil(src, opts{:});
fprintf('[BENCHMARK RUN] %s %s seed %d: objective %.2f -> %.2f | XFOIL-analysed designs %d | %.0f s\n', airfoilTag, algorithm, seed, ...
    result.runInfo.objectiveOriginalFit, result.runInfo.objectiveFinal, result.runInfo.xfoilAnalysedDesigns, toc(t0));
end
