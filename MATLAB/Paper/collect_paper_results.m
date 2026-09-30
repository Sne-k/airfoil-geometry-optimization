function T = collect_paper_results(runDir, outDir)
%COLLECT_PAPER_RESULTS  Tables and figures of the paper batch (run_paper_batch.m).
%   T = COLLECT_PAPER_RESULTS reads every run in runDir (default
%   MATLAB/output/paper) and writes to outDir (default results/paper):
%     runs.csv        one row per run: settings, results and checks
%     cases.csv       statistics over the random seeds of each case
%     runs/<tag>/     optimised .dat file, polars, summary, run_info.json
%                     (local paths removed) and the evaluation history
%                     (without the design variables)
%     convergence_optimisers.png  best objective against the number of
%                     designs analysed with XFOIL and against evaluations
%     airfoils_smooth.png         original and optimised airfoils (best seed)
%     curvature_limits_effect.png NACA 2412 with and without curvature limits
%     flight_phases.png           CL/CD against CL of the NACA 2412 designs
%   Checks per run: whether the design meets the curvature limits of its
%   original, the median duration of an analysed design (machine speed),
%   the share of XFOIL-analysed designs that were rejected afterwards and
%   the worst share in any 30 consecutive analysed designs (a burst would
%   point to a disturbed run).

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'Optimization'), fullfile(root, 'Aerodynamics'), fullfile(root, 'NACA2412'));
if nargin < 1 || isempty(runDir), runDir = fullfile(root, 'output', 'paper'); end
if nargin < 2 || isempty(outDir), outDir = fullfile(root, '..', 'results', 'paper'); end
if ~exist(fullfile(outDir, 'runs'), 'dir'), mkdir(fullfile(outDir, 'runs')); end

caseOrder = {'NACA_2412', 'NACA_2412_nocurv', 'NACA_2412_weighted', 'cmp_ga', 'cmp_pso', ...
    'cmp_bayesopt', 'NACA_0012', 'NACA_4412', 'NACA_23012', 'CLARK_Y', 'NACA_2412_cruise', ...
    'NACA_2412_loiter', 'NACA_2412_keepclmax'};
d = dir(fullfile(runDir, '*', 'run_info.json'));
rows = cell(numel(d), 1);
res = cell(numel(d), 1);
hist = cell(numel(d), 1);
for k = 1:numel(d)
    folder = d(k).folder;
    [~, tag] = fileparts(folder);
    raw = fileread(fullfile(folder, 'run_info.json'));
    info = jsondecode(raw);
    s = load(fullfile(folder, 'result.mat'));
    r = s.result;
    H = readtable(fullfile(folder, 'history.csv'));
    analysed = H.xfoil_analyses > 0;
    rejected = analysed & (H.objective == 0 | isnan(H.objective));
    fa = double(rejected(analysed));
    worst = mean(fa);
    if numel(fa) >= 30, worst = max(movmean(fa, 30, 'Endpoints', 'discard')); end
    sm = r.summary;
    val = @(q) sm{strcmp(sm.Quantity, q), {'Original', 'Optimized'}};
    ld = val('max CL/CD');  e15 = val('max CL^1.5/CD');  clm = val('CL max');
    cm = val('CM at alpha = 0');  tc = val('t/c max');  al = val('alpha at max CL/CD (deg)');
    row = struct();
    row.tag = tag;
    row.case_name = regexprep(tag, '_s\d+$', '');
    row.seed = info.options.Seed;
    row.airfoil = info.airfoil;
    row.objective = info.options.Objective;
    row.design_CL = strtrim(sprintf('%g ', info.options.DesignCL));
    row.algorithm = info.options.Algorithm;
    row.local_search = logical(info.options.LocalSearch);
    row.curvature_limits = logical(info.options.Curvature);
    row.objective_original_fit = info.objectiveOriginalFit;
    row.objective_global = info.objectiveGlobal;
    row.objective_final = info.objectiveFinal;
    row.objective_gain_percent = 100 * (info.objectiveFinal / info.objectiveOriginalFit - 1);
    row.LDmax_original = ld(1);  row.LDmax_optimized = ld(2);  row.alpha_LDmax_optimized = al(2);
    row.E15_original = e15(1);  row.E15_optimized = e15(2);
    row.CLmax_original = clm(1);  row.CLmax_optimized = clm(2);
    row.CM0_original = cm(1);  row.CM0_optimized = cm(2);
    row.tc_original = tc(1);  row.tc_optimized = tc(2);
    row.reversals_top = r.curvatureOptimized.reversalsTop;
    row.reversals_bottom = r.curvatureOptimized.reversalsBot;
    row.te_curvature_top = r.curvatureOptimized.teCurvTop;
    row.te_curvature_bottom = r.curvatureOptimized.teCurvBot;
    row.meets_curvature_limits = logical(info.designMeetsCurvatureLimits);
    row.evaluations = info.evaluations;
    row.xfoil_analysed = info.xfoilAnalysedDesigns;
    row.rejected_after_xfoil_percent = 100 * mean(fa);
    row.worst_30_rejected_percent = 100 * worst;
    row.median_eval_seconds = info.medianEvaluationSeconds;
    row.run_time_min = info.runTimeSeconds / 60;
    row.git_commit = info.gitCommit;
    rows{k} = row;
    res{k} = r;
    hist{k} = H;

    % files for the repository (no local paths)
    dest = fullfile(outDir, 'runs', tag);
    if ~exist(dest, 'dir'), mkdir(dest); end
    datFile = dir(fullfile(folder, '*_optimized.dat'));
    copyfile(fullfile(folder, datFile(1).name), dest);
    for f = {'polar_original.csv', 'polar_optimized.csv', 'summary.csv'}
        copyfile(fullfile(folder, f{1}), dest);
    end
    raw = regexprep(raw, '"OutputDir":\s*"[^"]*"', sprintf('"OutputDir": "MATLAB/output/paper/%s"', tag));
    raw = regexprep(raw, '"path":\s*"[^"]*"', '"path": "xfoil.exe (XFOIL 6.99, not included)"');
    fid = fopen(fullfile(dest, 'run_info.json'), 'w');
    fprintf(fid, '%s', raw);
    fclose(fid);
    writetable(H(:, {'time_s', 'stage', 'objective', 'xfoil_analyses', 'eval_seconds'}), ...
        fullfile(dest, 'history.csv'));
end
T = struct2table(vertcat(rows{:}));
[~, ci] = ismember(T.case_name, caseOrder);
[~, order] = sortrows([ci, T.seed]);
T = T(order, :);  res = res(order);  hist = hist(order);
writetable(T, fullfile(outDir, 'runs.csv'));

%% Statistics over the seeds
cases = unique(T.case_name, 'stable');
C = cell(numel(cases), 1);
for k = 1:numel(cases)
    m = strcmp(T.case_name, cases{k});
    c = struct();
    c.case_name = cases{k};
    c.objective = T.objective{find(m, 1)};
    c.seeds = sum(m);
    c.objective_original_fit = T.objective_original_fit(find(m, 1));
    c.objective_mean = mean(T.objective_final(m));
    c.objective_std = std(T.objective_final(m));
    c.objective_min = min(T.objective_final(m));
    c.objective_max = max(T.objective_final(m));
    c.gain_percent_mean = mean(T.objective_gain_percent(m));
    c.LDmax_original = T.LDmax_original(find(m, 1));
    c.LDmax_mean = mean(T.LDmax_optimized(m));
    c.LDmax_min = min(T.LDmax_optimized(m));
    c.LDmax_max = max(T.LDmax_optimized(m));
    c.E15_mean = mean(T.E15_optimized(m));
    c.CLmax_original = T.CLmax_original(find(m, 1));
    c.CLmax_mean = mean(T.CLmax_optimized(m));
    c.CM0_mean = mean(T.CM0_optimized(m));
    c.all_meet_curvature_limits = all(T.meets_curvature_limits(m));
    c.xfoil_analysed_mean = mean(T.xfoil_analysed(m));
    c.run_time_min_mean = mean(T.run_time_min(m));
    C{k} = c;
end
C = struct2table(vertcat(C{:}));
writetable(C, fullfile(outDir, 'cases.csv'));

best = @(name) find(strcmp(T.case_name, name) & T.objective_final == max(T.objective_final(strcmp(T.case_name, name))), 1);

%% Optimiser comparison: convergence
f = figure('Color', 'w', 'Position', [100 100 1100 420]);
algs = {'cmp_ga', 'cmp_pso', 'cmp_bayesopt'};
labels = {'genetic algorithm', 'particle swarm', 'Bayesian optimisation'};
colors = lines(3);
styles = {'-', '--', ':'};
hs = gobjects(1, 3);
for a = 1:3
    idx = find(strcmp(T.case_name, algs{a}));
    for j = 1:numel(idx)
        H = hist{idx(j)};
        keep = ismember(H.stage, {'start', 'global'});
        H = H(keep, :);
        obj = -H.objective;
        obj(~(obj > 0)) = NaN;
        bestSoFar = cummax(fillmissing(obj, 'constant', -Inf));
        nx = cumsum(H.xfoil_analyses > 0);
        subplot(1, 2, 1); hold on;
        h = plot(nx, bestSoFar, styles{j}, 'Color', colors(a, :), 'LineWidth', 1.3);
        if j == 1, hs(a) = h; end
        subplot(1, 2, 2); hold on;
        plot((1:height(H))', bestSoFar, styles{j}, 'Color', colors(a, :), 'LineWidth', 1.3);
    end
end
subplot(1, 2, 1); grid on; xlabel('designs analysed with XFOIL'); ylabel('best peak C_L/C_D so far');
legend(hs, labels, 'Location', 'southeast'); ylim([100 inf]);
title('NACA 2412, equal budget, three seeds each');
subplot(1, 2, 2); grid on; xlabel('evaluations (including designs rejected by the limits)');
ylabel('best peak C_L/C_D so far'); ylim([100 inf]);
exportgraphics(f, fullfile(outDir, 'convergence_optimisers.png'), 'Resolution', 130);

%% Original and optimised airfoils (best seed of each)
foils = {'NACA_0012', 'NACA_2412', 'NACA_4412', 'NACA_23012', 'CLARK_Y'};
f = figure('Color', 'w', 'Position', [60 60 1100 1250]);
for k = 1:numel(foils)
    i = best(foils{k});
    r = res{i};
    [yuF, ylF] = cstSurfaces(r.Au, r.Al, r.dte, r.x);
    subplot(numel(foils), 2, 2*k - 1);
    plot(r.x, yuF, 'k-', r.x, ylF, 'k-', r.x, r.yu, 'r-', r.x, r.yl, 'r-', 'LineWidth', 1.2);
    axis equal; grid on; xlim([0 1]);
    title(sprintf('%s: original (black), optimised seed %d (red)', r.name, T.seed(i)), 'Interpreter', 'none');
    subplot(numel(foils), 2, 2*k);
    po = r.polarOriginal;  pn = r.polarOptimized;
    plot(po.alpha, po.CL ./ po.CD, 'k-', pn.alpha, pn.CL ./ pn.CD, 'r-', 'LineWidth', 1.2);
    grid on; xlabel('\alpha (deg)'); ylabel('C_L/C_D');
    title(sprintf('peak C_L/C_D %.1f \\rightarrow %.1f', T.LDmax_original(i), T.LDmax_optimized(i)));
end
exportgraphics(f, fullfile(outDir, 'airfoils_smooth.png'), 'Resolution', 110);

%% NACA 2412 with and without curvature limits
iS = best('NACA_2412');  iW = best('NACA_2412_nocurv');
rs = res{iS};  rw = res{iW};
f = figure('Color', 'w', 'Position', [60 60 1250 420]);
subplot(1, 3, 1);
plot(rs.x, rs.yu, 'b-', rs.x, rs.yl, 'b-', rw.x, rw.yu, 'r--', rw.x, rw.yl, 'r--', 'LineWidth', 1.2);
axis equal; grid on; xlim([0 1]); title('shapes: with limits (blue), without (red)');
subplot(1, 3, 2);
xg = rs.curvatureLimits.x;
plot(xg, cstCurvature(rs.AuOpt, rs.dte, xg, 'upper'), 'b-', xg, cstCurvature(rs.AlOpt, rs.dte, xg, 'lower'), 'b:', ...
     xg, cstCurvature(rw.AuOpt, rw.dte, xg, 'upper'), 'r-', xg, cstCurvature(rw.AlOpt, rw.dte, xg, 'lower'), 'r:', 'LineWidth', 1.2);
grid on; xlabel('x/c'); ylabel('curvature (convex > 0)'); ylim([-2 4]);
legend('upper, with limits', 'lower, with limits', 'upper, without', 'lower, without', 'Location', 'north');
subplot(1, 3, 3);
p0 = rs.polarOriginal;  ps = rs.polarOptimized;  pw = rw.polarOptimized;
plot(p0.CL, p0.CL ./ p0.CD, 'k-', ps.CL, ps.CL ./ ps.CD, 'b-', pw.CL, pw.CL ./ pw.CD, 'r--', 'LineWidth', 1.2);
grid on; xlabel('C_L'); ylabel('C_L/C_D'); legend('NACA 2412', 'with limits', 'without limits', 'Location', 'south');
exportgraphics(f, fullfile(outDir, 'curvature_limits_effect.png'), 'Resolution', 120);

%% Flight-phase designs of NACA 2412
phases = {'NACA_2412', 'NACA_2412_cruise', 'NACA_2412_loiter', 'NACA_2412_weighted', 'NACA_2412_keepclmax'};
names = {'peak C_L/C_D', 'cruise (C_L = 0.4)', 'loiter (C_L^{1.5}/C_D)', 'weighted cruise + loiter', 'peak C_L/C_D, keep C_{L,max}'};
f = figure('Color', 'w', 'Position', [100 100 800 520]);
p0 = res{best('NACA_2412')}.polarOriginal;
plot(p0.CL, p0.CL ./ p0.CD, 'k-', 'LineWidth', 2); hold on;
for k = 1:numel(phases)
    p = res{best(phases{k})}.polarOptimized;
    plot(p.CL, p.CL ./ p.CD, 'LineWidth', 1.3);
end
grid on; xlabel('C_L'); ylabel('C_L/C_D'); xlim([0 1.6]);
legend([{'NACA 2412'}, names], 'Location', 'southoutside', 'NumColumns', 2);
title('NACA 2412 designs for different flight phases (best seed each, XFOIL, Re = 10^6)');
exportgraphics(f, fullfile(outDir, 'flight_phases.png'), 'Resolution', 130);
close all;
fprintf('collect_paper_results: %d runs, %d cases -> %s\n', height(T), height(C), outDir);
end
