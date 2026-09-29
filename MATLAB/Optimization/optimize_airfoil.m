function result = optimize_airfoil(airfoil, varargin)
%OPTIMIZE_AIRFOIL  Makes any airfoil more aerodynamically efficient.
%   result = OPTIMIZE_AIRFOIL(airfoil) takes an airfoil ('NACA 2412', '4415'
%   or a Selig/Lednicer .dat file), fits it with a CST parameterisation and
%   runs a hybrid search with XFOIL in the loop to maximise its efficiency:
%   a genetic algorithm followed by fmincon (default), a particle swarm
%   followed by pattern search, or Bayesian optimisation followed by
%   fmincon. By default the result keeps at least the original maximum
%   thickness (the structure is not weakened), a pitching moment within 0.05
%   of the original, and a surface at least as smooth as the original: no
%   additional curvature reversals and no larger trailing-edge curvature
%   (curvatureLimits, following Xoptfoil2). Every candidate is analysed with
%   two XFOIL panellings and scored by the lower result, so the search
%   cannot exploit numerical artefacts. The optimised .dat file, the polars,
%   a before/after table, every evaluation of the search, the run settings
%   and figures are written to OutputDir.
%
%   Options (name, value):
%     'Re'            Reynolds number                            (1e6)
%     'Objective'     'LDmax' | 'endurance' (CL^1.5/CD) | 'LDatCL'  ('LDmax')
%     'DesignCL'      lift coefficient(s) used by 'LDatCL'       (0.5)
%     'Weights'       weights of several design lift coefficients (equal)
%     'MinThickness'  minimum t/c as a fraction of the original  (1.0)
%     'CmIncrease'    allowed increase of |CM| at alpha = 0      (0.05)
%     'KeepCLmax'     do not let the maximum lift drop           (false)
%     'Curvature'     apply the curvature limits                 (true)
%     'CurvatureThreshold'  curvature below which reversals are not
%                     counted                                    (0.01)
%     'Algorithm'     'ga' (GA -> fmincon) | 'pso' (particle swarm ->
%                     pattern search) | 'bayesopt' (Bayesian optimisation
%                     -> fmincon)                                ('ga')
%     'LocalSearch'   refine the global result locally           (true)
%     'Seed'          random number seed                          (1)
%     'Order'         CST order per surface (Order+1 coefficients) (6)
%     'MaxChange'     bound on the change of each CST coefficient (0.08)
%     'Population'    GA population / swarm size                 (50)
%     'Generations'   GA generations / swarm iterations. Bayesian
%                     optimisation gets the same number of evaluations,
%                     Population*(Generations+1)                  (25)
%     'NLPIterations' fmincon iterations (pattern search: 20 evaluations
%                     per variable)                              (15)
%     'UseParallel'   parallel evaluation (Parallel Computing Toolbox) (true)
%     'OutputDir'     output folder     (MATLAB/output/optimize_airfoil/<name>)
%
%   Example:
%       r = optimize_airfoil('NACA 2412');
%       r = optimize_airfoil('myfoil.dat', 'Re', 5e5, 'Objective', 'endurance');
%       r = optimize_airfoil('NACA 2412', 'Objective', 'LDatCL', ...
%                            'DesignCL', [0.4 1.0], 'Weights', [0.2 0.8]);
%
%   Requires XFOIL (see Aerodynamics/xfoilPolar.m), the Optimization Toolbox
%   and the Global Optimization Toolbox ('bayesopt': Statistics and Machine
%   Learning Toolbox).

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(here, fullfile(root, 'NACA2412'), fullfile(root, 'Aerodynamics'));
clock0 = tic;
started = datetime('now');

ip = inputParser;
ip.addParameter('Re', 1e6);
ip.addParameter('Objective', 'LDmax');
ip.addParameter('DesignCL', 0.5);
ip.addParameter('Weights', []);
ip.addParameter('MinThickness', 1.0);
ip.addParameter('CmIncrease', 0.05);
ip.addParameter('KeepCLmax', false);
ip.addParameter('Curvature', true);
ip.addParameter('CurvatureThreshold', 0.01);
ip.addParameter('Algorithm', 'ga');
ip.addParameter('LocalSearch', true);
ip.addParameter('Seed', 1);
ip.addParameter('Order', 6);
ip.addParameter('MaxChange', 0.08);
ip.addParameter('Population', 50);
ip.addParameter('Generations', 25);
ip.addParameter('NLPIterations', 15);
ip.addParameter('UseParallel', true);
ip.addParameter('OutputDir', '');
ip.parse(varargin{:});
o = ip.Results;
o.Algorithm = lower(o.Algorithm);
if ~any(strcmp(o.Algorithm, {'ga', 'pso', 'bayesopt'}))
    error('optimize_airfoil:algorithm', 'Unknown algorithm ''%s''.', o.Algorithm);
end

exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end

%% Input airfoil and its performance
[xu0, yu0, xl0, yl0, name] = readAirfoil(airfoil);
tag = regexprep(strtrim(name), '[^\w]+', '_');
if isempty(o.OutputDir), o.OutputDir = fullfile(root, 'output', 'optimize_airfoil', tag); end
if ~exist(o.OutputDir, 'dir'), mkdir(o.OutputDir); end
historyDir = fullfile(o.OutputDir, 'history');
if exist(historyDir, 'dir')
    delete(fullfile(historyDir, 'eval_*.csv'));
else
    mkdir(historyDir);
end

polBase = xfoilPolar(xu0, yu0, xl0, yl0, o.Re, [-2 18 0.5], exe);
if isempty(polBase.alpha)
    error('optimize_airfoil:xfoil', 'XFOIL could not analyse %s.', name);
end
mBase = efficiencyMetrics(polBase);

%% CST representation
n1 = o.Order + 1;
[Au, Al, dte] = cstFit(xu0, yu0, xl0, yl0, o.Order);
iu = xu0 >= 0;  il = xl0 >= 0;          % cambered NACA noses reach slightly ahead of x = 0
fitErr = max(abs([cstBasis(xu0(iu), o.Order)*Au.' + xu0(iu)*dte/2 - yu0(iu); ...
                  cstBasis(xl0(il), o.Order)*Al.' - xl0(il)*dte/2 - yl0(il)]));
x = (1 - cos(linspace(0, pi, 150)')) / 2;
[yuF, ylF] = cstSurfaces(Au, Al, dte, x);
tFit = max(yuF - ylF);

S.Au = Au; S.Al = Al; S.dte = dte; S.x = x; S.Re = o.Re; S.exe = exe;
S.alphaRange = [-2 12 0.5];
S.tMin = o.MinThickness * tFit - 1e-4;
S.tMax = max(0.25, 1.5 * tFit);
S.cmMax = Inf;
if ~isnan(mBase.CM0)
    S.cmMax = abs(mBase.CM0) + o.CmIncrease;
else
    warning('optimize_airfoil:noCM0', ...
        'XFOIL gave no pitching moment around alpha = 0; the pitching-moment limit is not applied.');
end
S.objective = o.Objective;
S.designCL = o.DesignCL;
S.weights = o.Weights;
S.clMaxMin = -Inf;
S.checkAbove = 0;
S.failValue = 0;
% Curvature of the fitted original: limits for the search, or (without
% limits) only a reference for the report
curvRef = curvatureLimits(Au, Al, dte, o.CurvatureThreshold);
S.curv = [];
if o.Curvature, S.curv = curvRef; end
S.curvReject = o.Curvature;
S.historyDir = historyDir;
S.stage = 'start';
if o.KeepCLmax
    % The sweep must reach stall; the limit comes from the fitted original,
    % analysed like the candidates
    S.alphaRange = [-2 18 0.5];
    p1 = xfoilPolar(x, yuF, x, ylF, o.Re, S.alphaRange, exe, [], false);
    p2 = xfoilPolar(x, yuF, x, ylF, o.Re, S.alphaRange, exe, 200, false);
    if ~isempty(p1.CL) && ~isempty(p2.CL)
        S.clMaxMin = 0.99 * min(max(p1.CL), max(p2.CL));
    end
end

nv = 2 * n1;
lb = -o.MaxChange * ones(1, nv);
ub = o.MaxChange * ones(1, nv);
fStart = airfoilObjective(zeros(1, nv), S);
fprintf('%s: CST fit error %.1e c, %s of the fitted original = %.2f\n', ...
    name, fitErr, o.Objective, -fStart);
fprintf('Curvature of the fitted original: %d/%d reversals (upper/lower), trailing-edge curvature %.2f/%.2f', ...
    curvRef.reversalsTop, curvRef.reversalsBot, curvRef.teTop, curvRef.teBot);
if o.Curvature, fprintf(' (limits applied)\n'); else, fprintf(' (no limits)\n'); end
S.checkAbove = -fStart;             % below this, one panelling is enough
isValid = @(d) designViolation(d, S, o.Curvature) == 0;

%% Hybrid optimisation: global search, then local refinement
rng(o.Seed);
% Start from the fitted original and random designs that meet the
% geometric limits (with curvature limits, only ~0.1 % of the box does)
X0 = [zeros(1, nv); feasibleSamples(o.Population - 1, lb, ub, isValid)];
S.stage = 'global';
objective = @(d) airfoilObjective(d, S);
switch o.Algorithm
    case 'pso'
        psoOpts = optimoptions('particleswarm', 'SwarmSize', o.Population, 'MaxIterations', o.Generations, ...
            'FunctionTolerance', 1e-3, 'UseParallel', o.UseParallel, 'Display', 'iter', ...
            'InitialSwarmMatrix', X0);
        [dG, ~, flagG, outG] = particleswarm(objective, nv, lb, ub, psoOpts);
    case 'bayesopt'
        names = arrayfun(@(i) sprintf('d%d', i), 1:nv, 'UniformOutput', false);
        vars = optimizableVariable(names{1}, [lb(1) ub(1)]);
        for i = 2:nv, vars(i) = optimizableVariable(names{i}, [lb(i) ub(i)]); end
        Sb = S;  Sb.failValue = NaN;                 % failed analyses are modelled as errors
        fun = @(T) airfoilObjective(table2array(T), Sb);
        xcon = @(T) validRows(table2array(T), isValid);
        nInit = min(size(X0, 1), 20);
        res = bayesopt(fun, vars, 'MaxObjectiveEvaluations', o.Population * (o.Generations + 1), ...
            'AcquisitionFunctionName', 'expected-improvement-plus', 'XConstraintFcn', xcon, ...
            'InitialX', array2table(X0(1:nInit, :), 'VariableNames', names), ...
            'UseParallel', o.UseParallel, 'PlotFcn', [], 'Verbose', 1);
        dG = table2array(res.XAtMinObjective);
        flagG = NaN;
        outG = struct('funccount', res.NumObjectiveEvaluations, 'elapsedSeconds', res.TotalElapsedTime);
    otherwise
        % Genetic algorithm -> fmincon, the method of the project report
        gaOpts = optimoptions('ga', 'PopulationSize', o.Population, 'MaxGenerations', o.Generations, ...
            'FunctionTolerance', 1e-3, 'UseParallel', o.UseParallel, 'Display', 'iter', ...
            'InitialPopulationMatrix', X0);
        [dG, ~, flagG, outG] = ga(objective, nv, [], [], [], [], lb, ub, [], gaOpts);
end
S.stage = 'check';
fG = airfoilObjective(dG, S);
dL = dG;  fL = fG;  flagL = NaN;  outL = struct();
if o.LocalSearch
    S.stage = 'local';
    if strcmp(o.Algorithm, 'pso')
        % Pattern search needs no gradients, which suits the noisy XFOIL
        % results; designs outside the limits are simply not accepted
        psOpts = optimoptions('patternsearch', 'MaxFunctionEvaluations', 20*nv, 'InitialMeshSize', 0.02, ...
            'MeshTolerance', 1e-3, 'UseCompletePoll', true, 'UseParallel', o.UseParallel, 'Display', 'iter');
        [dL, ~, flagL, outL] = patternsearch(@(d) airfoilObjective(d, S), dG, [], [], [], [], lb, ub, [], psOpts);
    else
        % fmincon takes the curvature limits as nonlinear constraints, so the
        % objective must not jump at their boundary. Its first quasi-Newton
        % step would otherwise cross the whole search box, so it works in a
        % region of +-25 % of the box around the global result.
        Sl = S;  Sl.curvReject = false;
        nonlcon = [];
        if o.Curvature, nonlcon = @(d) curvatureConstraint(d, S); end
        r = 0.25 * o.MaxChange;
        lbL = max(lb, dG - r);
        ubL = min(ub, dG + r);
        nlpOpts = optimoptions('fmincon', 'Algorithm', 'sqp', 'FiniteDifferenceStepSize', 1e-2, ...
            'MaxIterations', o.NLPIterations, 'StepTolerance', 1e-4, 'OptimalityTolerance', 1e-3, ...
            'UseParallel', o.UseParallel, 'Display', 'iter');
        [dL, ~, flagL, outL] = fmincon(@(d) airfoilObjective(d, Sl), dG, [], [], [], [], lbL, ubL, nonlcon, nlpOpts);
    end
    S.stage = 'check';
    fL = airfoilObjective(dL, S);            % all limits: positive if dL breaks one
    if fL > 0 && isfield(outL, 'bestfeasible') && ~isempty(outL.bestfeasible)
        dL = outL.bestfeasible.x;            % fmincon ended outside the limits
        fL = airfoilObjective(dL, S);
    end
end
if fL <= fG, d = dL; else, d = dG; end       % XFOIL is noisy: keep the better point
if min(fL, fG) >= fStart
    warning('optimize_airfoil:noGain', 'No improvement found; returning the fitted original.');
    d = zeros(1, nv);
end
S.stage = 'final';
fOpt = airfoilObjective(d, S);

%% Optimised airfoil
AuOpt = Au + d(1:n1);
AlOpt = Al + d(n1+1:end);
[yu, yl] = cstSurfaces(AuOpt, AlOpt, dte, x);
polOpt = xfoilPolar(x, yu, x, yl, o.Re, [-2 18 0.5], exe);
mOpt = efficiencyMetrics(polOpt);
[vCurv, cOpt] = curvatureViolation(AuOpt, AlOpt, dte, curvRef);
[~, cFit] = curvatureViolation(Au, Al, dte, curvRef);

writeAirfoilDat(fullfile(o.OutputDir, [tag '_optimized.dat']), [name ' optimized'], x, yu, x, yl);
writetable(struct2table(polBase), fullfile(o.OutputDir, 'polar_original.csv'));
writetable(struct2table(polOpt), fullfile(o.OutputDir, 'polar_optimized.csv'));

rows = {'max CL/CD'; 'alpha at max CL/CD (deg)'; 'max CL^1.5/CD'; 'CL max'; ...
        'alpha at CL max (deg)'; 'CD min'; 'CM at alpha = 0'; 't/c max'; ...
        sprintf('objective %s, lower of 160/200 panels', o.Objective); ...
        'curvature reversals, upper surface'; 'curvature reversals, lower surface'; ...
        'trailing-edge curvature, upper surface'; 'trailing-edge curvature, lower surface'};
vb = [mBase.LDmax; mBase.alphaLD; mBase.E15max; mBase.CLmax; mBase.alphaStall; ...
      mBase.CDmin; mBase.CM0; maxThickness(xu0, yu0, xl0, yl0); -fStart; ...
      cFit.reversalsTop; cFit.reversalsBot; cFit.teCurvTop; cFit.teCurvBot];
vo = [mOpt.LDmax; mOpt.alphaLD; mOpt.E15max; mOpt.CLmax; mOpt.alphaStall; ...
      mOpt.CDmin; mOpt.CM0; max(yu - yl); -fOpt; ...
      cOpt.reversalsTop; cOpt.reversalsBot; cOpt.teCurvTop; cOpt.teCurvBot];
change = 100*(vo - vb)./abs(vb);
change(abs(vb) < 1e-3) = NaN;                            % no percentage of a value near 0
change(end-3:end) = NaN;                                 % curvature: compare the values
summary = table(rows, vb, vo, change, ...
    'VariableNames', {'Quantity', 'Original', 'Optimized', 'Change_percent'});
writetable(summary, fullfile(o.OutputDir, 'summary.csv'));
fprintf('\n%s at Re = %.3g (XFOIL, Ncrit 9):\n', name, o.Re);
fprintf('(the curvature rows compare the CST fit of the original with the design)\n');
disp(summary);

%% Evaluation history and run information
H = readHistory(historyDir);
writetable(H, fullfile(o.OutputDir, 'history.csv'));
info.airfoil = name;
info.started = char(started, 'yyyy-MM-dd HH:mm:ss');
info.runTimeSeconds = round(toc(clock0));
info.matlab = version;
info.computer = computer;
pool = gcp('nocreate');
info.parallelWorkers = 0;
if ~isempty(pool), info.parallelWorkers = pool.NumWorkers; end
info.xfoil = describeFile(exe);
info.gitCommit = gitDescribe(root);
info.options = o;
info.cstFitError = fitErr;
info.limits = struct('tMin', S.tMin, 'tMax', S.tMax, 'cmMax', S.cmMax, 'clMaxMin', S.clMaxMin, ...
    'curvatureApplied', o.Curvature, 'curvatureThreshold', curvRef.threshold, ...
    'reversalsTop', curvRef.reversalsTop, 'reversalsBot', curvRef.reversalsBot, ...
    'teCurvatureTop', curvRef.teTop, 'teCurvatureBot', curvRef.teBot, ...
    'teCurvatureTolerance', curvRef.teTolerance);
info.objectiveOriginalFit = -fStart;
info.objectiveGlobal = -fG;
info.objectiveLocal = -fL;
info.objectiveFinal = -fOpt;
info.designMeetsCurvatureLimits = all(vCurv == 0);
info.evaluations = height(H);
info.xfoilAnalysedDesigns = sum(H.xfoil_analyses > 0);
info.globalExitFlag = flagG;
info.globalOutput = cleanOutput(outG);
info.localExitFlag = flagL;
info.localOutput = cleanOutput(outL);
fid = fopen(fullfile(o.OutputDir, 'run_info.json'), 'w');
fprintf(fid, '%s\n', jsonencode(info, 'PrettyPrint', true));
fclose(fid);

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

f2 = figure('Color', 'w', 'Position', [100 100 1000 420]);
sides = {'upper', 'lower'};
coefs = {{Au, AuOpt}, {Al, AlOpt}};
for s = 1:2
    subplot(1, 2, s);
    plot(curvRef.x, cstCurvature(coefs{s}{1}, dte, curvRef.basis, sides{s}), 'k-', ...
         curvRef.x, cstCurvature(coefs{s}{2}, dte, curvRef.basis, sides{s}), 'r-', 'LineWidth', 1.5);
    hold on;
    yline([-1 1] * curvRef.threshold, 'b:');
    grid on; xlabel('x/c'); ylabel('curvature (convex > 0)');
    title(sprintf('%s surface', sides{s}));
    legend('original (CST fit)', 'optimised', 'reversal threshold', 'Location', 'best');
end
exportgraphics(f2, fullfile(o.OutputDir, 'curvature.png'), 'Resolution', 130);

f3 = figure('Color', 'w', 'Position', [100 100 700 420]);
plotConvergence(H);
exportgraphics(f3, fullfile(o.OutputDir, 'convergence.png'), 'Resolution', 130);

result = struct('name', name, 'options', o, 'fitError', fitErr, 'Au', Au, 'Al', Al, ...
    'AuOpt', AuOpt, 'AlOpt', AlOpt, 'dte', dte, 'x', x, 'yu', yu, 'yl', yl, ...
    'original', mBase, 'optimized', mOpt, 'polarOriginal', polBase, 'polarOptimized', polOpt, ...
    'curvatureOriginalFit', cFit, 'curvatureOptimized', cOpt, 'curvatureLimits', rmfield(curvRef, 'basis'), ...
    'summary', summary, 'history', H, 'runInfo', info, 'outputDir', o.OutputDir);
save(fullfile(o.OutputDir, 'result.mat'), 'result');
end

function t = maxThickness(xu, yu, xl, yl)
% Maximum thickness of the input airfoil on a common grid
xs = linspace(0.01, 0.99, 400)';
iu = xu > 0.005; il = xl > 0.005;
t = max(interp1(xu(iu), yu(iu), xs, 'pchip') - interp1(xl(il), yl(il), xs, 'pchip'));
end

function X = feasibleSamples(n, lb, ub, isValid)
% n random designs within the bounds that meet the geometric limits
nv = numel(lb);
X = zeros(0, nv);
tries = 0;
while size(X, 1) < n && tries < 2e6
    Z = lb + (ub - lb) .* rand(2000, nv);
    ok = validRows(Z, isValid);
    X = [X; Z(ok, :)]; %#ok<AGROW>
    tries = tries + size(Z, 1);
end
if size(X, 1) < n
    warning('optimize_airfoil:fewValid', ...
        'Only %d of %d starting designs meet the limits; the others are random.', size(X, 1), n);
    X = [X; lb + (ub - lb) .* rand(n - size(X, 1), nv)];
end
X = X(1:n, :);
end

function ok = validRows(X, isValid)
ok = false(size(X, 1), 1);
for i = 1:size(X, 1)
    ok(i) = isValid(X(i, :));
end
end

function [c, ceq] = curvatureConstraint(d, S)
n1 = numel(S.Au);
c = curvatureViolation(S.Au + d(1:n1), S.Al + d(n1+1:end), S.dte, S.curv);
ceq = [];
end

function H = readHistory(folder)
% All logged evaluations in time order
files = dir(fullfile(folder, 'eval_*.csv'));
T = cell(numel(files), 1);
for i = 1:numel(files)
    T{i} = readtable(fullfile(files(i).folder, files(i).name), 'Delimiter', ',', ...
        'ReadVariableNames', false, 'FileType', 'text', 'TextType', 'char');
end
T = vertcat(T{:});
T = sortrows(T, 1);
nv = width(T) - 4;
H = table(T{:, 1} - T{1, 1}, T{:, 2}, T{:, 3}, T{:, 4}, T{:, 5:end}, 'VariableNames', ...
    {'time_s', 'stage', 'objective', 'xfoil_analyses', 'd'});
H.d = reshape(H.d, [], nv);
end

function plotConvergence(H)
% Best efficiency so far against the number of designs analysed with XFOIL
analysed = H.xfoil_analyses > 0;
f = H.objective;
f(~(f < 0)) = 0;                            % failed or rejected designs
best = -cummin(f);
n = cumsum(analysed);
plot(n(analysed), best(analysed), 'k-', 'LineWidth', 1.5); hold on;
stages = {'global', 'local'};
colors = {'b', 'r'};
for i = 1:2
    k = find(strcmp(H.stage, stages{i}) & analysed, 1);
    if ~isempty(k), xline(n(k), [colors{i} ':'], stages{i}); end
end
grid on; xlabel('designs analysed with XFOIL'); ylabel('best objective so far');
end

function s = describeFile(file)
d = dir(file);
if isempty(d)
    s = struct('path', file, 'bytes', NaN, 'date', '');
else
    s = struct('path', file, 'bytes', d.bytes, 'date', d.date);
end
end

function s = gitDescribe(folder)
% Commit of the code that produced the result, marked if files were changed
[st, out] = system(sprintf('git -C "%s" rev-parse --short HEAD', folder));
if st ~= 0
    s = 'unknown';
    return;
end
s = strtrim(out);
[~, changes] = system(sprintf('git -C "%s" status --porcelain -- .', folder));
if ~isempty(strtrim(changes)), s = [s ' + uncommitted changes']; end
end

function s = cleanOutput(s)
% Solver output without large internal fields
if ~isstruct(s), s = struct(); return; end
for f = {'rngstate', 'problemtype', 'function', 'lambda', 'grad', 'hessian', 'bestfeasible'}
    if isfield(s, f{1}), s = rmfield(s, f{1}); end
end
end
