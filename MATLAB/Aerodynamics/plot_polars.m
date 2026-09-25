%% Shapes and XFOIL polars of NACA 2412 and its optimised versions
% Reads the polars and .dat files in results/xfoil (no XFOIL run needed) and
% writes results/xfoil/designs.png, polars.png and ld_at_cl.csv.

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
res = fullfile(here, '..', '..', 'results');
addpath(here);

names = {'NACA 2412 (baseline)', 'Report airfoil (camber/thickness)', ...
         'PARSEC, XFOIL-optimised, t \geq 12%', 'CST, optimize\_airfoil'};
plain = {'NACA 2412 (baseline)', 'Report airfoil (camber/thickness)', ...
         'PARSEC, XFOIL-optimised, t >= 12%', 'CST, optimize_airfoil'};
polars = {'polar_NACA2412.csv', 'polar_report_airfoil.csv', 'polar_parsec_t12.csv', 'polar_cst.csv'};
dats = {fullfile(res, 'airfoils', 'NACA2412_baseline.dat'), ...
        fullfile(res, 'airfoils', 'optimized_m050_p516_t080.dat'), ...
        fullfile(res, 'xfoil', 'NACA2412_parsec_t12_optimized.dat'), ...
        fullfile(res, 'xfoil', 'NACA2412_cst_optimized.dat')};
styles = {'k-', 'r-', 'b-', 'm-'};

%% Shapes
f1 = figure('Color', 'w', 'Position', [100 100 900 330]);
hold on;
for k = 1:numel(dats)
    [xu, yu, xl, yl] = readAirfoil(dats{k});
    plot([flipud(xu(:)); xl(:)], [flipud(yu(:)); yl(:)], styles{k}, 'LineWidth', 1.5);
end
axis equal; grid on; xlim([0 1]);
xlabel('x/c'); ylabel('y/c');
legend(names, 'Location', 'southoutside', 'NumColumns', 2);
title('NACA 2412 and its optimised versions');
exportgraphics(f1, fullfile(res, 'xfoil', 'designs.png'), 'Resolution', 150);

%% Polars
f2 = figure('Color', 'w', 'Position', [100 100 1100 470]);
tl = tiledlayout(1, 3, 'TileSpacing', 'compact');
ax = [nexttile(tl), nexttile(tl), nexttile(tl)];
for a = ax, hold(a, 'on'); grid(a, 'on'); end
clTargets = [0.3 0.5 0.8 1.0 1.2];
ldAtCL = nan(numel(polars), numel(clTargets));
for k = 1:numel(polars)
    P = readtable(fullfile(res, 'xfoil', polars{k}));
    plot(ax(1), P.alpha, P.CL, styles{k}, 'LineWidth', 1.5);
    plot(ax(2), P.CL, P.CL ./ P.CD, styles{k}, 'LineWidth', 1.5);
    plot(ax(3), P.alpha, P.CM, styles{k}, 'LineWidth', 1.5);

    % L/D at fixed lift coefficients (first crossing on the attached branch)
    for j = 1:numel(clTargets)
        ldAtCL(k, j) = efficiencyValue(P, 'LDatCL', clTargets(j));
    end
end
ldAtCL(ldAtCL == 0) = NaN;                   % lift coefficient not reached
xlabel(ax(1), '\alpha (deg)'); ylabel(ax(1), 'C_L'); title(ax(1), 'Lift');
xlabel(ax(2), 'C_L'); ylabel(ax(2), 'C_L / C_D'); title(ax(2), 'Efficiency at equal lift');
xlim(ax(2), [0 1.7]);
xlabel(ax(3), '\alpha (deg)'); ylabel(ax(3), 'C_M (c/4)'); title(ax(3), 'Pitching moment');
lg = legend(ax(1), names, 'NumColumns', 4);
lg.Layout.Tile = 'south';
title(tl, 'XFOIL, Re = 10^6, M = 0, N_{crit} = 9');
exportgraphics(f2, fullfile(res, 'xfoil', 'polars.png'), 'Resolution', 150);

T = array2table(round(ldAtCL, 1), 'VariableNames', compose('LD_at_CL_%.1f', clTargets));
T = addvars(T, plain(:), 'Before', 1, 'NewVariableNames', 'Airfoil');
writetable(T, fullfile(res, 'xfoil', 'ld_at_cl.csv'));
disp(T);
