%% Morphing from NACA 2412 to an optimised airfoil, with the efficiency of every step
% Blends the surface coordinates of NACA 2412 and a target airfoil (any
% .dat file) on common cosine-spaced stations, so it works for targets that
% are not NACA sections (e.g. the PARSEC design). Writes a .dat file and a
% frame for each step and computes the peak lift-to-drag ratio of every
% other step with XFOIL (see Aerodynamics/README.md).
%
% Output folder: MATLAB/output/morph_to_design

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'NACA2412'), fullfile(root, 'Aerodynamics'));
outDir = fullfile(root, 'output', 'morph_to_design');
if ~exist(outDir, 'dir'), mkdir(outDir); end

targetFile = fullfile(root, '..', 'results', 'xfoil', 'NACA2412_parsec_t12_optimized.dat');
nSteps = 20;
Re = 1e6;
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end

%% Start and end shapes on the same stations
x = (1 - cos(linspace(0, pi, 150)')) / 2;
[xu, yu, xl, yl] = naca4(0.02, 0.40, 0.12, x, true);
yuB = onGrid(xu, yu, x);  ylB = onGrid(xl, yl, x);
[xu, yu, xl, yl] = readAirfoil(targetFile);
yuT = onGrid(xu, yu, x);  ylT = onGrid(xl, yl, x);

%% Morphing loop
ld = nan(nSteps + 1, 1);
fig = figure('Color', 'w', 'Position', [100 100 800 400]);
gifFile = fullfile(outDir, 'morph_to_design.gif');
for k = 0:nSteps
    f = k / nSteps;
    yu = (1 - f)*yuB + f*yuT;
    yl = (1 - f)*ylB + f*ylT;
    writeAirfoilDat(fullfile(outDir, sprintf('morph_%02d.dat', k)), sprintf('Morph step %d', k), x, yu, x, yl);
    if mod(k, 2) == 0
        ld(k+1) = efficiencyValue(xfoilPolar(x, yu, x, yl, Re, [-2 12 0.5], exe), 'LDmax');
    end

    clf(fig);
    plot(x, yuB, '-', x, ylB, '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 1); hold on;
    plot(x, yu, 'b-', x, yl, 'b-', 'LineWidth', 1.8);
    axis equal; axis([0 1 -0.08 0.14]); grid on;
    xlabel('x/c'); ylabel('y/c');
    title(sprintf('NACA 2412 \\rightarrow optimised design: step %d/%d', k, nSteps));
    drawnow;
    [im, map] = rgb2ind(frame2im(getframe(fig)), 32);
    delay = 0.12;
    if k == 0 || k == nSteps, delay = 1.0; end
    if k == 0
        imwrite(im, map, gifFile, 'gif', 'LoopCount', Inf, 'DelayTime', delay);
    else
        imwrite(im, map, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
    end
end

writetable(table((0:nSteps)', ld, 'VariableNames', {'step', 'LD_max'}), ...
    fullfile(outDir, 'morph_efficiency.csv'));
f2 = figure('Color', 'w');
ok = ~isnan(ld);
plot(100*(find(ok) - 1)/nSteps, ld(ok), 'o-', 'LineWidth', 1.8);
grid on; xlabel('morphing progress (%)'); ylabel('peak C_L/C_D (XFOIL, Re = 10^6)');
title('Efficiency along the morph from NACA 2412');
exportgraphics(f2, fullfile(outDir, 'morph_efficiency.png'), 'Resolution', 150);

function y = onGrid(xs, ys, x)
% Surface interpolated on the stations x
[xs, i] = unique(xs(:));
y = interp1(xs, ys(i), x, 'pchip', 'extrap');
end
