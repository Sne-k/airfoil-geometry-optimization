%% Aerodynamic optimisation with the PARSEC parameterisation (XFOIL in the loop)
% Takes the richer shape description of the project's PARSEC branch
% (9 free parameters: leading-edge radius, upper and lower crest position,
% height and curvature, trailing-edge direction and wedge angle) and
% optimises it with the same XFOIL objective and GA -> fmincon structure as
% optimize_xfoil_naca.m. The GA population is seeded with the PARSEC fit of
% NACA 2412.
%   case t08: maximum thickness 0.08..0.15 (report bounds)
%   case t12: maximum thickness 0.12..0.15 (NACA 2412 thickness or more)
%
% Output folder: MATLAB/output/optimization_xfoil

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(here, fullfile(root, 'NACA2412'), fullfile(root, 'PARSEC'), fullfile(root, 'Aerodynamics'));
outDir = fullfile(root, 'output', 'optimization_xfoil');
if ~exist(outDir, 'dir'), mkdir(outDir); end

exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end
Re = 1e6;
x = (1 - cos(linspace(0, pi, 150)')) / 2;

% q = [rle Xup Yup YXXup Xlow Ylow YXXlow alpha_te beta_te]
q0 = [0.01495 0.32556 0.07946 -0.63759 0.22209 -0.04144 0.22360 -2.81359 19.52005];  % NACA 2412 fit
lb = [0.005 0.20 0.04 -1.50 0.10 -0.08 -1.00 -15  2];
ub = [0.030 0.55 0.11 -0.10 0.60  0.03  1.50   5 30];

gaOpts = optimoptions('ga', 'PopulationSize', 40, 'MaxGenerations', 15, ...
    'FunctionTolerance', 1e-3, 'UseParallel', true, 'Display', 'iter', ...
    'InitialPopulationMatrix', q0);
nlpOpts = optimoptions('fmincon', 'Algorithm', 'sqp', 'FiniteDifferenceStepSize', 1e-2, ...
    'MaxIterations', 15, 'StepTolerance', 1e-4, 'OptimalityTolerance', 1e-3, 'UseParallel', true, 'Display', 'iter');

cases = {'t08', [0.08 0.15];
         't12', [0.12 0.15]};
results = cell(size(cases, 1), 1);
rng(1);
for c = 1:size(cases, 1)
    [tag, tRange] = cases{c, :};
    objective = @(q) -parsecMaxLD(q, x, Re, exe, tRange);
    qGA = ga(objective, 9, [], [], [], [], lb, ub, [], gaOpts);
    [qNLP, fNLP] = fmincon(objective, qGA, [], [], [], [], lb, ub, [], nlpOpts);
    if fNLP <= objective(qGA), q = qNLP; else, q = qGA; end   % XFOIL is noisy: keep the better point

    p = [q(1:7), 0, 0, q(8), q(9)];
    [yu, yl] = parsecSurfaces(p, x);
    pol = xfoilPolar(x, yu, x, yl, Re, [-2 18 0.5], exe);
    m = efficiencyMetrics(pol);
    fprintf('%s: t = %.4f  (L/D)max = %.1f at %.1f deg  CLmax = %.3f\n', ...
        tag, max(yu - yl), m.LDmax, m.alphaLD, m.CLmax);
    fprintf('   p = [%s]\n', sprintf('%.5f ', p));
    writeAirfoilDat(fullfile(outDir, ['xfoil_parsec_' tag '.dat']), ...
        sprintf('XFOIL-optimised PARSEC (%s)', tag), x, yu, x, yl);
    results{c} = struct('tag', tag, 'p', p, 'metrics', m, 'polar', pol);
end
save(fullfile(outDir, 'xfoil_parsec_results.mat'), 'results');
