function trip_sensitivity(runDir, outDir, airfoilDir, workers, positions, forms)
%TRIP_SENSITIVITY  Sensitivity of the tripped-flow results to the trip position.
%   TRIP_SENSITIVITY repeats the tripped condition of collect_population_results
%   (transition fixed on both surfaces, Re 1e6, Ncrit 9) with the trip at each
%   chord position in positions (default x/c = 0.025, 0.05 and 0.10), for the
%   original airfoils and the seed-1 designs of the formulations in forms
%   (default peak, alpha2, cldes, nocurv and robusttrip). The analysis is the
%   one of collect_population_results: XFOIL with 160 panel nodes, alpha from
%   -2 to 18 deg in 0.5 deg steps, the friction floor of xfoilPolar, every
%   polar at the exact and at the rounded coordinates with the 200-node
%   decision when they disagree, and polars that do not depend on the load of
%   the machine. The run at x/c = 0.05 is the published tripped condition and
%   serves as a control. Writes to outDir (default
%   results/population/trip_sensitivity):
%     trip_conditions.csv  one row per run and trip position: peak CL/CD,
%                     CL/CD at 2 deg and at the design lift coefficient for
%                     the original and the design, the gains, the upper-surface
%                     transition at the angle of the peak, and the checks of
%                     conditions.csv
%     trip_summary.csv  per formulation and trip position: median, quartiles,
%                     minimum and maximum of the gain in peak CL/CD, and the
%                     number of designs worse than their original
%   TRIP_SENSITIVITY(runDir, outDir, airfoilDir, workers, positions, forms)
%   sets the folders (as in collect_population_results), the number of
%   parallel workers (default 4), the trip positions and the formulations.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'Optimization'), fullfile(root, 'NACA2412'));
if nargin < 1 || isempty(runDir), runDir = fullfile(root, 'output', 'population'); end
if nargin < 2 || isempty(outDir), outDir = fullfile(root, '..', 'results', 'population', 'trip_sensitivity'); end
if nargin < 3 || isempty(airfoilDir), airfoilDir = fullfile(root, 'airfoils', 'uiuc'); end
if nargin < 4 || isempty(workers), workers = 4; end
if nargin < 5 || isempty(positions), positions = [0.025 0.05 0.10]; end
if nargin < 6 || isempty(forms), forms = {'peak', 'alpha2', 'cldes', 'nocurv', 'robusttrip'}; end
if ~exist(outDir, 'dir'), mkdir(outDir); end
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end

%% Seed-1 runs of the chosen formulations (found as in collect_population_results)
d = dir(fullfile(runDir, '*', 'result.mat'));
B = table();
if isfile(fullfile(runDir, 'baselines.csv')), B = readtable(fullfile(runDir, 'baselines.csv'), 'TextType', 'char'); end
runs = struct('tag', {}, 'airfoil', {}, 'formulation', {}, 'designCL', {});
G = struct('tag', {}, 'x', {}, 'yu', {}, 'yl', {});          % geometries to analyse
for k = 1:numel(d)
    [~, tag] = fileparts(d(k).folder);
    tok = regexp(tag, '^(.*)_(robustmean|robustworst|robusttripworst|robusttrip|peak|alpha2|cldes|cl05|nocurv)_s(\d+)$', 'tokens', 'once');
    if isempty(tok) || ~isfile(fullfile(d(k).folder, 'run_info.json')), continue; end
    if str2double(tok{3}) ~= 1 || ~any(strcmp(tok{2}, forms)), continue; end
    S = load(fullfile(d(k).folder, 'result.mat'));
    r = S.result;  o = r.options;
    designCL = NaN;
    if ~isempty(B) && any(strcmp(B.airfoil, tok{1})), designCL = B.design_CL(strcmp(B.airfoil, tok{1})); end
    if strcmp(o.Objective, 'LDatCL'), designCL = o.DesignCL(1); end
    runs(end+1) = struct('tag', tag, 'airfoil', tok{1}, 'formulation', tok{2}, 'designCL', designCL); %#ok<AGROW>
    G(end+1) = struct('tag', tag, 'x', r.x, 'yu', r.yu, 'yl', r.yl); %#ok<AGROW>
end
if isempty(runs), error('trip_sensitivity:none', 'No finished seed-1 runs in %s.', runDir); end
names = unique({runs.airfoil}, 'stable');
for k = 1:numel(names)
    [xu, yu, xl, yl] = readAirfoil(originalSource(names{k}, root, airfoilDir));
    G(end+1) = struct('tag', ['original:' names{k}], 'x', {{xu, xl}}, 'yu', yu, 'yl', yl); %#ok<AGROW>
end

%% XFOIL with the trip at every position (the rule of collect_population_results)
nG = numel(G);  nP = numel(positions);
jobs = [repelem((1:nG)', nP), repmat((1:nP)', nG, 1)];
P = cell(size(jobs, 1), 1);
cut = false(size(jobs, 1), 1);
sens = nan(size(jobs, 1), 1);
used = zeros(size(jobs, 1), 1);
if workers > 0 && isempty(gcp('nocreate')), parpool('Processes', workers); end
parfor (j = 1:size(jobs, 1), workers)
    g = G(jobs(j, 1));
    flow = struct('Xtr', positions(jobs(j, 2)) * [1 1]);
    if iscell(g.x), xu = g.x{1};  xl = g.x{2}; else, xu = g.x;  xl = g.x; end
    [pE, cE] = stablePolar(xu, g.yu, xl, g.yl, 1e6, exe, flow);
    [pR, cR] = stablePolar(round(xu, 6), round(g.yu, 6), round(xl, 6), round(g.yl, 6), 1e6, exe, flow);
    vE = metrics(pE, NaN);  vR = metrics(pR, NaN);
    sens(j) = 100 * (max(vE(1), vR(1)) / min(vE(1), vR(1)) - 1);
    if xor(isnan(vE(1)), isnan(vR(1))), sens(j) = Inf; end
    pick = 1;
    if isnan(vE(1)) && ~isnan(vR(1))
        pick = 2;
    elseif sens(j) > 1 && isfinite(sens(j))
        v2 = [vE(1), vR(1), peakLD(stablePolar(xu, g.yu, xl, g.yl, 1e6, exe, flow, 200)), ...
            peakLD(stablePolar(round(xu, 6), round(g.yu, 6), round(xl, 6), round(g.yl, 6), 1e6, exe, flow, 200))];
        v2 = sort(v2(~isnan(v2)));
        m = v2(ceil(numel(v2) / 2));
        if abs(vR(1) - m) < abs(vE(1) - m), pick = 2; end
    end
    used(j) = pick;
    if pick == 1, P{j} = pE;  cut(j) = cE; else, P{j} = pR;  cut(j) = cR; end
end
index = @(tag, c) find(strcmp({G(jobs(:, 1)).tag}', tag) & jobs(:, 2) == c, 1);

%% One row per run and trip position
C = cell(numel(runs) * nP, 1);
n = 0;
for k = 1:numel(runs)
    for c = 1:nP
        io = index(['original:' runs(k).airfoil], c);  id = index(runs(k).tag, c);
        po = P{io};  pd = P{id};
        v = [metrics(po, runs(k).designCL); metrics(pd, runs(k).designCL)];
        g = 100 * (v(2, 1:3) ./ v(1, 1:3) - 1);
        n = n + 1;
        C{n} = table({runs(k).tag}, {runs(k).airfoil}, {runs(k).formulation}, positions(c), v(1, 1), v(2, 1), g(1), ...
            v(1, 2), v(2, 2), g(2), v(1, 3), v(2, 3), g(3), xtrAtPeak(po, v(1, 4)), xtrAtPeak(pd, v(2, 4)), ...
            numel(po.alpha), numel(pd.alpha), cut(io) || cut(id), sens(io), sens(id), used(io), used(id), ...
            'VariableNames', {'tag', 'airfoil', 'formulation', 'trip_xc', 'LDmax_original', 'LDmax', ...
            'LDmax_gain_percent', 'LD_2deg_original', 'LD_2deg', 'LD_2deg_gain_percent', 'LD_designCL_original', ...
            'LD_designCL', 'LD_designCL_gain_percent', 'xtr_top_at_peak_original', 'xtr_top_at_peak', ...
            'angles_original', 'angles', 'no_stable_polar', 'sensitivity_percent_original', 'sensitivity_percent', ...
            'polar_used_original', 'polar_used'});
    end
end
C = vertcat(C{:});
writetable(C, fullfile(outDir, 'trip_conditions.csv'));

%% Statistics over the airfoils per formulation and trip position
S = cell(0, 1);
for f = 1:numel(forms)
    for c = 1:nP
        x = C.LDmax_gain_percent(strcmp(C.formulation, forms{f}) & C.trip_xc == positions(c));
        q = quantile(x(~isnan(x)), [0.25 0.75]);
        S{end+1, 1} = table(forms(f), positions(c), numel(x), sum(isnan(x)), median(x, 'omitnan'), q(1), q(2), ...
            min(x), max(x), sum(x < 0), 'VariableNames', {'formulation', 'trip_xc', 'airfoils', 'without_value', ...
            'median_gain_percent', 'q1_gain_percent', 'q3_gain_percent', 'min_gain_percent', 'max_gain_percent', ...
            'designs_worse_than_original'}); %#ok<AGROW>
    end
end
S = vertcat(S{:});
writetable(S, fullfile(outDir, 'trip_summary.csv'));
disp(S);
fprintf('%d runs, %d airfoils, %d trip positions, %d XFOIL polars\n', numel(runs), numel(names), nP, numel(P));
end

function x = xtrAtPeak(p, alphaPeak)
% upper-surface transition location at the angle of the peak CL/CD (NaN without a peak)
x = NaN;
if ~isnan(alphaPeak) && ~isempty(p.alpha), x = interp1(p.alpha, p.xtrTop, alphaPeak); end
end

function [p, unstable] = stablePolar(xu, yu, xl, yl, Re, exe, flow, panels)
% XFOIL polar that does not depend on the load of the machine (as in collect_population_results)
unstable = false;
flow.TimeFactor = 3;
if nargin < 8, panels = []; end
[p, info] = xfoilPolar(xu, yu, xl, yl, Re, [-2 18 0.5], exe, panels, true, flow);
if ~info.timedOut, return; end
for attempt = 2:4
    [q, info] = xfoilPolar(xu, yu, xl, yl, Re, [-2 18 0.5], exe, panels, true, flow);
    same = isequal(q.alpha, p.alpha);
    p = q;
    if ~info.timedOut || same, return; end
end
unstable = true;
p = struct('alpha', [], 'CL', [], 'CD', [], 'CM', [], 'xtrTop', [], 'xtrBot', []);
end

function v = peakLD(p)
% peak CL/CD of a polar by the rule of metrics; NaN if the polar is not usable
v = metrics(p, NaN);
v = v(1);
end

function v = metrics(p, designCL)
% [peak CL/CD, CL/CD at 2 deg, CL/CD at the design CL, angle of the peak, CL max, CM at 0 deg, CM at the angle
% of the peak]; NaN where XFOIL gave no value (as in collect_population_results)
v = nan(1, 7);
if numel(p.alpha) < 12 || p.alpha(1) > 0 || p.alpha(end) < 0, return; end
m = efficiencyMetrics(p);
v([1 4 5 6]) = [m.LDmax, m.alphaLD, m.CLmax, m.CM0];
v(7) = interp1(p.alpha, p.CM, m.alphaLD);
e = efficiencyValue(p, 'LDatAlpha', 2);
if e > 0, v(2) = e; end
if ~isnan(designCL)
    e = efficiencyValue(p, 'LDatCL', designCL);
    if e > 0, v(3) = e; end
end
end

function src = originalSource(tag, root, airfoilDir)
% Airfoil behind a tag of run_population_study
if startsWith(tag, 'NACA_')
    src = strrep(tag, '_', ' ');
elseif strcmp(tag, 'CLARK_Y')
    src = fullfile(root, 'airfoils', 'clarky.dat');
else
    src = fullfile(airfoilDir, [lower(tag) '.dat']);
end
end
