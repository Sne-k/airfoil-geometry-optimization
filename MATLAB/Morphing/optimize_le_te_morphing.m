%% Leading- and trailing-edge morphing with a fixed wing box
% Morphs only a droop nose (0 to 15 % chord) and a trailing edge (65 to
% 100 % chord); the wing box in between is not changed, as in the droop
% nose / morphing trailing edge study of Bashir et al. (Applied Sciences,
% 2021). Both surfaces are shifted by the same smooth deflection, so the
% thickness is kept:
%   nose:  dy = -dLE * ((0.15 - x)/0.15)^2   for x < 0.15
%   tail:  dy = -dTE * ((x - 0.65)/0.35)^2   for x > 0.65
% (positive = downwards). A grid of deflections is analysed with XFOIL and
% the best setting is found for three flight phases: cruise (CL/CD at
% CL = 0.4), loiter (maximum CL^1.5/CD) and high lift (CL,max). Every
% shape is analysed with 160 and 200 panel nodes and the lower value of each
% figure is used: large deflections can make XFOIL converge to a spurious,
% almost fully laminar solution (CD = 0.0026 at CL = 1.2) with one panelling.
%
% Output folder: MATLAB/output/le_te_morphing

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'NACA2412'), fullfile(root, 'Aerodynamics'));
outDir = fullfile(root, 'output', 'le_te_morphing');
if ~exist(outDir, 'dir'), mkdir(outDir); end
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end
Re = 1e6;
xLE = 0.15;  xTE = 0.65;
dLE = linspace(-0.02, 0.06, 9);          % nose deflection (fraction of chord)
dTE = linspace(-0.03, 0.06, 10);         % trailing-edge deflection

%% Base airfoil: NACA 2412
x = (1 - cos(linspace(0, pi, 150)')) / 2;
[xu, yu, xl, yl] = naca4(0.02, 0.40, 0.12, x, true);
yu0 = interp1(xu, yu, x, 'pchip', 'extrap');
yl0 = interp1(xl, yl, x, 'pchip', 'extrap');
shape = @(a, b) -a*max(xLE - x, 0).^2 / xLE^2 - b*max(x - xTE, 0).^2 / (1 - xTE)^2;

%% Grid of deflections
[A, B] = ndgrid(dLE, dTE);
cruise = nan(size(A));  loiter = nan(size(A));  clmax = nan(size(A));
parfor k = 1:numel(A)
    dy = shape(A(k), B(k));
    v = nan(2, 3);
    for n = 1:2
        panels = [];
        if n == 2, panels = 200; end
        p = xfoilPolar(x, yu0 + dy, x, yl0 + dy, Re, [-2 18 0.5], exe, panels);
        if numel(p.alpha) < 12, continue; end
        v(n, :) = [efficiencyValue(p, 'LDatCL', 0.4), efficiencyValue(p, 'endurance'), max(p.CL)];
    end
    v(v == 0) = NaN;
    cruise(k) = min(v(:, 1), [], 'includenan');
    loiter(k) = min(v(:, 2), [], 'includenan');
    clmax(k) = min(v(:, 3), [], 'includenan');
end

%% Best setting per flight phase
phases = {'cruise, CL/CD at CL = 0.4', 'loiter, max CL^1.5/CD', 'high lift, CL,max'};
maps = {cruise, loiter, clmax};
i0 = find(abs(A) < 1e-9 & abs(B) < 1e-9, 1);        % undeflected airfoil
rows = cell(3, 1);
f1 = figure('Color', 'w', 'Position', [100 100 1200 380]);
f2 = figure('Color', 'w', 'Position', [100 100 900 330]);
ax2 = axes(f2); hold(ax2, 'on');
xc = [flipud(x); x(2:end)];
plot(ax2, xc, [flipud(yu0); yl0(2:end)], 'k-', 'LineWidth', 1.2);
colors = {'b', 'r', 'm'};
for k = 1:3
    [v, ib] = max(maps{k}(:));
    rows{k} = {phases{k}, A(ib), B(ib), maps{k}(i0), v, 100*(v/maps{k}(i0) - 1)};
    figure(f1); subplot(1, 3, k);
    contourf(dTE, dLE, maps{k}, 12, 'LineColor', 'none'); colorbar; hold on;
    plot(B(ib), A(ib), 'wp', 'MarkerSize', 14, 'MarkerFaceColor', 'w');
    xlabel('trailing-edge deflection (c)'); ylabel('nose deflection (c)'); title(phases{k});
    dy = shape(A(ib), B(ib));
    plot(ax2, xc, [flipud(yu0 + dy); yl0(2:end) + dy(2:end)], [colors{k} '-'], 'LineWidth', 1.2);
    writeAirfoilDat(fullfile(outDir, sprintf('naca2412_morph_%d.dat', k)), ['NACA 2412 morphed for ' phases{k}], ...
        x, yu0 + dy, x, yl0 + dy);
end
T = cell2table(vertcat(rows{:}), 'VariableNames', {'Phase', 'dLE', 'dTE', 'NACA2412', 'Morphed', 'Gain_percent'});
writetable(T, fullfile(outDir, 'le_te_morphing.csv'));
disp(T);
exportgraphics(f1, fullfile(outDir, 'le_te_maps.png'), 'Resolution', 150);
axis(ax2, 'equal'); grid(ax2, 'on'); xlim(ax2, [0 1]);
xline(ax2, xLE, ':');
xline(ax2, xTE, ':');
legend(ax2, [{'NACA 2412'}, phases], 'Location', 'southoutside', 'NumColumns', 2);
title(ax2, 'Morphed shapes (nose and trailing edge only; wing box between the dotted lines)');
exportgraphics(f2, fullfile(outDir, 'le_te_shapes.png'), 'Resolution', 150);
