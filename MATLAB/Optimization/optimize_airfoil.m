function result = optimize_airfoil(airfoil, varargin)
%OPTIMIZE_AIRFOIL  Makes any airfoil more aerodynamically efficient.
%   result = OPTIMIZE_AIRFOIL(airfoil) takes an airfoil ('NACA 2412', '4415'
%   or a Selig/Lednicer .dat file), fits it with a CST parameterisation and
%   runs a hybrid genetic algorithm -> fmincon search with XFOIL in the loop
%   to maximise its efficiency. By default the result keeps at least the
%   original maximum thickness (the structure is not weakened) and a
%   pitching moment within 0.05 of the original. The optimised .dat file,
%   the polars, a before/after table and figures are written to OutputDir.
%
%   Options (name, value):
%     'Re'            Reynolds number                            (1e6)
%     'Objective'     'LDmax' | 'endurance' (CL^1.5/CD) | 'LDatCL'  ('LDmax')
%     'DesignCL'      lift coefficient used by 'LDatCL'          (0.5)
%     'MinThickness'  minimum t/c as a fraction of the original  (1.0)
%     'CmIncrease'    allowed increase of |CM| at alpha = 0      (0.05)
%     'Order'         CST order per surface (Order+1 coefficients) (6)
%     'MaxChange'     bound on the change of each CST coefficient (0.08)
%     'Population'    GA population size                         (50)
%     'Generations'   GA generations                             (25)
%     'NLPIterations' fmincon iterations                         (15)
%     'UseParallel'   parallel evaluation (Parallel Computing Toolbox) (true)
%     'OutputDir'     output folder     (MATLAB/output/optimize_airfoil/<name>)
%
%   Example:
%       r = optimize_airfoil('NACA 2412');
%       r = optimize_airfoil('myfoil.dat', 'Re', 5e5, 'Objective', 'endurance');
%
%   Requires XFOIL (see Aerodynamics/xfoilPolar.m), the Optimization Toolbox
%   and the Global Optimization Toolbox.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(here, fullfile(root, 'NACA2412'), fullfile(root, 'Aerodynamics'));

ip = inputParser;
ip.addParameter('Re', 1e6);
ip.addParameter('Objective', 'LDmax');
ip.addParameter('DesignCL', 0.5);
ip.addParameter('MinThickness', 1.0);
ip.addParameter('CmIncrease', 0.05);
ip.addParameter('Order', 6);
ip.addParameter('MaxChange', 0.08);
ip.addParameter('Population', 50);
ip.addParameter('Generations', 25);
ip.addParameter('NLPIterations', 15);
ip.addParameter('UseParallel', true);
ip.addParameter('OutputDir', '');
ip.parse(varargin{:});
o = ip.Results;

exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end

%% Input airfoil and its performance
[xu0, yu0, xl0, yl0, name] = readAirfoil(airfoil);
tag = regexprep(strtrim(name), '[^\w]+', '_');
if isempty(o.OutputDir), o.OutputDir = fullfile(root, 'output', 'optimize_airfoil', tag); end
if ~exist(o.OutputDir, 'dir'), mkdir(o.OutputDir); end

polBase = xfoilPolar(xu0, yu0, xl0, yl0, o.Re, [-2 18 0.5], exe);
if isempty(polBase.alpha)
    error('optimize_airfoil:xfoil', 'XFOIL could not analyse %s.', name);
end
mBase = efficiencyMetrics(polBase);

%% CST representation
n1 = o.Order + 1;
[Au, Al, dte] = cstFit(xu0, yu0, xl0, yl0, o.Order);
fitErr = max(abs([cstBasis(xu0, o.Order)*Au.' + xu0*dte/2 - yu0; ...
                  cstBasis(xl0, o.Order)*Al.' - xl0*dte/2 - yl0]));
x = (1 - cos(linspace(0, pi, 150)')) / 2;
[yuF, ylF] = cstSurfaces(Au, Al, dte, x);
tFit = max(yuF - ylF);

S.Au = Au; S.Al = Al; S.dte = dte; S.x = x; S.Re = o.Re; S.exe = exe;
S.alphaRange = [-2 12 0.5];
S.tMin = o.MinThickness * tFit - 1e-4;
S.tMax = max(0.25, 1.5 * tFit);
S.cmMax = Inf;
if ~isnan(mBase.CM0), S.cmMax = abs(mBase.CM0) + o.CmIncrease; end
S.objective = o.Objective;
S.designCL = o.DesignCL;

objective = @(d) airfoilObjective(d, S);
nv = 2 * n1;
lb = -o.MaxChange * ones(1, nv);
ub = o.MaxChange * ones(1, nv);
fStart = objective(zeros(1, nv));
fprintf('%s: CST fit error %.1e c, %s of the fitted original = %.2f\n', ...
    name, fitErr, o.Objective, -fStart);

%% Hybrid optimisation: GA (global) -> fmincon (local)
rng(1);
gaOpts = optimoptions('ga', 'PopulationSize', o.Population, 'MaxGenerations', o.Generations, ...
    'FunctionTolerance', 1e-3, 'UseParallel', o.UseParallel, 'Display', 'iter', ...
    'InitialPopulationMatrix', zeros(1, nv));
dGA = ga(objective, nv, [], [], [], [], lb, ub, [], gaOpts);
fGA = objective(dGA);
nlpOpts = optimoptions('fmincon', 'Algorithm', 'sqp', 'FiniteDifferenceStepSize', 1e-2, ...
    'MaxIterations', o.NLPIterations, 'StepTolerance', 1e-4, 'OptimalityTolerance', 1e-3, ...
    'UseParallel', o.UseParallel, 'Display', 'iter');
[dNLP, fNLP] = fmincon(objective, dGA, [], [], [], [], lb, ub, [], nlpOpts);
if fNLP <= fGA, d = dNLP; else, d = dGA; end            % XFOIL is noisy: keep the better point
if min(fNLP, fGA) >= fStart
    warning('optimize_airfoil:noGain', 'No improvement found; returning the fitted original.');
    d = zeros(1, nv);
end

%% Optimised airfoil
AuOpt = Au + d(1:n1);
AlOpt = Al + d(n1+1:end);
[yu, yl] = cstSurfaces(AuOpt, AlOpt, dte, x);
polOpt = xfoilPolar(x, yu, x, yl, o.Re, [-2 18 0.5], exe);
mOpt = efficiencyMetrics(polOpt);

writeAirfoilDat(fullfile(o.OutputDir, [tag '_optimized.dat']), [name ' optimized'], x, yu, x, yl);
writetable(struct2table(polBase), fullfile(o.OutputDir, 'polar_original.csv'));
writetable(struct2table(polOpt), fullfile(o.OutputDir, 'polar_optimized.csv'));

rows = {'max CL/CD'; 'alpha at max CL/CD (deg)'; 'max CL^1.5/CD'; 'CL max'; ...
        'alpha at CL max (deg)'; 'CD min'; 'CM at alpha = 0'; 't/c max'};
vb = [mBase.LDmax; mBase.alphaLD; mBase.E15max; mBase.CLmax; mBase.alphaStall; ...
      mBase.CDmin; mBase.CM0; maxThickness(xu0, yu0, xl0, yl0)];
vo = [mOpt.LDmax; mOpt.alphaLD; mOpt.E15max; mOpt.CLmax; mOpt.alphaStall; ...
      mOpt.CDmin; mOpt.CM0; max(yu - yl)];
summary = table(rows, vb, vo, 100*(vo - vb)./abs(vb), ...
    'VariableNames', {'Quantity', 'Original', 'Optimized', 'Change_percent'});
writetable(summary, fullfile(o.OutputDir, 'summary.csv'));
fprintf('\n%s at Re = %.3g (XFOIL, Ncrit 9):\n', name, o.Re);
disp(summary);

%% Figures
f = figure('Color', 'w', 'Position', [100 100 1000 700]);
subplot(2, 2, [1 2]);
plot(xu0, yu0, 'k-', xl0, yl0, 'k-', 'LineWidth', 1.5); hold on;
plot(x, yu, 'r-', x, yl, 'r-', 'LineWidth', 1.5);
axis equal; grid on; xlim([0 1]);
title(sprintf('%s (black) and optimised (red)', name), 'Interpreter', 'none');
subplot(2, 2, 3);
plot(polBase.alpha, polBase.CL ./ polBase.CD, 'k-', polOpt.alpha, polOpt.CL ./ polOpt.CD, 'r-', 'LineWidth', 1.5);
grid on; xlabel('\alpha (deg)'); ylabel('C_L/C_D'); legend('original', 'optimised', 'Location', 'best');
subplot(2, 2, 4);
plot(polBase.alpha, polBase.CL, 'k-', polOpt.alpha, polOpt.CL, 'r-', 'LineWidth', 1.5);
grid on; xlabel('\alpha (deg)'); ylabel('C_L'); legend('original', 'optimised', 'Location', 'best');
exportgraphics(f, fullfile(o.OutputDir, 'comparison.png'), 'Resolution', 130);

result = struct('name', name, 'options', o, 'fitError', fitErr, 'Au', Au, 'Al', Al, ...
    'AuOpt', AuOpt, 'AlOpt', AlOpt, 'dte', dte, 'x', x, 'yu', yu, 'yl', yl, ...
    'original', mBase, 'optimized', mOpt, 'polarOriginal', polBase, 'polarOptimized', polOpt, ...
    'summary', summary, 'outputDir', o.OutputDir);
save(fullfile(o.OutputDir, 'result.mat'), 'result');
end

function t = maxThickness(xu, yu, xl, yl)
% Maximum thickness of the input airfoil on a common grid
xs = linspace(0.01, 0.99, 400)';
iu = xu > 0.005; il = xl > 0.005;
t = max(interp1(xu(iu), yu(iu), xs, 'pchip') - interp1(xl(il), yl(il), xs, 'pchip'));
end
