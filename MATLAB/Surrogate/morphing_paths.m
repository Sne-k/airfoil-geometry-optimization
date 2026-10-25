% Morphing paths for the decision on morphing: peak CL/CD with free transition (Ncrit 9) and with transition
% tripped at 5 % chord along a linear blend of the surfaces from the original to an optimised design
% (21 shapes, blend fraction 0 to 1), the robust objective (their mean), CM at 0 deg and t/c. As
% morph_to_design.m, but both conditions and the consensus polars of the population study.
% Paths: NACA 2412 -> surrogate design (seed 3), NACA 2412 -> design of the current optimiser for the same
% objective (population study, robusttrip seed 3, the design of the CFD study), NACA 0012 -> surrogate design (seed 3).
% Output: surrogate/morph_paths/morph_paths.csv (published as results/surrogate/morphing_paths.csv).
W = getenv('AIRFOIL_WORK');                         % work folder with the logged runs (MATLAB/Surrogate/README.md)
if isempty(W), error('Surrogate:work', 'Set the environment variable AIRFOIL_WORK (MATLAB/Surrogate/README.md).'); end
here = fileparts(mfilename('fullpath'));  ML = fileparts(here);
addpath(fullfile(ML, 'Aerodynamics'), fullfile(ML, 'NACA2412'), fullfile(ML, 'Paper'), fullfile(ML, 'Optimization'));
exe = fullfile(W, 'tools', 'xfoil.exe');
out = fullfile(W, 'surrogate', 'morph_paths');
if ~exist(out, 'dir'), mkdir(out); end
paths = {'NACA_2412', 'surrogate', fullfile(W, 'surrogate', 'benchmark_v3', 'NACA_2412_surrogate_s3', 'result.mat')
         'NACA_2412', 'current optimiser', fullfile(W, 'population_runs', 'NACA_2412_robusttrip_s3', 'result.mat')
         'NACA_0012', 'surrogate', fullfile(W, 'surrogate', 'benchmark_v4', 'NACA_0012_surrogate_s3', 'result.mat')};
x = (1 - cos(linspace(0, pi, 161)')) / 2;
F = 0:0.05:1;
jobs = cell(0, 5);
for p = 1:size(paths, 1)
    [xu, yu, xl, yl] = readAirfoil(strrep(paths{p, 1}, '_', ' '));
    yuB = onGrid(xu, yu, x);  ylB = onGrid(xl, yl, x);
    r = load(paths{p, 3});  r = r.result;
    if iscell(r.x), xs = r.x; else, xs = {r.x, r.x}; end
    yuT = onGrid(xs{1}, r.yu, x);  ylT = onGrid(xs{2}, r.yl, x);
    for f = F
        jobs(end+1, :) = {paths{p, 1}, paths{p, 2}, f, (1 - f) * yuB + f * yuT, (1 - f) * ylB + f * ylT}; %#ok<AGROW>
    end
end
if isempty(gcp('nocreate')), parpool('Processes', 4); end
R = cell(size(jobs, 1), 1);
parfor j = 1:size(jobs, 1)
    yu = jobs{j, 4};  yl = jobs{j, 5};
    v = nan(1, 4);
    [pf, sf] = consensusPolar(x, yu, x, yl, 1e6, exe, struct());
    [pt, st] = consensusPolar(x, yu, x, yl, 1e6, exe, struct('Xtr', [0.05 0.05]));
    if usable(pf), m = efficiencyMetrics(pf); v(1) = m.LDmax; v(3) = m.CM0; end
    if usable(pt), m = efficiencyMetrics(pt); v(2) = m.LDmax; end
    v(4) = max(yu - yl);
    R{j} = {jobs{j, 1}, jobs{j, 2}, jobs{j, 3}, v(1), v(2), mean(v(1:2)), v(3), v(4), sf.sensitivityPercent, st.sensitivityPercent};
end
T = cell2table(vertcat(R{:}), 'VariableNames', {'airfoil', 'design', 'blend', 'LDmax_free', 'LDmax_tripped', ...
    'robust_objective', 'CM0', 'tc', 'sensitivity_free_percent', 'sensitivity_tripped_percent'});
writetable(T, fullfile(out, 'morph_paths.csv'));
disp(T);
fprintf('[MORPH PATHS DONE]\n');

function y = onGrid(xs, ys, x)
[xs, i] = unique(xs(:));  ys = ys(:);  ys = ys(i);
y = interp1(xs, ys, x, 'pchip');
end

function ok = usable(p)
ok = numel(p.alpha) >= 12 && p.alpha(1) <= 0 && p.alpha(end) >= 0;
end
