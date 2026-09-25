%% PARSEC representation of the NACA 2412 baseline
% Fits the PARSEC parameters to the NACA 2412 section by least squares
% (trailing-edge height and thickness fixed at zero), plots both shapes and
% exports the PARSEC airfoil. The fitted vector is the starting individual
% of the PARSEC genetic algorithm (Optimization/run_parsec_ga.m).
%
% Output folder: MATLAB/output/parsec

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'NACA2412'));
outDir = fullfile(here, '..', 'output', 'parsec');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% Target: NACA 2412 (cosine-spaced stations)
x = (1 - cos(linspace(0, pi, 100)')) / 2;
[xu, yu, xl, yl] = naca4(0.02, 0.40, 0.12, x);

%% Least-squares fit
% q = [rle Xup Yup YXXup Xlow Ylow YXXlow alpha_te beta_te]
toP = @(q) [q(1:7), 0, 0, q(8), q(9)];
q0  = [0.0216 0.3445 0.0791 -0.6448 0.17 -0.0338 0.6748 0 0];
lbq = [0.005 0.20 0.04 -1.5 0.05 -0.08 0.05 -15  0];
ubq = [0.030 0.50 0.10 -0.1 0.40 -0.01 1.50  15 30];
opts = optimoptions('lsqnonlin', 'Display', 'off');
q = lsqnonlin(@(q) parsecResidual(toP(q), xu, yu, xl, yl), q0, lbq, ubq, opts);
p = toP(q);

err = parsecResidual(p, xu, yu, xl, yl);
names = {'rle', 'Xup', 'Yup', 'YXXup', 'Xlow', 'Ylow', 'YXXlow', 'yte', 'dyte', 'alpha_te', 'beta_te'};
fprintf('PARSEC fit of NACA 2412 (max |error| = %.2e c):\n', max(abs(err)));
for k = 1:numel(p)
    fprintf('  %-9s = %9.5f\n', names{k}, p(k));
end

save(fullfile(outDir, 'parsec_naca2412.mat'), 'p');
exportAirfoilDat(p, fullfile(outDir, 'parsec_naca2412.dat'), 'PARSEC fit of NACA 2412');

%% Plot
e = (1:6) - 0.5;
a = parsec(p);
xs = (1 - cos(linspace(0, pi, 200)')) / 2;
figure('Color', 'w');
plot(xu, yu, 'k-', xl, yl, 'k-', 'LineWidth', 2); hold on;
plot(xs, (xs.^e) * a(1:6), 'r--', xs, (xs.^e) * a(7:12), 'r--', 'LineWidth', 1.5);
axis equal; grid on; xlim([0 1]);
xlabel('x/c'); ylabel('y/c');
title('NACA 2412 and its PARSEC fit');
legend('NACA 2412', '', 'PARSEC fit', 'Location', 'southeast');

function r = parsecResidual(p, xu, yu, xl, yl)
% Vertical distance between the PARSEC surfaces and the target coordinates
e = (1:6) - 0.5;
a = parsec(p);
r = [(max(xu, 0).^e) * a(1:6) - yu; (max(xl, 0).^e) * a(7:12) - yl];
end
