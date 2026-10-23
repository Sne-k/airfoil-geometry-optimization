function result = equal_budget_case(seed, algorithm, outRoot)
%EQUAL_BUDGET_CASE  Step (c): optimiser comparison at equal budget on NACA 2412, the task of the paper batch
%   (cmp_<alg>_s<seed>): peak CL/CD, free transition, Re 1e6, global search only, population 40,
%   15 generations. Code of commit 021a63d (current code, friction floor), so GA, particle swarm and
%   Bayesian optimisation are rerun with it. The surrogate uses model A (free transition, peak CL/CD),
%   warm-started with the peak optima of the three training airfoils whose seed CST fits are closest.
W = getenv('AIRFOIL_WORK');                         % work folder with the logged runs (MATLAB/Surrogate/README.md)
if isempty(W), error('Surrogate:work', 'Set the environment variable AIRFOIL_WORK (MATLAB/Surrogate/README.md).'); end
here = fileparts(mfilename('fullpath'));  ML = fileparts(here);  repo = fileparts(ML);   % MATLAB/Surrogate, MATLAB, repo
addpath(fullfile(ML, 'Optimization'), fullfile(ML, 'Paper'));
setenv('XFOIL_EXE', fullfile(W, 'tools', 'xfoil.exe'));
if nargin < 3, outRoot = fullfile(W, 'surrogate', 'compare_v4'); end
opts = {'Seed', seed, 'Algorithm', algorithm, 'LocalSearch', false, 'Population', 40, 'Generations', 15, ...
    'OutputDir', fullfile(outRoot, sprintf('cmp_%s_s%d', algorithm, seed))};
if strcmp(algorithm, 'surrogate')
    R = readtable(fullfile(W, 'feasibility', 'runs_seed_fit.csv'), 'TextType', 'char');
    names = [compose('Au%d', 0:6), compose('Al%d', 0:6)];
    seedOf = @(t) R{find(startsWith(R.tag, [t '_']), 1), names};
    m = jsondecode(fileread(fullfile(here, 'models', 'model_A.json')));
    train = setdiff(unique(cellfun(@(t) regexprep(t, '_[a-z0-9]+_s\d+$', ''), R.tag, 'UniformOutput', false)), m.held_out);
    C = readtable(fullfile(repo, 'results', 'population', 'cst_coefficients.csv'), 'TextType', 'char');
    [~, k] = sort(cellfun(@(t) norm(seedOf(t) - seedOf('NACA_2412')), train));
    warm = zeros(0, 14);
    for t = train(k(1:3)).'
        row = C(strcmp(C.tag, [t{1} '_peak_s1']), :);
        if ~isempty(row), warm(end+1, :) = row{1, names}; end %#ok<AGROW>
    end
    fprintf('[WARM START] NACA_2412 from %s (%d shapes)\n', strjoin(train(k(1:3)), ', '), size(warm, 1));
    opts = [opts, {'SurrogateModel', fullfile(here, 'models', 'model_A.json'), 'WarmStart', warm}];
end
t0 = tic;
result = optimize_airfoil('NACA 2412', opts{:});
fprintf('[CMP RUN] %s seed %d: objective %.2f -> %.2f | XFOIL-analysed designs %d | %.0f s\n', algorithm, seed, ...
    result.runInfo.objectiveOriginalFit, result.runInfo.objectiveFinal, result.runInfo.xfoilAnalysedDesigns, toc(t0));
end
