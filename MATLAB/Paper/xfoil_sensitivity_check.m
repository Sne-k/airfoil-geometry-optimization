function T = xfoil_sensitivity_check(runDir, outDir, workers, only)
%XFOIL_SENSITIVITY_CHECK  Re-evaluates the final design of every population run and tests it for false XFOIL solutions.
%   T = XFOIL_SENSITIVITY_CHECK(runDir, outDir) reads every finished run of
%   run_population_study.m in runDir (default MATLAB/output/population) and
%   evaluates the objective of the optimiser for its final design exactly as
%   the optimiser does (airfoilObjective.m: alpha from -2 to 12 deg, no
%   restarts, the flow conditions of the run, mean or lower value over them,
%   the same rules for unusable polars) in four variants:
%     exact160, exact200   the exact CST coordinates, 160 and 200 panel nodes
%     round160, round200   the coordinates rounded to 6 decimals, as in the
%                          published .dat files, 160 and 200 panel nodes
%   once with the friction floor of xfoilPolar switched off (the code the
%   optimisations ran with) and once with it on. The objective of the
%   optimiser is the lower of exact160 and exact200; without the floor it
%   must reproduce the recorded objective (column reproduced).
%
%   A real design gives nearly the same value in all four variants. XFOIL
%   occasionally converges to a false low-drag solution that exists only
%   for one panelling or disappears when the coordinates change in the
%   sixth decimal; such a design shows a large spread (largest / smallest
%   value - 1). Written to outDir (default results/population):
%     sensitivity.csv        one row per run: the eight values, the recorded
%                            objective, the spreads without and with the
%                            floor, and the objective with the floor
%     cst_coefficients.csv   the exact CST coefficients of every final design
%                            (full precision), from which the exact
%                            coordinates follow with cstSurfaces.m
%
%   XFOIL_SENSITIVITY_CHECK(runDir, outDir, workers, only) sets the number of
%   parallel workers (default 8) and takes only the runs whose name matches
%   the regular expression only.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
if nargin < 1 || isempty(runDir), runDir = fullfile(root, 'output', 'population'); end
if nargin < 2 || isempty(outDir), outDir = fullfile(root, '..', 'results', 'population'); end
if nargin < 3 || isempty(workers), workers = 8; end
if nargin < 4, only = ''; end
addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'Optimization'), fullfile(root, 'NACA2412'));
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% Runs
d = dir(runDir);
d = d([d.isdir] & ~startsWith({d.name}, '.'));
R = struct('tag', {}, 'form', {}, 'x', {}, 'yu', {}, 'yl', {}, 'S', {}, 'objective', {}, 'cst', {});
for k = 1:numel(d)
    tag = d(k).name;
    f = fullfile(runDir, tag, 'result.mat');
    if ~isfile(f) || ~isfile(fullfile(runDir, tag, 'run_info.json')), continue; end
    if ~isempty(only) && isempty(regexp(tag, only, 'once')), continue; end
    tok = regexp(tag, '_(robustmean|robustworst|robusttripworst|robusttrip|peak|alpha2|cldes|cl05|nocurv)_s\d+$', 'tokens', 'once');
    s = load(f);  r = s.result;  o = r.options;
    [yu, yl] = cstSurfaces(r.AuOpt, r.AlOpt, r.dte, r.x);
    S = struct('Re', o.Re, 'objective', o.Objective, 'weights', o.Weights, 'aggregate', o.Aggregate, 'cmMax', Inf, 'clMaxMin', -Inf);
    if strcmp(o.Objective, 'LDatAlpha'), S.design = o.DesignAlpha; else, S.design = o.DesignCL; end
    if isfinite(o.CmIncrease) && isfinite(r.original.CM0), S.cmMax = abs(r.original.CM0) + o.CmIncrease; end
    if o.KeepCLmax, S.clMaxMin = r.original.CLmax; end
    S.flows = arrayfun(@(n) struct('Ncrit', n), o.Ncrit(:).', 'UniformOutput', false);
    if ~isempty(o.Conditions), S.flows = o.Conditions(:).'; end
    R(end+1) = struct('tag', tag, 'form', tok{1}, 'x', r.x, 'yu', yu, 'yl', yl, 'S', S, ...
        'objective', r.runInfo.objectiveFinal, 'cst', {{r.AuOpt(:).', r.AlOpt(:).', r.dte}}); %#ok<AGROW>
end
fprintf('[SENSITIVITY] %d runs\n', numel(R));

%% Evaluations: run x {exact160, exact200, round160, round200} x {floor off, floor on}
variants = {'exact160', false, []; 'exact200', false, 200; 'round160', true, []; 'round200', true, 200};
jobs = [repelem((1:numel(R))', 8), repmat(kron((1:4)', [1; 1]), numel(R), 1), repmat([0; 1], 4 * numel(R), 1)];
E = nan(size(jobs, 1), 1);
if workers > 0 && isempty(gcp('nocreate')), parpool('Processes', workers); end
parfor (j = 1:size(jobs, 1), workers)
    r = R(jobs(j, 1));  v = variants(jobs(j, 2), :);
    x = r.x;  yu = r.yu;  yl = r.yl;
    if v{2}, x = round(x, 6);  yu = round(yu, 6);  yl = round(yl, 6); end
    E(j) = objectiveValue(x, yu, yl, r.S, v{3}, jobs(j, 3) == 1, exe);
end

%% Table
names = {'exact160', 'exact200', 'round160', 'round200'};
V = reshape(E, 2, 4, numel(R));                          % floor x variant x run
rows = cell(numel(R), 1);
for k = 1:numel(R)
    off = squeeze(V(1, :, k));  on = squeeze(V(2, :, k));
    rec = min(off(1:2));
    rows{k} = [{R(k).tag, R(k).form, R(k).objective, rec, abs(rec / R(k).objective - 1) < 1e-6}, num2cell(off), num2cell(on), ...
        {spread(off), spread(on), min(on(1:2))}];
end
T = cell2table(vertcat(rows{:}), 'VariableNames', [{'tag', 'formulation', 'objective_recorded', 'objective_recomputed', 'reproduced'}, ...
    names, strcat(names, '_floor'), {'spread_percent', 'spread_percent_floor', 'objective_floor'}]);
writetable(T, fullfile(outDir, 'sensitivity.csv'));
n = numel(R(1).cst{1});                                  % exact CST coefficients, full precision
fid = fopen(fullfile(outDir, 'cst_coefficients.csv'), 'w');
fprintf(fid, '%s\n', strjoin([{'tag'}, compose('Au%d', 0:n-1), compose('Al%d', 0:n-1), {'dte'}], ','));
for k = 1:numel(R)
    fprintf(fid, '%s%s\n', R(k).tag, sprintf(',%.17g', [R(k).cst{1}, R(k).cst{2}, R(k).cst{3}]));
end
fclose(fid);
fprintf('[SENSITIVITY DONE] %d runs, %d reproduce the recorded objective\n', height(T), sum(T.reproduced));
end

function e = objectiveValue(x, yu, yl, S, panels, useFloor, exe)
% The objective of airfoilObjective.m for one panelling: 0 for an unusable polar
ec = zeros(1, numel(S.flows));
for c = 1:numel(S.flows)
    flow = S.flows{c};  flow.FrictionFloor = useFloor;
    pol = xfoilPolar(x, yu, x, yl, S.Re, [-2 12 0.5], exe, panels, false, flow);
    if numel(pol.alpha) < 12 || pol.alpha(1) > 0 || pol.alpha(end) < 0 || ...
            abs(interp1(pol.alpha, pol.CM, 0)) > S.cmMax || max(pol.CL) < S.clMaxMin
        e = 0;
        return;
    end
    ec(c) = efficiencyValue(pol, S.objective, S.design, S.weights, S.aggregate);
end
if strcmp(S.aggregate, 'worst'), e = min(ec); else, e = mean(ec); end
if ~isfinite(e) || e < 0, e = 0; end
end

function s = spread(v)
% largest / smallest value - 1, in per cent; Inf if a variant gives no value
if any(v <= 0 | isnan(v)), s = Inf; else, s = 100 * (max(v) / min(v) - 1); end
end
