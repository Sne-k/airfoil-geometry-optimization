%% Baseline NACA 2412 airfoil
% Generates the baseline section used throughout the project, plots it and
% exports it as .dat (XFLR5 / XFOIL) and .csv files.
%
% Output folder: MATLAB/output/naca2412

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
outDir = fullfile(here, '..', 'output', 'naca2412');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% Parameters
m = 0.02;                    % maximum camber (2 % chord)
p = 0.40;                    % position of maximum camber (40 % chord)
t = 0.12;                    % maximum thickness (12 % chord)
x = linspace(0, 1, 100)';    % chordwise stations (same as the report run)

%% Geometry
[xu, yu, xl, yl, yc] = naca4(m, p, t, x);

%% Export
writeAirfoilDat(fullfile(outDir, 'NACA2412.dat'), 'NACA 2412', xu, yu, xl, yl);
writematrix([flipud([xu yu]); xl(2:end) yl(2:end)], fullfile(outDir, 'NACA2412.csv'));
fprintf('NACA 2412 written to %s\n', outDir);

%% Plot
figure('Color', 'w');
plot(xu, yu, 'b-', xl, yl, 'r-', x, yc, 'k--', 'LineWidth', 1.5);
axis equal; grid on; xlim([0 1]);
xlabel('x/c'); ylabel('y/c');
title('NACA 2412 baseline airfoil');
legend('Upper surface', 'Lower surface', 'Camber line', 'Location', 'southeast');
