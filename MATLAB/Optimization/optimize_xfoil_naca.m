%% Aerodynamic GA + NLP optimisation of the NACA section (XFOIL in the loop)
% Improved version of the report method: same design variables [m p t],
% same GA -> fmincon structure, but the objective is the maximum
% lift-to-drag ratio computed by XFOIL (Re = 1e6, alpha -2..12 deg)
% instead of the camber/thickness ratio.
%   case t08: report bounds (t >= 0.08)
%   case t12: keeps at least the NACA 2412 thickness (t >= 0.12), so the
%             wing structure is not weakened
% Requires XFOIL (see Aerodynamics/xfoilPolar.m) and the Parallel
% Computing Toolbox for the parallel GA (set UseParallel to false without it).
%
% Output folder: MATLAB/output/optimization_xfoil

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(here, fullfile(root, 'NACA2412'), fullfile(root, 'Aerodynamics'));
outDir = fullfile(root, 'output', 'optimization_xfoil');
if ~exist(outDir, 'dir'), mkdir(outDir); end

exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end
Re = 1e6;
x = (1 - cos(linspace(0, pi, 150)')) / 2;       % 150 cosine-spaced stations per surface

objective = @(v) -nacaMaxLD(v, x, Re, exe);
gaOpts = optimoptions('ga', 'PopulationSize', 24, 'MaxGenerations', 15, ...
    'FunctionTolerance', 1e-3, 'UseParallel', true, 'Display', 'iter');
nlpOpts = optimoptions('fmincon', 'Algorithm', 'sqp', 'FiniteDifferenceStepSize', 1e-2, ...
    'MaxIterations', 15, 'StepTolerance', 1e-4, 'OptimalityTolerance', 1e-3, 'UseParallel', true, 'Display', 'iter');

cases = {'t08', [0.00 0.20 0.08], [0.05 0.60 0.15];
         't12', [0.00 0.20 0.12], [0.05 0.60 0.15]};
results = cell(size(cases, 1), 1);
rng(1);
for c = 1:size(cases, 1)
    [tag, lb, ub] = cases{c, :};
    vGA = ga(objective, 3, [], [], [], [], lb, ub, [], gaOpts);
    [vNLP, fNLP] = fmincon(objective, vGA, [], [], [], [], lb, ub, [], nlpOpts);
    if fNLP <= objective(vGA), v = vNLP; else, v = vGA; end   % XFOIL is noisy: keep the better point

    [xu, yu, xl, yl] = naca4(v(1), v(2), v(3), x);
    pol = xfoilPolar(xu, yu, xl, yl, Re, [-2 18 0.5], exe);
    m = efficiencyMetrics(pol);
    fprintf('%s: m = %.4f  p = %.4f  t = %.4f  (L/D)max = %.1f at %.1f deg  CLmax = %.3f\n', ...
        tag, v, m.LDmax, m.alphaLD, m.CLmax);
    writeAirfoilDat(fullfile(outDir, ['xfoil_naca_' tag '.dat']), ...
        sprintf('XFOIL-optimised NACA m=%.3f p=%.3f t=%.3f', v), xu, yu, xl, yl);
    results{c} = struct('tag', tag, 'v', v, 'vGA', vGA, 'metrics', m, 'polar', pol);
end
save(fullfile(outDir, 'xfoil_naca_results.mat'), 'results');
