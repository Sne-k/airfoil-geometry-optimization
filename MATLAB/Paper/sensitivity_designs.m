function T = sensitivity_designs(outDir)
%SENSITIVITY_DESIGNS  How the gains depend on transition (Ncrit) and Reynolds number.
%   T = SENSITIVITY_DESIGNS analyses every seed airfoil of the paper batch
%   and its best design (the seed with the highest objective), the other
%   NACA 2412 designs (without curvature limits, cruise, loiter, weighted)
%   and the earlier PARSEC design, off the design condition:
%     Ncrit = 5, 7, 9 (design value) and 11 at Re = 10^6
%     Re = 0.5 and 2 million at Ncrit = 9
%   XFOIL, 160 panel nodes, alpha from -2 to 18 deg in 0.5 deg steps. The gain
%   of each design is taken against its original at the same condition.
%   Writes sensitivity.csv and sensitivity.png to outDir (default
%   results/paper).

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'Optimization'), fullfile(root, 'NACA2412'));
if nargin < 1 || isempty(outDir), outDir = fullfile(root, '..', 'results', 'paper'); end
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end
runs = readtable(fullfile(outDir, 'runs.csv'), 'TextType', 'char');
paperRuns = fullfile(root, 'output', 'paper');

% designs: {label, file or NACA code, label of its original}
D = {};
seedAirfoils = {'NACA_2412', 'NACA 2412'; 'NACA_0012', 'NACA 0012'; 'NACA_4412', 'NACA 4412'; ...
    'NACA_23012', 'NACA 23012'; 'CLARK_Y', fullfile(root, 'airfoils', 'clarky.dat')};
for k = 1:size(seedAirfoils, 1)
    orig = strrep(seedAirfoils{k, 1}, '_', ' ');
    D(end+1, :) = {orig, seedAirfoils{k, 2}, orig}; %#ok<AGROW>
    D(end+1, :) = {[orig ' optimised'], bestFile(runs, seedAirfoils{k, 1}, paperRuns), orig}; %#ok<AGROW>
end
for c = {'NACA_2412_nocurv', 'without curvature limits'; 'NACA_2412_cruise', 'cruise'; ...
         'NACA_2412_loiter', 'loiter'; 'NACA_2412_weighted', 'weighted'}'
    D(end+1, :) = {['NACA 2412 ' c{2}], bestFile(runs, c{1}, paperRuns), 'NACA 2412'}; %#ok<AGROW>
end
parsec = dir(fullfile(root, '..', 'results', 'xfoil', '*.dat'));
parsec = parsec(contains(lower({parsec.name}), 'parsec') & contains({parsec.name}, '12'));
if ~isempty(parsec)
    D(end+1, :) = {'NACA 2412 PARSEC design (earlier)', fullfile(parsec(1).folder, parsec(1).name), 'NACA 2412'};
end

cond = [1e6 5; 1e6 7; 1e6 9; 1e6 11; 5e5 9; 2e6 9];                  % [Re Ncrit]
jobs = [repelem((1:size(D, 1))', size(cond, 1)), repmat((1:size(cond, 1))', size(D, 1), 1)];
M = nan(size(jobs, 1), 5);
files = D(:, 2);
parfor j = 1:size(jobs, 1)
    [xu, yu, xl, yl] = readAirfoil(files{jobs(j, 1)});
    c = cond(jobs(j, 2), :);
    p = xfoilPolar(xu, yu, xl, yl, c(1), [-2 18 0.5], exe, [], true, struct('Ncrit', c(2)));
    m = efficiencyMetrics(p);
    M(j, :) = [m.LDmax, m.E15max, efficiencyValue(p, 'LDatCL', 0.4), efficiencyValue(p, 'LDatCL', 1.0), m.CLmax];
end
T = table(D(jobs(:, 1), 1), D(jobs(:, 1), 3), cond(jobs(:, 2), 1), cond(jobs(:, 2), 2), ...
    M(:, 1), M(:, 2), M(:, 3), M(:, 4), M(:, 5), 'VariableNames', ...
    {'design', 'original', 'Re', 'Ncrit', 'LDmax', 'E15max', 'LD_at_CL_0p4', 'LD_at_CL_1p0', 'CLmax'});
% gain against the original at the same condition
T.LDmax_gain_percent = nan(height(T), 1);
T.E15_gain_percent = nan(height(T), 1);
for j = 1:height(T)
    o = strcmp(T.design, T.original{j}) & T.Re == T.Re(j) & T.Ncrit == T.Ncrit(j);
    T.LDmax_gain_percent(j) = 100 * (T.LDmax(j) / T.LDmax(o) - 1);
    T.E15_gain_percent(j) = 100 * (T.E15max(j) / T.E15max(o) - 1);
end
writetable(T, fullfile(outDir, 'sensitivity.csv'));

% figure: gain in peak CL/CD against Ncrit (Re = 1e6) and against Re (Ncrit 9)
f = figure('Color', 'w', 'Position', [100 100 1150 480]);
opt = unique(T.design(~strcmp(T.design, T.original)), 'stable');
for s = 1:2
    subplot(1, 2, s); hold on;
    for k = 1:numel(opt)
        if s == 1
            m = strcmp(T.design, opt{k}) & T.Re == 1e6;  xv = T.Ncrit(m);
        else
            m = strcmp(T.design, opt{k}) & T.Ncrit == 9;  xv = T.Re(m) / 1e6;
        end
        [xv, o] = sort(xv);  g = T.LDmax_gain_percent(m);
        plot(xv, g(o), '-o', 'LineWidth', 1.2);
    end
    grid on; ylabel('gain in peak C_L/C_D over the original (%)');
    if s == 1
        xlabel('N_{crit} (Re = 10^6)'); title('Transition sensitivity');
    else
        xlabel('Re / 10^6 (N_{crit} = 9)'); title('Reynolds-number sensitivity');
        legend(opt, 'Location', 'eastoutside');
    end
end
exportgraphics(f, fullfile(outDir, 'sensitivity.png'), 'Resolution', 130);
close(f);
end

function f = bestFile(runs, caseName, paperRuns)
m = find(strcmp(runs.case_name, caseName));
[~, i] = max(runs.objective_final(m));
tag = runs.tag{m(i)};
d = dir(fullfile(paperRuns, tag, '*_optimized.dat'));
f = fullfile(d(1).folder, d(1).name);
end
