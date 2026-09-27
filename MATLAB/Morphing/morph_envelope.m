%% What morphing gains: efficiency envelope between two optimised airfoils
% Blends a source and a target airfoil (e.g. a cruise and a loiter design)
% in nSteps steps and analyses every step with XFOIL. At each lift
% coefficient, a wing that can take any of these shapes flies with the best
% of them; this "morphing envelope" is compared with the fixed airfoils,
% including an optional single compromise design.
%
% Every shape is analysed with 160 and 200 panel nodes and the lower CL/CD
% is used at each lift coefficient. The analysis is quasi-steady (every
% shape is analysed as if fixed).
% Output folder: MATLAB/output/morph_envelope

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'NACA2412'), fullfile(root, 'Aerodynamics'));
outDir = fullfile(root, 'output', 'morph_envelope');
if ~exist(outDir, 'dir'), mkdir(outDir); end
res = fullfile(root, '..', 'results', 'optimize_airfoil');

sourceFile = fullfile(res, 'NACA_2412_cruise', 'NACA_2412_optimized.dat');     % cruise design
targetFile = fullfile(res, 'NACA_2412_loiter', 'NACA_2412_optimized.dat');     % loiter design
compromiseFile = fullfile(res, 'NACA_2412_weighted', 'NACA_2412_optimized.dat'); % '' to skip
names = {'cruise design', 'loiter design', 'weighted compromise'};
nSteps = 10;
Re = 1e6;
clGrid = (0.2:0.05:1.4)';
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end

%% Shapes on common stations
x = (1 - cos(linspace(0, pi, 150)')) / 2;
[yuS, ylS] = onGridFile(sourceFile, x);
[yuT, ylT] = onGridFile(targetFile, x);
[xu, yu, xl, yl] = naca4(0.02, 0.40, 0.12, x, true);
yuB = onGrid(xu, yu, x);  ylB = onGrid(xl, yl, x);

%% Polars along the morph (parallel if a pool is available)
f = (0:nSteps)' / nSteps;
ld = nan(numel(f), numel(clGrid));
parfor k = 1:numel(f)
    ld(k, :) = robustCurve(x, (1 - f(k))*yuS + f(k)*yuT, (1 - f(k))*ylS + f(k)*ylT, Re, exe, clGrid).';
end
[env, best] = max(ld, [], 1, 'omitnan');
ldBase = robustCurve(x, yuB, ylB, Re, exe, clGrid);
ldComp = nan(size(clGrid));
if ~isempty(compromiseFile)
    [yuC, ylC] = onGridFile(compromiseFile, x);
    ldComp = robustCurve(x, yuC, ylC, Re, exe, clGrid);
end

T = table(clGrid, ldBase, ld(1, :)', ld(end, :)', ldComp, env', f(best), ...
    'VariableNames', {'CL', 'NACA2412', 'cruise', 'loiter', 'compromise', 'morphing_envelope', 'best_step'});
writetable(T, fullfile(outDir, 'morph_envelope.csv'));
disp(T);

%% Figures
f1 = figure('Color', 'w', 'Position', [100 100 800 500]);
plot(clGrid, ldBase, 'k-', clGrid, ld(1, :), 'b-', clGrid, ld(end, :), 'r-', 'LineWidth', 1.3); hold on;
if ~isempty(compromiseFile), plot(clGrid, ldComp, 'm--', 'LineWidth', 1.3); end
plot(clGrid, env, 'g-', 'LineWidth', 3);
grid on; xlabel('C_L'); ylabel('C_L / C_D');
legend([{'NACA 2412'}, names(1:2 + ~isempty(compromiseFile)), {'morphing envelope'}], 'Location', 'southoutside', 'NumColumns', 3);
title('Efficiency at equal lift: fixed airfoils and a morphing airfoil (XFOIL, Re = 10^6)');
exportgraphics(f1, fullfile(outDir, 'morph_envelope.png'), 'Resolution', 150);

f2 = figure('Color', 'w', 'Position', [100 100 800 330]);
xc = [flipud(x); x(2:end)];
plot(xc, [flipud(yuS); ylS(2:end)], 'b-', xc, [flipud(yuT); ylT(2:end)], 'r-', 'LineWidth', 1.5);
axis equal; grid on; xlim([0 1]); xlabel('x/c'); ylabel('y/c');
legend(names(1:2), 'Location', 'southoutside', 'NumColumns', 2);
title('Morphing end states');
exportgraphics(f2, fullfile(outDir, 'morph_end_states.png'), 'Resolution', 150);

function [yu, yl] = onGridFile(file, x)
[xu, yu, xl, yl] = readAirfoil(file);
yu = onGrid(xu, yu, x);
yl = onGrid(xl, yl, x);
end

function y = onGrid(xs, ys, x)
[xs, i] = unique(xs(:));
y = interp1(xs, ys(i), x, 'pchip', 'extrap');
end

function ld = robustCurve(x, yu, yl, Re, exe, clGrid)
% CL/CD at the lift coefficients clGrid: lower value of the 160- and
% 200-panel analyses (NaN where either does not reach that lift)
ld = nan(numel(clGrid), 2);
for n = 1:2
    panels = [];
    if n == 2, panels = 200; end
    p = xfoilPolar(x, yu, x, yl, Re, [-2 18 0.5], exe, panels);
    for j = 1:numel(clGrid)
        ld(j, n) = efficiencyValue(p, 'LDatCL', clGrid(j));
    end
end
ld(ld == 0) = NaN;
ld = min(ld, [], 2, 'includenan');
end
