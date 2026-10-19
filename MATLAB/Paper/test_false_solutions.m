function T = test_false_solutions(casesFile)
%TEST_FALSE_SOLUTIONS  Reproduces the known false XFOIL solutions of the population study and the effect of the friction floor.
%   T = TEST_FALSE_SOLUTIONS() reads results/population/false_solution_cases.csv:
%   six final designs whose objective XFOIL overrated at one panelling (a
%   false low-drag solution at the exact coordinates) and one control
%   design. For each it rebuilds the exact coordinates from the CST
%   coefficients (150 cosine-spaced points, as optimize_airfoil.m) and
%   evaluates the objective of the optimiser (designObjective.m) at 160 and
%   200 panel nodes, without and with the friction floor of xfoilPolar. The
%   values must agree with the expected ones in the file (from
%   sensitivity_before_reruns.csv) within 0.05 %; a value of 0 means the
%   polar is not usable. T lists computed and expected values; the function
%   stops with an error if a value does not agree.
%
%   XFOIL is needed: set XFOIL_EXE to xfoil.exe. The test runs 7 designs x 4
%   evaluations (about ten minutes).

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
if nargin < 1 || isempty(casesFile), casesFile = fullfile(root, '..', 'results', 'population', 'false_solution_cases.csv'); end
addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'Optimization'));
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end

C = readtable(casesFile, 'TextType', 'char');
x = (1 - cos(linspace(0, pi, 150)')) / 2;
names = {'exact160', 'exact200', 'exact160_floor', 'exact200_floor'};
variants = {[], false; 200, false; [], true; 200, true};
rows = cell(height(C), 1);
ok = true;
for k = 1:height(C)
    Au = C{k, compose('Au%d', 0:6)};  Al = C{k, compose('Al%d', 0:6)};
    [yu, yl] = cstSurfaces(Au, Al, C.dte(k), x);
    S = struct('Re', C.Re(k), 'objective', C.objective{k}, 'design', [], 'weights', [], 'aggregate', C.aggregate{k}, ...
        'cmMax', C.cm_max(k), 'clMaxMin', -Inf);
    S.flows = {struct('Ncrit', 9)};
    if strcmp(C.flows{k}, 'free+tripped'), S.flows = {struct('Ncrit', 9), struct('Xtr', [0.05 0.05])}; end   % as run_population_study.m
    v = zeros(1, 4);
    for m = 1:4
        v(m) = designObjective(x, yu, yl, S, variants{m, 1}, variants{m, 2}, exe);
    end
    expected = C{k, names};
    agree = abs(v - expected) <= 5e-4 * max(abs(expected), 1e-9) | (v == 0 & expected == 0);
    ok = ok && all(agree);
    rows{k} = [{C.tag{k}, C.role{k}}, num2cell(v), num2cell(expected), {all(agree)}];
    fprintf('%-26s %-14s %s | expected %s | %s\n', C.tag{k}, C.role{k}, sprintf('%8.2f', v), sprintf('%8.2f', expected), ...
        string(all(agree)));
end
T = cell2table(vertcat(rows{:}), 'VariableNames', [{'tag', 'role'}, names, strcat('expected_', names), {'agrees'}]);
if ~ok, error('test_false_solutions:mismatch', 'Some values do not agree with the expected ones.'); end
fprintf('All %d designs reproduce the expected values.\n', height(T));
end
