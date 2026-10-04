function collect_population_results(runDir, outDir, airfoilDir)
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
%                     gains. Conditions (Re 1e6 and Ncrit 9 unless stated):
%                     design, Ncrit 5, Ncrit 7, Ncrit 11, Re 0.5e6, Re 2e6,
%                     tripped (transition fixed at x/c = 0.05 on both
%                     surfaces)
%     summary.csv     statistics over the airfoils for every formulation
%                     and condition: median, quartiles, minimum, maximum of
%                     the gain in peak CL/CD, and the number of designs that
%                     are worse than their original
%     gain_by_angle.csv  gain in CL/CD of the peak-optimised designs at
%                     every angle of attack (design condition): the size of
%                     a gain depends on the angle at which it is reported
%     seeds.csv       spread of the peak CL/CD over the three seeds
%     airfoils/       the optimised .dat files
%   and the figures gains_by_condition.png and gain_by_angle.png.
%   The analysis uses XFOIL with 160 panel nodes, alpha from -2 to 18 deg in
%   0.5 deg steps. A gain is taken against the original airfoil at the same
%   condition. airfoilDir holds the UIUC coordinate files (default
%   MATLAB/airfoils/uiuc).

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'Optimization'), fullfile(root, 'NACA2412'));
if nargin < 1 || isempty(runDir), runDir = fullfile(root, 'output', 'population'); end
if nargin < 2 || isempty(outDir), outDir = fullfile(root, '..', 'results', 'population'); end
if nargin < 3 || isempty(airfoilDir), airfoilDir = fullfile(root, 'airfoils', 'uiuc'); end
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
parfor j = 1:size(jobs, 1)
    g = G(jobs(j, 1));
    if iscell(g.x), xu = g.x{1};  xl = g.x{2}; else, xu = g.x;  xl = g.x; end
    P{j} = xfoilPolar(xu, g.yu, xl, g.yl, cond{jobs(j, 2), 2}, [-2 18 0.5], exe, [], true, cond{jobs(j, 2), 3});
end
pol = @(tag, c) P{find(strcmp({G(jobs(:, 1)).tag}', tag) & jobs(:, 2) == c, 1)};

%% Metrics per run and condition
C = cell(0, 1);
A = cell(0, 1);
for k = 1:height(R)
    for c = 1:nC
        po = pol(['original:' R.airfoil{k}], c);
        pd = pol(R.tag{k}, c);
        v = [metrics(po, R.design_CL(k)); metrics(pd, R.design_CL(k))];
        g = 100 * (v(2, 1:3) ./ v(1, 1:3) - 1);
        C{end+1, 1} = table(R.tag(k), R.airfoil(k), R.formulation(k), R.seed(k), cond(c, 1), v(1, 1), v(2, 1), g(1), ...
            v(1, 2), v(2, 2), g(2), v(1, 3), v(2, 3), g(3), v(1, 4), v(2, 4), v(1, 5), v(2, 5), 'VariableNames', ...
            {'tag', 'airfoil', 'formulation', 'seed', 'condition', 'LDmax_original', 'LDmax', 'LDmax_gain_percent', ...
            'LD_2deg_original', 'LD_2deg', 'LD_2deg_gain_percent', 'LD_designCL_original', 'LD_designCL', ...
            'LD_designCL_gain_percent', 'alpha_LDmax_original', 'alpha_LDmax', 'CLmax_original', 'CLmax'}); %#ok<AGROW>
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
        g = g(~isnan(g));
        if isempty(g), continue; end
        S{end+1, 1} = table(forms(f), cond(c, 1), numel(g), median(g), quantile(g, 0.25), quantile(g, 0.75), min(g), max(g), ...
            sum(g < 0), 'VariableNames', {'formulation', 'condition', 'airfoils', 'median_gain_percent', 'q25', 'q75', ...
            'min', 'max', 'designs_worse_than_original'}); %#ok<AGROW>
    end
end
S = vertcat(S{:});
writetable(S, fullfile(outDir, 'summary.csv'));

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
f = figure('Color', 'w', 'Position', [60 60 1150 460], 'Visible', 'off');
show = intersect({'peak', 'alpha2', 'cldes', 'nocurv'}, forms, 'stable');
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

function v = metrics(p, designCL)
% [peak CL/CD, CL/CD at 2 deg, CL/CD at the design CL, angle of the peak, CL max]; NaN where XFOIL gave no value
v = nan(1, 5);
if isempty(p.alpha), return; end
m = efficiencyMetrics(p);
v([1 4 5]) = [m.LDmax, m.alphaLD, m.CLmax];
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
