function collect_population_results(runDir, outDir, airfoilDir, workers, only)
%COLLECT_POPULATION_RESULTS  Tables of the population study (run_population_study.m).
%   COLLECT_POPULATION_RESULTS reads every finished run in runDir (default
%   MATLAB/output/population), analyses each original airfoil and each
%   design with XFOIL at the design condition and off it, and writes to
%   outDir (default results/population):
%     runs.csv        one row per run: airfoil, formulation, seed, objective
%                     before and after, curvature of the design, effort
%     conditions.csv  one row per run and condition: peak CL/CD, CL/CD at
%                     2 deg and CL/CD at the design lift coefficient of the
%                     airfoil, for the original and the design, and the
%                     gains; the pitching moment at 0 deg (the quantity the
%                     optimiser limits) and at the angle of the peak CL/CD;
%                     the number of converged angles of both polars.
%                     Conditions (Re 1e6 and Ncrit 9 unless stated):
%                     design, Ncrit 5, Ncrit 7, Ncrit 11, Re 0.5e6, Re 2e6,
%                     tripped (transition fixed at x/c = 0.05 on both
%                     surfaces)
%     summary.csv     statistics over the airfoils for every formulation
%                     and condition: median, quartiles, minimum, maximum of
%                     the gain in peak CL/CD, the number of designs that are
%                     worse than their original, and the number of airfoils
%                     without a value
%     gain_by_angle.csv  gain in CL/CD of the peak-optimised designs at
%                     every angle of attack (design condition): the size of
%                     a gain depends on the angle at which it is reported
%     seeds.csv       spread of the peak CL/CD over the three seeds
%     robustness.csv  one row per run: mean, standard deviation and lowest
%                     value of the peak CL/CD over the seven conditions, for
%                     the original and the design, and the mean and lowest
%                     gain (only where all seven conditions give a value)
%     robustness_summary.csv  medians of these over the airfoils for every
%                     formulation (seed 1)
%     airfoils/       the optimised .dat files
%   and the figures gains_by_condition.png and gain_by_angle.png.
%   The analysis uses XFOIL with 160 panel nodes, alpha from -2 to 18 deg in
%   0.5 deg steps, with the friction floor of xfoilPolar. Every polar is
%   computed twice: at the exact coordinates of the design and at the
%   coordinates rounded to 6 decimals (as in the published .dat files). XFOIL
%   occasionally converges to a false low-drag solution that exists only at
%   one of them (too high), or misses the angle of the peak at one of them
%   (too low). If the two peaks agree within 1 %, the exact polar is used. If
%   they disagree, both are also computed with 200 panel nodes, and the
%   160-node polar whose peak is closer to the median of the four is used.
%   conditions.csv gives the difference of the two 160-node peaks
%   (sensitivity_percent) and the polar used (polar_used: 1 exact, 2
%   rounded), also for the original. A gain is taken against the original airfoil at the same
%   condition. airfoilDir holds the UIUC coordinate files (default
%   MATLAB/airfoils/uiuc).
%
%   A polar gives values only if it is usable by the rule of the optimiser:
%   at least 12 converged angles, on both sides of 0 deg or at it. (Without
%   the rule, a polar of which only a few negative angles had converged once
%   gave a wrong peak.) The polars must also not depend on how busy the
%   machine is. xfoilPolar stops a sweep at a time limit; normally that only
%   cuts a tail of angles beyond stall that do not converge. The analysis
%   uses three times the standard limit, and a polar whose sweep was still
%   stopped is computed again and accepted when the same angles converge
%   twice in a row (up to four runs); otherwise the row is marked
%   (no_stable_polar) and has no values.
%
%   COLLECT_POPULATION_RESULTS(runDir, outDir, airfoilDir, workers) sets the
%   number of parallel workers for the XFOIL analyses (default 4; 0 runs
%   them one after the other). COLLECT_POPULATION_RESULTS(..., workers,
%   only) takes only the runs whose name matches the regular expression
%   only, for example '^NACA_2412_' (a check on part of a batch).

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'Optimization'), fullfile(root, 'NACA2412'));
if nargin < 1 || isempty(runDir), runDir = fullfile(root, 'output', 'population'); end
if nargin < 2 || isempty(outDir), outDir = fullfile(root, '..', 'results', 'population'); end
if nargin < 3 || isempty(airfoilDir), airfoilDir = fullfile(root, 'airfoils', 'uiuc'); end
if nargin < 4 || isempty(workers), workers = 4; end
if nargin < 5, only = ''; end
if ~exist(fullfile(outDir, 'airfoils'), 'dir'), mkdir(fullfile(outDir, 'airfoils')); end
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end

%% Finished runs
d = dir(fullfile(runDir, '*', 'result.mat'));
R = cell(0, 1);
G = struct('tag', {}, 'x', {}, 'yu', {}, 'yl', {});          % geometries to analyse
B = table();
if isfile(fullfile(runDir, 'baselines.csv')), B = readtable(fullfile(runDir, 'baselines.csv'), 'TextType', 'char'); end
for k = 1:numel(d)
    [~, tag] = fileparts(d(k).folder);
    if ~isempty(only) && isempty(regexp(tag, only, 'once')), continue; end
    tok = regexp(tag, '^(.*)_(robustmean|robustworst|robusttripworst|robusttrip|peak|alpha2|cldes|cl05|nocurv)_s(\d+)$', 'tokens', 'once');
    if isempty(tok) || ~isfile(fullfile(d(k).folder, 'run_info.json')), continue; end
    S = load(fullfile(d(k).folder, 'result.mat'));
    r = S.result;  i = r.runInfo;  o = r.options;
    designCL = NaN;
    if ~isempty(B) && any(strcmp(B.airfoil, tok{1})), designCL = B.design_CL(strcmp(B.airfoil, tok{1})); end
    if strcmp(o.Objective, 'LDatCL'), designCL = o.DesignCL(1); end
    R{end+1, 1} = table({tag}, tok(1), tok(2), str2double(tok{3}), {o.Objective}, logical(o.Curvature), ...
        {mat2str(o.Ncrit)}, {o.Aggregate}, designCL, i.objectiveOriginalFit, i.objectiveFinal, ...
        100 * (i.objectiveFinal / i.objectiveOriginalFit - 1), r.curvatureOriginalFit.reversalsTop, ...
        r.curvatureOriginalFit.reversalsBot, r.curvatureOptimized.reversalsTop, r.curvatureOptimized.reversalsBot, ...
        logical(i.designMeetsCurvatureLimits), max(r.yu - r.yl), i.evaluations, i.xfoilAnalysedDesigns, ...
        i.medianEvaluationSeconds, i.runTimeSeconds, {i.gitCommit}, 'VariableNames', ...
        {'tag', 'airfoil', 'formulation', 'seed', 'objective', 'curvature_limits', 'Ncrit', 'aggregate', 'design_CL', ...
        'objective_original_fit', 'objective_final', 'objective_gain_percent', 'reversals_top_original', ...
        'reversals_bottom_original', 'reversals_top', 'reversals_bottom', 'meets_curvature_limits', 'tc', ...
        'evaluations', 'xfoil_analysed_designs', 'median_evaluation_seconds', 'run_seconds', 'git_commit'}); %#ok<AGROW>
    G(end+1) = struct('tag', tag, 'x', r.x, 'yu', r.yu, 'yl', r.yl); %#ok<AGROW>
    copyfile(fullfile(d(k).folder, [regexprep(strtrim(r.name), '[^\w]+', '_') '_optimized.dat']), ...
        fullfile(outDir, 'airfoils', [tag '.dat']));
end
if isempty(R), error('collect_population_results:none', 'No finished runs in %s.', runDir); end
R = vertcat(R{:});
R.objective_gain_percent(R.objective_original_fit <= 0) = NaN;          % the original had no value at the design point
writetable(R, fullfile(outDir, 'runs.csv'));

%% Originals
names = unique(R.airfoil, 'stable');
for k = 1:numel(names)
    src = originalSource(names{k}, root, airfoilDir);
    [xu, yu, xl, yl] = readAirfoil(src);
    G(end+1) = struct('tag', ['original:' names{k}], 'x', {{xu, xl}}, 'yu', yu, 'yl', yl); %#ok<AGROW>
end

%% XFOIL at every condition
cond = {'design', 1e6, struct()
        'Ncrit 5', 1e6, struct('Ncrit', 5)
        'Ncrit 7', 1e6, struct('Ncrit', 7)
        'Ncrit 11', 1e6, struct('Ncrit', 11)
        'Re 0.5e6', 0.5e6, struct()
        'Re 2e6', 2e6, struct()
        'tripped', 1e6, struct('Xtr', [0.05 0.05])};
nG = numel(G);  nC = size(cond, 1);
jobs = [repelem((1:nG)', nC), repmat((1:nC)', nG, 1)];
P = cell(size(jobs, 1), 1);
cut = false(size(jobs, 1), 1);                       % no polar that is independent of the machine load
sens = nan(size(jobs, 1), 1);                        % exact against rounded coordinates, peak CL/CD, per cent
used = zeros(size(jobs, 1), 1);                      % 1 exact, 2 rounded coordinates (160 panel nodes)
if workers > 0 && isempty(gcp('nocreate')), parpool('Processes', workers); end
parfor (j = 1:size(jobs, 1), workers)
    g = G(jobs(j, 1));
    if iscell(g.x), xu = g.x{1};  xl = g.x{2}; else, xu = g.x;  xl = g.x; end
    [pE, cE] = stablePolar(xu, g.yu, xl, g.yl, cond{jobs(j, 2), 2}, exe, cond{jobs(j, 2), 3});
    [pR, cR] = stablePolar(round(xu, 6), round(g.yu, 6), round(xl, 6), round(g.yl, 6), cond{jobs(j, 2), 2}, exe, cond{jobs(j, 2), 3});
    vE = metrics(pE, NaN);  vR = metrics(pR, NaN);
    sens(j) = 100 * (max(vE(1), vR(1)) / min(vE(1), vR(1)) - 1);
    if xor(isnan(vE(1)), isnan(vR(1))), sens(j) = Inf; end            % only one of the two gives a value
    pick = 1;                                        % they agree within 1 %, or only the exact one gives a value
    if isnan(vE(1)) && ~isnan(vR(1))
        pick = 2;
    elseif sens(j) > 1 && isfinite(sens(j))          % they disagree: the 200-node polars decide
        v2 = [vE(1), vR(1), peakLD(stablePolar(xu, g.yu, xl, g.yl, cond{jobs(j, 2), 2}, exe, cond{jobs(j, 2), 3}, 200)), ...
            peakLD(stablePolar(round(xu, 6), round(g.yu, 6), round(xl, 6), round(g.yl, 6), cond{jobs(j, 2), 2}, exe, cond{jobs(j, 2), 3}, 200))];
        v2 = sort(v2(~isnan(v2)));
        m = v2(ceil(numel(v2) / 2));                 % median; the lower middle value for an even number
        if abs(vR(1) - m) < abs(vE(1) - m), pick = 2; end
    end
    used(j) = pick;
    if pick == 1, P{j} = pE;  cut(j) = cE; else, P{j} = pR;  cut(j) = cR; end
end
index = @(tag, c) find(strcmp({G(jobs(:, 1)).tag}', tag) & jobs(:, 2) == c, 1);
pol = @(tag, c) P{index(tag, c)};

%% Metrics per run and condition
C = cell(0, 1);
A = cell(0, 1);
for k = 1:height(R)
    for c = 1:nC
        po = pol(['original:' R.airfoil{k}], c);
        pd = pol(R.tag{k}, c);
        v = [metrics(po, R.design_CL(k)); metrics(pd, R.design_CL(k))];
        g = 100 * (v(2, 1:3) ./ v(1, 1:3) - 1);
        late = cut(index(['original:' R.airfoil{k}], c)) || cut(index(R.tag{k}, c));
        se = [sens(index(['original:' R.airfoil{k}], c)), sens(index(R.tag{k}, c)), used(index(['original:' R.airfoil{k}], c)), used(index(R.tag{k}, c))];
        C{end+1, 1} = table(R.tag(k), R.airfoil(k), R.formulation(k), R.seed(k), cond(c, 1), v(1, 1), v(2, 1), g(1), ...
            v(1, 2), v(2, 2), g(2), v(1, 3), v(2, 3), g(3), v(1, 4), v(2, 4), v(1, 5), v(2, 5), numel(po.alpha), ...
            numel(pd.alpha), late, v(1, 6), v(2, 6), v(1, 7), v(2, 7), se(1), se(2), se(3), se(4), 'VariableNames', ...
            {'tag', 'airfoil', 'formulation', 'seed', 'condition', 'LDmax_original', 'LDmax', 'LDmax_gain_percent', ...
            'LD_2deg_original', 'LD_2deg', 'LD_2deg_gain_percent', 'LD_designCL_original', 'LD_designCL', ...
            'LD_designCL_gain_percent', 'alpha_LDmax_original', 'alpha_LDmax', 'CLmax_original', 'CLmax', ...
            'angles_original', 'angles', 'no_stable_polar', 'CM0_original', 'CM0', 'CM_LDmax_original', 'CM_LDmax', ...
            'sensitivity_percent_original', 'sensitivity_percent', 'polar_used_original', 'polar_used'}); %#ok<AGROW>
    end
    if strcmp(R.formulation{k}, 'peak') && R.seed(k) == 1
        po = pol(['original:' R.airfoil{k}], 1);
        pd = pol(R.tag{k}, 1);
        [a, io, id] = intersect(round(po.alpha, 6), round(pd.alpha, 6));
        a = a(:);
        keep = a >= 0 & a <= 10;
        ldo = po.CL(io) ./ po.CD(io);  ldd = pd.CL(id) ./ pd.CD(id);
        A{end+1, 1} = table(repmat(R.airfoil(k), sum(keep), 1), a(keep), ldo(keep), ldd(keep), ...
            100 * (ldd(keep) ./ ldo(keep) - 1), 'VariableNames', {'airfoil', 'alpha', 'LD_original', 'LD', 'gain_percent'}); %#ok<AGROW>
    end
end
C = vertcat(C{:});
writetable(C, fullfile(outDir, 'conditions.csv'));
if ~isempty(A), A = vertcat(A{:});  writetable(A, fullfile(outDir, 'gain_by_angle.csv')); end

%% Statistics over the airfoils (seed 1 of every formulation)
forms = unique(C.formulation, 'stable');
S = cell(0, 1);
for f = 1:numel(forms)
    for c = 1:nC
        g = C.LDmax_gain_percent(strcmp(C.formulation, forms{f}) & C.seed == 1 & strcmp(C.condition, cond{c, 1}));
        missing = sum(isnan(g));
        g = g(~isnan(g));
        if isempty(g), continue; end
        sel = strcmp(C.formulation, forms{f}) & C.seed == 1 & strcmp(C.condition, cond{c, 1});
        dcm = C.CM0(sel) - C.CM0_original(sel);
        S{end+1, 1} = table(forms(f), cond(c, 1), numel(g), median(g), quantile(g, 0.25), quantile(g, 0.75), min(g), max(g), ...
            sum(g < 0), missing, median(dcm, 'omitnan'), min(dcm), max(dcm), 'VariableNames', {'formulation', 'condition', ...
            'airfoils', 'median_gain_percent', 'q25', 'q75', 'min', 'max', 'designs_worse_than_original', ...
            'airfoils_without_value', 'CM0_change_median', 'CM0_change_min', 'CM0_change_max'}); %#ok<AGROW>
    end
end
S = vertcat(S{:});
writetable(S, fullfile(outDir, 'summary.csv'));

%% Robustness over the seven conditions (one row per run)
W = cell(height(R), 1);
for k = 1:height(R)
    c = C(strcmp(C.tag, R.tag{k}), :);
    full = all(~isnan(c.LDmax) & ~isnan(c.LDmax_original));
    lo = nan(1, 3);  ld = nan(1, 3);  g = nan(1, 2);
    if full
        lo = [mean(c.LDmax_original), std(c.LDmax_original), min(c.LDmax_original)];
        ld = [mean(c.LDmax), std(c.LDmax), min(c.LDmax)];
        g = [mean(c.LDmax_gain_percent), min(c.LDmax_gain_percent)];
    end
    W{k} = table(R.tag(k), R.airfoil(k), R.formulation(k), R.seed(k), sum(~isnan(c.LDmax_gain_percent)), lo(1), lo(2), ...
        lo(3), ld(1), ld(2), ld(3), g(1), g(2), 'VariableNames', {'tag', 'airfoil', 'formulation', 'seed', 'conditions', ...
        'LDmax_mean_original', 'LDmax_std_original', 'LDmax_min_original', 'LDmax_mean', 'LDmax_std', 'LDmax_min', ...
        'mean_gain_percent', 'lowest_gain_percent'});
end
W = vertcat(W{:});
writetable(W, fullfile(outDir, 'robustness.csv'));
V = cell(0, 1);
for f = 1:numel(forms)
    w = W(strcmp(W.formulation, forms{f}) & W.seed == 1 & ~isnan(W.mean_gain_percent), :);
    if isempty(w), continue; end
    V{end+1, 1} = table(forms(f), height(w), median(w.mean_gain_percent), median(w.lowest_gain_percent), ...
        sum(w.lowest_gain_percent < 0), median(100 * (w.LDmax_std ./ w.LDmax_std_original - 1)), ...
        sum(strcmp(W.formulation, forms{f}) & W.seed == 1 & isnan(W.mean_gain_percent)), 'VariableNames', ...
        {'formulation', 'airfoils', 'median_mean_gain_percent', 'median_lowest_gain_percent', ...
        'designs_below_original_somewhere', 'median_std_change_percent', 'airfoils_without_all_conditions'}); %#ok<AGROW>
end
if ~isempty(V), writetable(vertcat(V{:}), fullfile(outDir, 'robustness_summary.csv')); end

%% Spread over the seeds (peak formulation, design condition)
D = C(strcmp(C.formulation, 'peak') & strcmp(C.condition, 'design'), :);
Z = cell(0, 1);
for k = 1:numel(names)
    v = D.LDmax(strcmp(D.airfoil, names{k}));
    if numel(v) < 2, continue; end
    Z{end+1, 1} = table(names(k), numel(v), mean(v), std(v), min(v), max(v), 100 * (max(v) - min(v)) / mean(v), ...
        'VariableNames', {'airfoil', 'seeds', 'LDmax_mean', 'LDmax_std', 'LDmax_min', 'LDmax_max', 'range_percent_of_mean'}); %#ok<AGROW>
end
if ~isempty(Z), writetable(vertcat(Z{:}), fullfile(outDir, 'seeds.csv')); end

%% Figures
show = intersect({'peak', 'alpha2', 'cldes', 'nocurv', 'robusttrip'}, forms, 'stable');
if isempty(show), show = forms(:).'; end               % only the robust runs so far
f = figure('Color', 'w', 'Position', [60 60 max(1150, 290 * numel(show)) 460], 'Visible', 'off');
tiledlayout(1, numel(show), 'TileSpacing', 'compact', 'Padding', 'compact');
for s = 1:numel(show)
    nexttile;  hold on;  box on;  grid on;
    for c = 1:nC
        g = C.LDmax_gain_percent(strcmp(C.formulation, show{s}) & C.seed == 1 & strcmp(C.condition, cond{c, 1}));
        g = g(~isnan(g));
        plot(c + 0.25 * (rand(size(g)) - 0.5), g, '.', 'Color', [0.55 0.55 0.55], 'MarkerSize', 9);
        if ~isempty(g), plot(c + [-0.3 0.3], median(g) * [1 1], 'k-', 'LineWidth', 2); end
    end
    yline(0, 'r:');
    set(gca, 'XTick', 1:nC, 'XTickLabel', cond(:, 1), 'XTickLabelRotation', 40);
    ylabel('gain in peak C_L / C_D (%)');  title(show{s}, 'Interpreter', 'none');
end
exportgraphics(f, fullfile(outDir, 'gains_by_condition.png'), 'Resolution', 130);
close(f);
if ~isempty(A)
    f = figure('Color', 'w', 'Position', [60 60 700 430], 'Visible', 'off');
    hold on;  box on;  grid on;
    for k = 1:numel(names)
        a = A(strcmp(A.airfoil, names{k}), :);
        plot(a.alpha, a.gain_percent, '-', 'Color', [0.6 0.6 0.6]);
    end
    ang = unique(A.alpha);
    plot(ang, arrayfun(@(x) median(A.gain_percent(A.alpha == x)), ang), 'k-', 'LineWidth', 2);
    yline(0, 'r:');  xlabel('\alpha at which the gain is reported (deg)');  ylabel('gain in C_L / C_D (%)');
    title('Designs optimised for peak C_L / C_D: gain by angle of attack');
    exportgraphics(f, fullfile(outDir, 'gain_by_angle.png'), 'Resolution', 130);
    close(f);
end
fprintf('%d runs, %d airfoils, %d XFOIL polars\n', height(R), numel(names), numel(P));
end

function [p, unstable] = stablePolar(xu, yu, xl, yl, Re, exe, flow, panels)
% XFOIL polar that does not depend on the load of the machine (see the header)
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
% of the peak]; NaN where XFOIL gave no value
v = nan(1, 7);
if numel(p.alpha) < 12 || p.alpha(1) > 0 || p.alpha(end) < 0, return; end    % no usable polar
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
