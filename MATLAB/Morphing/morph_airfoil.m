%% Geometric morphing from the NACA 2412 baseline to the optimised airfoil
% Linearly interpolates [m p t] between the baseline and the optimised
% section in nSteps steps, writes one XFLR5 .dat file per step and records
% the sequence as AVI and GIF. This is a shape interpolation only: no
% mechanism, skin, structure or actuation is modelled.
%
% Uses MATLAB/output/optimization/optimization_result.mat if the
% optimisation has been run, otherwise the airfoil analysed in the report.
%
% Output folder: MATLAB/output/morphing

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'NACA2412'));
outDir = fullfile(here, '..', 'output', 'morphing');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% Start and end shapes
baseline = [0.02, 0.40, 0.12];                  % NACA 2412
resultFile = fullfile(here, '..', 'output', 'optimization', 'optimization_result.mat');
if isfile(resultFile)
    S = load(resultFile);
    target = S.vOpt;
    fprintf('Target from %s\n', resultFile);
else
    target = [0.0500, 0.5158, 0.0800];          % airfoil analysed in the report
    fprintf('No optimisation result found, using the airfoil from the report.\n');
end

nSteps = 20;
x = linspace(0, 1, 100)';

%% Morphing loop
fig = figure('Color', 'w', 'Position', [100 100 800 400]);
video = VideoWriter(fullfile(outDir, 'naca2412_morphing.avi'));
video.FrameRate = 10;
open(video);
gifFile = fullfile(outDir, 'naca2412_morphing.gif');

[xb_u, yb_u, xb_l, yb_l] = naca4(baseline(1), baseline(2), baseline(3), x);

for k = 0:nSteps
    f = k / nSteps;
    v = (1 - f)*baseline + f*target;
    [xu, yu, xl, yl, yc] = naca4(v(1), v(2), v(3), x);

    writeAirfoilDat(fullfile(outDir, sprintf('naca2412_morph_%02d.dat', k)), ...
        sprintf('NACA2412 Morph Step %d', k), xu, yu, xl, yl);

    clf(fig);
    plot(xb_u, yb_u, '-', xb_l, yb_l, '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 1); hold on;
    plot(xu, yu, 'b-', xl, yl, 'r-', 'LineWidth', 1.8);
    plot(x, yc, 'k--', 'LineWidth', 1);
    axis equal; axis([0 1 -0.12 0.14]); grid on;
    xlabel('x/c'); ylabel('y/c');
    title(sprintf('Step %d/%d   m = %.3f   p = %.2f   t = %.3f', k, nSteps, v));
    legend('NACA 2412 (start)', '', 'Upper surface', 'Lower surface', 'Camber line', ...
        'Location', 'southeast');
    drawnow;

    frame = getframe(fig);
    writeVideo(video, frame);
    [im, map] = rgb2ind(frame2im(frame), 64);
    delay = 0.12;
    if k == 0 || k == nSteps, delay = 1.0; end
    if k == 0
        imwrite(im, map, gifFile, 'gif', 'LoopCount', Inf, 'DelayTime', delay);
    else
        imwrite(im, map, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
    end
end
close(video);
fprintf('Wrote %d .dat files, %s and %s\n', nSteps + 1, 'naca2412_morphing.avi', 'naca2412_morphing.gif');
