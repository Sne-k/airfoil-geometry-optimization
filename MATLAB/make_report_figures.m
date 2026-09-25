%% Figures for the repository README
% Rebuilds results/figures from the airfoil files that were analysed in
% XFLR5 for the report (results/morph_sequence):
%   geometry_comparison.png  baseline vs optimised airfoil
%   objective_landscape.png  camber/thickness objective over (m, t)
%   morphing.gif             the 21-step morphing sequence

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'NACA2412'), fullfile(here, 'Optimization'));
resDir = fullfile(here, '..', 'results');
seqDir = fullfile(resDir, 'morph_sequence');
figDir = fullfile(resDir, 'figures');
if ~exist(figDir, 'dir'), mkdir(figDir); end

%% Baseline vs optimised (step 0 and step 20 of the analysed sequence)
[xb, yb] = readDat(fullfile(seqDir, 'naca2412_morph_00.dat'));
[xo, yo] = readDat(fullfile(seqDir, 'naca2412_morph_20.dat'));
f1 = figure('Color', 'w', 'Position', [100 100 900 380]);
plot(xb, yb, 'b-', 'LineWidth', 2); hold on;
plot(xo, yo, 'r--', 'LineWidth', 2);
axis equal; grid on; xlim([0 1]); ylim([-0.08 0.12]);
xlabel('x/c'); ylabel('y/c');
legend('NACA 2412 (baseline)', 'Optimised: m = 0.050, p = 0.516, t = 0.080', 'Location', 'southeast');
title('Airfoils analysed in XFLR5');
exportgraphics(f1, fullfile(figDir, 'geometry_comparison.png'), 'Resolution', 150);

%% Objective landscape: camber/thickness over (m, t) at p = 0.516
x = linspace(0, 1, 100)';
m = linspace(0, 0.05, 41);
t = linspace(0.08, 0.15, 36);
R = zeros(numel(t), numel(m));
for i = 1:numel(t)
    for j = 1:numel(m)
        R(i, j) = camberThicknessRatio([m(j), 0.516, t(i)], x);
    end
end
f2 = figure('Color', 'w', 'Position', [100 100 620 480]);
contourf(m, t, R, 20, 'LineColor', 'none'); hold on;
cb = colorbar; cb.Label.String = 'camber / thickness';
plot(0.02, 0.12, 'wo', 'MarkerSize', 9, 'LineWidth', 2);
plot(0.05, 0.08, 'wp', 'MarkerSize', 16, 'MarkerFaceColor', 'w');
text(0.0205, 0.1235, ' NACA 2412', 'Color', 'w', 'FontWeight', 'bold');
text(0.0495, 0.0835, 'optimum ', 'Color', 'w', 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
xlabel('maximum camber m'); ylabel('maximum thickness t');
title('Objective rises towards high m and low t: optimum sits on the bounds');
exportgraphics(f2, fullfile(figDir, 'objective_landscape.png'), 'Resolution', 150);

%% Morphing GIF from the analysed sequence
f3 = figure('Color', 'w', 'Position', [100 100 800 360]);
gifFile = fullfile(figDir, 'morphing.gif');
for k = 0:20
    [xs, ys] = readDat(fullfile(seqDir, sprintf('naca2412_morph_%02d.dat', k)));
    clf(f3);
    plot(xb, yb, '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 1); hold on;
    plot(xs, ys, 'b-', 'LineWidth', 2);
    axis equal; axis([0 1 -0.08 0.12]); grid on;
    xlabel('x/c'); ylabel('y/c');
    title(sprintf('Morphing NACA 2412 \\rightarrow optimised airfoil: step %d/20', k));
    drawnow;
    [im, map] = rgb2ind(frame2im(getframe(f3)), 32);
    delay = 0.12;
    if k == 0 || k == 20, delay = 1.0; end
    if k == 0
        imwrite(im, map, gifFile, 'gif', 'LoopCount', Inf, 'DelayTime', delay);
    else
        imwrite(im, map, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
    end
end
fprintf('Figures written to %s\n', figDir);

function [x, y] = readDat(file)
% Coordinates of a Selig-format .dat file (the first line is the name)
data = readmatrix(file, 'FileType', 'text', 'NumHeaderLines', 1);
x = data(:, 1);
y = data(:, 2);
end
