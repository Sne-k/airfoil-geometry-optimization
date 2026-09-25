%% Aerodynamic comparison of the approaches tried in the project
% Analyses the final airfoil of every approach with the same XFOIL set-up
% (Re = 1e6, Mach 0, Ncrit 9, re-panelled, alpha = -2..18 deg) and ranks
% them by maximum lift-to-drag ratio. Airfoils from the XFOIL optimisations
% and the PARSEC GA are included when their scripts have been run.
%
% Output folder: MATLAB/output/aero

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(here, fullfile(root, 'NACA2412'), fullfile(root, 'PARSEC'));
outDir = fullfile(root, 'output', 'aero');
if ~exist(outDir, 'dir'), mkdir(outDir); end

exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(here, 'xfoil.exe'); end
Re = 1e6;
x = (1 - cos(linspace(0, pi, 150)')) / 2;

%% Airfoils: {name, xu, yu, xl, yl}
A = cell(0, 5);
A(end+1, :) = nacaCase('NACA 2412 (baseline)', [0.02 0.40 0.12], x);
A(end+1, :) = nacaCase('Report method: GA+fmincon, camber/thickness (gian.m)', [0.05 0.5158 0.08], x);
A(end+1, :) = nacaCase('GA+PSO+fmincon with sign bug (suniyo/deki.m)', [0.00 0.40 0.13], x);
A(end+1, :) = nacaCase('NSGA-II multi-objective (idkwimdt.m)', [0.0540 0.4855 0.0800], x);
A(end+1, :) = bezierCase('Bezier camber, 12% thick (letshope.m, fixed)', [0 0; 0.4 0.04; 0.7 0.025; 1 0], 0.12, 0.06, x);
A(end+1, :) = bezierCase('Thin Bezier "supersonic" target (trialgp.m)', [0 0; 0.3 0.005; 0.6 0.002; 1 0], 0.05, 0, x);
pFit = [0.01495 0.32556 0.07946 -0.63759 0.22209 -0.04144 0.22360 0 0 -2.81359 19.52005];
[yu, yl] = parsecSurfaces(pFit, x);
A(end+1, :) = {'PARSEC fit of NACA 2412', x, yu, x, yl};
optional = {'PARSEC GA, minimum area (GAairfoil.m)', fullfile(root, 'output', 'parsec_ga', 'parsec_ga_optimized.dat');
            'XFOIL GA+fmincon, NACA, t >= 0.08', fullfile(root, 'output', 'optimization_xfoil', 'xfoil_naca_t08.dat');
            'XFOIL GA+fmincon, NACA, t >= 0.12', fullfile(root, 'output', 'optimization_xfoil', 'xfoil_naca_t12.dat');
            'XFOIL GA+fmincon, PARSEC, t >= 0.08', fullfile(root, 'output', 'optimization_xfoil', 'xfoil_parsec_t08.dat');
            'XFOIL GA+fmincon, PARSEC, t >= 0.12', fullfile(root, 'output', 'optimization_xfoil', 'xfoil_parsec_t12.dat');
            'optimize_airfoil (CST, XFOIL GA+fmincon), NACA 2412', fullfile(root, 'output', 'optimize_airfoil', 'NACA_2412', 'NACA_2412_optimized.dat')};
for k = 1:size(optional, 1)
    if isfile(optional{k, 2})
        A(end+1, :) = datCase(optional{k, 1}, optional{k, 2}); %#ok<SAGROW>
    end
end

%% Analyse
n = size(A, 1);
names = A(:, 1);
T = table('Size', [n 9], 'VariableTypes', repmat({'double'}, 1, 9), 'VariableNames', ...
    {'t_max', 'LD_max', 'alpha_LDmax', 'CL_at_LDmax', 'CL15_CD_max', 'CL_max', 'alpha_CLmax', 'CD_min', 'CM_0'});
polars = cell(n, 1);
for k = 1:n
    [~, xu, yu, xl, yl] = A{k, :};
    polars{k} = xfoilPolar(xu, yu, xl, yl, Re, [-2 18 0.5], exe);
    m = efficiencyMetrics(polars{k});
    T{k, :} = [thickness(xu, yu, xl, yl), m.LDmax, m.alphaLD, m.CL_LD, m.E15max, ...
               m.CLmax, m.alphaStall, m.CDmin, m.CM0];
end
T = addvars(T, names, 'Before', 1, 'NewVariableNames', 'Approach');
[T, order] = sortrows(T, 'LD_max', 'descend');
polars = polars(order);
disp(T);
writetable(T, fullfile(outDir, 'approach_comparison.csv'));

%% Figures
f1 = figure('Color', 'w', 'Position', [100 100 900 520]);
barh(flipud(T.LD_max));
set(gca, 'YTick', 1:n, 'YTickLabel', flipud(T.Approach), 'TickLabelInterpreter', 'none');
xlabel('maximum lift-to-drag ratio (XFOIL, Re = 10^6)');
title('Aerodynamic efficiency of every approach');
grid on;
exportgraphics(f1, fullfile(outDir, 'approach_comparison.png'), 'Resolution', 150);

f2 = figure('Color', 'w', 'Position', [100 100 800 500]);
hold on; grid on;
top = unique([1:min(4, n), find(strcmp(T.Approach, 'NACA 2412 (baseline)'))]);
for k = top
    plot(polars{k}.alpha, polars{k}.CL ./ polars{k}.CD, 'LineWidth', 1.8, 'DisplayName', T.Approach{k});
end
xlabel('\alpha (deg)'); ylabel('C_L / C_D');
legend('Location', 'southoutside', 'Interpreter', 'none');
title('Lift-to-drag ratio, XFOIL Re = 10^6');
exportgraphics(f2, fullfile(outDir, 'ld_polars.png'), 'Resolution', 150);

function row = nacaCase(name, v, x)
[xu, yu, xl, yl] = naca4(v(1), v(2), v(3), x);
row = {name, xu, yu, xl, yl};
end

function row = bezierCase(name, P, t, halfThickness, x)
% Bezier camber line with the NACA thickness laid off vertically, as in
% letshope.m and trialgp.m (the Bezier parameter is used as x)
n = size(P, 1) - 1;
yc = zeros(size(x));
for i = 0:n
    yc = yc + nchoosek(n, i) * (1 - x).^(n - i) .* x.^i * P(i+1, 2);
end
yt = 5*t*(0.2969*sqrt(x) - 0.1260*x - 0.3516*x.^2 + 0.2843*x.^3 - 0.1015*x.^4);
if halfThickness > 0
    yt = yt / max(yt) * halfThickness;
end
yu = yc + yt; yl = yc - yt;
yu(end) = yc(end); yl(end) = yc(end);
row = {name, x, yu, x, yl};
end

function row = datCase(name, file)
% Selig .dat file -> both surfaces from the leading edge to the trailing edge
d = readmatrix(file, 'FileType', 'text', 'NumHeaderLines', 1);
[~, iLE] = min(d(:, 1));
up = flipud(d(1:iLE, :));
lo = d(iLE:end, :);
row = {name, up(:, 1), up(:, 2), lo(:, 1), lo(:, 2)};
end

function t = thickness(xu, yu, xl, yl)
% Maximum thickness from both surfaces interpolated on a common grid
xs = linspace(0.01, 0.99, 400)';
iu = xu > 0.005; il = xl > 0.005;
t = max(interp1(xu(iu), yu(iu), xs, 'pchip') - interp1(xl(il), yl(il), xs, 'pchip'));
end
