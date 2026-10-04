function T = gain_decomposition(outDir)
%GAIN_DECOMPOSITION  One reported gain taken apart, step by step (NACA 2412).
%   T = GAIN_DECOMPOSITION collects, from result files that are already in
%   the repository, how the gain in lift-to-drag ratio over NACA 2412
%   changes from the number of the project report to what is left under
%   stricter conditions, and writes gain_decomposition.csv and
%   gain_decomposition.png to outDir (default results/paper). No analysis
%   is run. The steps:
%     1  as reported: CL/CD at 0 deg of the 8 % thick airfoil of the project
%        report, from the report's XFLR5 analysis
%        (results/paper/report_values.csv)
%     2  the same metric with the XFOIL analysis of this repository
%        (results/xfoil/polar_report_airfoil.csv, polar_NACA2412.csv)
%     3  the same airfoil, peak CL/CD against peak CL/CD
%     4  thickness and pitching moment kept, XFOIL in the loop, no curvature
%        limits: mean of three seeds (results/paper/cases.csv)
%     5  with curvature limits (smooth shape): mean of three seeds
%     6  the smooth design of seed 1 away from its design condition: lowest
%        and highest gain over Ncrit 5, 7, 11 and Re 0.5e6, 2e6
%        (results/paper/sensitivity.csv)
%     7  the same design with boundary layers tripped at 5 % chord
%        (results/cfd/designs/xfoil.csv, M = 0.15)
%     8  the same design in RANS, best CL/CD over the angles run: Transition
%        SST and fully turbulent SST (results/cfd/designs/peaks.csv, when
%        the design study has been collected)
%   Every gain is against NACA 2412 under the same condition and method.
%   T has the columns step, description, gain_percent, gain_low_percent,
%   gain_high_percent (the range, where a step has one) and source.

here = fileparts(mfilename('fullpath'));
repo = fullfile(here, '..', '..');
res = fullfile(repo, 'results');
if nargin < 1 || isempty(outDir), outDir = fullfile(res, 'paper'); end

rows = cell(0, 6);
% 1 to 3: the airfoil of the report
V = readtable(fullfile(res, 'paper', 'report_values.csv'), 'Delimiter', ',');
v = V(strcmp(V.quantity, 'CL/CD at 0 deg'), :);
rows(end+1, :) = {1, 'as reported: CL/CD at 0 deg, report airfoil (8 % thick), XFLR5', ...
    100 * (v.report_airfoil / v.NACA_2412 - 1), NaN, NaN, 'results/paper/report_values.csv'};
R = readtable(fullfile(res, 'xfoil', 'polar_report_airfoil.csv'));
N = readtable(fullfile(res, 'xfoil', 'polar_NACA2412.csv'));
ld0 = @(P) P.CL(abs(P.alpha) < 1e-9) / P.CD(abs(P.alpha) < 1e-9);
C = readtable(fullfile(res, 'xfoil', 'approach_comparison.csv'), 'Delimiter', ',');
peakReport = C.LD_max(startsWith(C.Approach, 'Report method'));
peakNaca = C.LD_max(startsWith(C.Approach, 'NACA 2412 (baseline)'));
rows(end+1, :) = {2, 'the same metric with the XFOIL analysis used here', 100 * (ld0(R) / ld0(N) - 1), NaN, NaN, ...
    'results/xfoil/polar_report_airfoil.csv, polar_NACA2412.csv'};
rows(end+1, :) = {3, 'same airfoil, peak CL/CD against peak CL/CD', 100 * (peakReport / peakNaca - 1), NaN, NaN, ...
    'results/xfoil/approach_comparison.csv'};
% 4, 5: optimised with XFOIL in the loop, thickness and pitching moment kept
K = readtable(fullfile(res, 'paper', 'cases.csv'));
g = @(name, col) 100 * (K.(col)(strcmp(K.case_name, name)) / K.LDmax_original(strcmp(K.case_name, name)) - 1);
rows(end+1, :) = {4, 'thickness and pitching moment kept, no curvature limits (3 seeds)', g('NACA_2412_nocurv', 'LDmax_mean'), ...
    g('NACA_2412_nocurv', 'LDmax_min'), g('NACA_2412_nocurv', 'LDmax_max'), 'results/paper/cases.csv'};
rows(end+1, :) = {5, 'smooth shape: with curvature limits (3 seeds)', g('NACA_2412', 'LDmax_mean'), ...
    g('NACA_2412', 'LDmax_min'), g('NACA_2412', 'LDmax_max'), 'results/paper/cases.csv'};
% 6: off-design, the smooth design of seed 1
S = readtable(fullfile(res, 'paper', 'sensitivity.csv'), 'Delimiter', ',');
s = S(strcmp(S.design, 'NACA 2412 optimised') & ~(S.Re == 1e6 & S.Ncrit == 9), :);
rows(end+1, :) = {6, 'smooth design at other Ncrit (5 to 11) and Re (0.5 to 2 million)', mean(s.LDmax_gain_percent), ...
    min(s.LDmax_gain_percent), max(s.LDmax_gain_percent), 'results/paper/sensitivity.csv'};
% 7: tripped
X = readtable(fullfile(res, 'cfd', 'designs', 'xfoil.csv'));
best = @(design, cond) max(X.CL(strcmp(X.design, design) & strcmp(X.condition, cond)) ./ ...
    X.CD(strcmp(X.design, design) & strcmp(X.condition, cond)));
rows(end+1, :) = {7, 'smooth design, boundary layers tripped at 5 % chord', ...
    100 * (best('smooth_s1', 'tripped') / best('naca2412', 'tripped') - 1), NaN, NaN, 'results/cfd/designs/xfoil.csv'};
% 8: RANS
peaks = fullfile(res, 'cfd', 'designs', 'peaks.csv');
if isfile(peaks)
    P = readtable(peaks);
    names = {'transition', 'smooth design, RANS with Transition SST'; 'sst', 'smooth design, RANS fully turbulent (SST)'};
    for k = 1:size(names, 1)
        p = P(strcmp(P.method, names{k, 1}) & strcmp(P.design, 'smooth_s1'), :);
        n = P(strcmp(P.method, names{k, 1}) & strcmp(P.design, 'naca2412'), :);
        if isempty(p) || isempty(n) || isnan(p.gain_over_naca2412_percent), continue; end
        lo = NaN;  hi = NaN;
        if ~isnan(p.LD_min_at_best) && ~isnan(n.LD_max_at_best)     % range from the force cycles of both airfoils
            lo = 100 * (p.LD_min_at_best / n.LD_max_at_best - 1);
            hi = 100 * (p.LD_max_at_best / n.LD_min_at_best - 1);
        end
        rows(end+1, :) = {8, names{k, 2}, p.gain_over_naca2412_percent, lo, hi, 'results/cfd/designs/peaks.csv'}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'step', 'description', 'gain_percent', 'gain_low_percent', 'gain_high_percent', 'source'});
writetable(T, fullfile(outDir, 'gain_decomposition.csv'));

f = figure('Color', 'w', 'Position', [80 80 980 90 + 46 * height(T)], 'Visible', 'off');
hold on;  box on;  grid on;
y = height(T):-1:1;
col = repmat([0.20 0.45 0.70], height(T), 1);
col(T.gain_percent < 0, :) = repmat([0.80 0.30 0.20], sum(T.gain_percent < 0), 1);
for k = 1:height(T)
    barh(y(k), T.gain_percent(k), 0.6, 'FaceColor', col(k, :), 'EdgeColor', 'none');
    if ~isnan(T.gain_low_percent(k))
        plot([T.gain_low_percent(k) T.gain_high_percent(k)], [y(k) y(k)], 'k-', 'LineWidth', 1.6);
        plot([T.gain_low_percent(k) T.gain_high_percent(k)], [y(k) y(k)], 'k|', 'MarkerSize', 8);
    end
    xt = max([T.gain_percent(k), T.gain_high_percent(k), 0]);
    text(xt + 2, y(k), sprintf('%+.1f %%', T.gain_percent(k)), 'VerticalAlignment', 'middle');
end
xline(0, 'k-');
set(gca, 'YTick', fliplr(y), 'YTickLabel', flipud(T.description), 'TickLabelInterpreter', 'none');
xlim([min(-20, min(T.gain_percent) - 10), max(T.gain_percent) + 40]);
ylim([0.4, height(T) + 0.6]);
xlabel('gain in lift-to-drag ratio over NACA 2412 (%)');
title('One reported gain taken apart');
exportgraphics(f, fullfile(outDir, 'gain_decomposition.png'), 'Resolution', 130);
close(f);
end
