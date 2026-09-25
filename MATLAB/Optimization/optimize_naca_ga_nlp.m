%% Hybrid GA + NLP optimisation of the NACA 2412 section
% Method used for the project report:
%   design variables  v = [m p t]  (NACA 4-digit maximum camber, its
%                                   position, maximum thickness)
%   objective         maximise camber / thickness (geometric stand-in for
%                     lift-to-drag; no aerodynamic analysis inside the loop)
%   stage 1           genetic algorithm (global search)
%   stage 2           fmincon, interior-point (local refinement from the GA
%                     result)
% The optimised section is exported as .dat for analysis in XFLR5.
%
% The GA is stochastic, so the hybrid run is repeated with several seeds.
% Every run ends with m on its upper bound and t on its lower bound; only p
% changes, because the objective hardly depends on it.
%
% Output folder: MATLAB/output/optimization

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'NACA2412'));
outDir = fullfile(here, '..', 'output', 'optimization');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% Problem definition
x = linspace(0, 1, 100)';            % chordwise stations (same as the report run)
baseline = [0.02, 0.40, 0.12];       % NACA 2412
lb = [0.00, 0.20, 0.08];             % bounds used for the report results
ub = [0.05, 0.60, 0.15];

objective = @(v) -camberThicknessRatio(v, x);   % minimise -C/T = maximise C/T

gaOpts = optimoptions('ga', 'PopulationSize', 100, 'MaxGenerations', 100, ...
    'FunctionTolerance', 1e-4, 'Display', 'off');
nlpOpts = optimoptions('fmincon', 'Algorithm', 'interior-point', ...
    'ConstraintTolerance', 1e-6, 'StepTolerance', 1e-6, 'MaxIterations', 300, ...
    'Display', 'off');

%% GA -> fmincon, repeated with several random seeds
seeds = (1:5)';
res = zeros(numel(seeds), 4);
for k = 1:numel(seeds)
    rng(seeds(k));
    vGA = ga(objective, 3, [], [], [], [], lb, ub, [], gaOpts);
    [vNLP, fNLP] = fmincon(objective, vGA, [], [], [], [], lb, ub, [], nlpOpts);
    res(k, :) = [vNLP, -fNLP];
end
T = array2table([seeds, res], 'VariableNames', {'seed', 'm', 'p', 't', 'C_over_T'});
disp(T);
writetable(T, fullfile(outDir, 'ga_nlp_seeds.csv'));

vOpt = res(1, 1:3);
fprintf('Baseline NACA 2412 : m = %.4f  p = %.4f  t = %.4f  C/T = %.4f\n', ...
    baseline, camberThicknessRatio(baseline, x));
fprintf('Optimised (seed %d) : m = %.4f  p = %.4f  t = %.4f  C/T = %.4f\n', ...
    seeds(1), vOpt, res(1, 4));
fprintf('m at its upper bound: %d   t at its lower bound: %d\n', ...
    abs(vOpt(1) - ub(1)) < 1e-4, abs(vOpt(3) - lb(3)) < 1e-4);

%% Export for XFLR5
[xu, yu, xl, yl] = naca4(vOpt(1), vOpt(2), vOpt(3), x);
writeAirfoilDat(fullfile(outDir, 'optimized_airfoil.dat'), ...
    sprintf('Optimized m=%.3f p=%.3f t=%.3f', vOpt), xu, yu, xl, yl);
[xub, yub, xlb, ylb] = naca4(baseline(1), baseline(2), baseline(3), x);
writeAirfoilDat(fullfile(outDir, 'baseline_NACA2412.dat'), 'NACA 2412', xub, yub, xlb, ylb);
save(fullfile(outDir, 'optimization_result.mat'), 'baseline', 'vOpt', 'lb', 'ub', 'T');

%% Baseline vs optimised
figure('Color', 'w');
plot(xub, yub, 'b-', xlb, ylb, 'b-', 'LineWidth', 1.5); hold on;
plot(xu, yu, 'r--', xl, yl, 'r--', 'LineWidth', 1.5);
axis equal; grid on; xlim([0 1]);
xlabel('x/c'); ylabel('y/c');
title('Baseline NACA 2412 vs optimised airfoil');
legend('NACA 2412', '', sprintf('Optimised (m=%.3f, p=%.2f, t=%.3f)', vOpt), '', ...
    'Location', 'southeast');
