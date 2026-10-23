% Step 1b: recompute the suspect logged designs (surrogate/suspects_A.csv) with XFOIL and the friction floor,
% as the optimiser evaluates them (designObjective.m: -2..12 deg, no restarts, free transition), at 160 and
% 200 panel nodes, without and with the floor. Output: surrogate/suspects_A_relabelled.csv.
W = getenv('AIRFOIL_WORK');                         % work folder with the logged runs (MATLAB/Surrogate/README.md)
if isempty(W), error('Surrogate:work', 'Set the environment variable AIRFOIL_WORK (MATLAB/Surrogate/README.md).'); end
here = fileparts(mfilename('fullpath'));  ML = fileparts(here);  repo = fileparts(ML);   % MATLAB/Surrogate, MATLAB, repo
addpath(fullfile(ML, 'Paper'), fullfile(ML, 'Aerodynamics'), fullfile(ML, 'Optimization'));
exe = fullfile(W, 'tools', 'xfoil.exe');
T = readtable(fullfile(W, 'surrogate', 'suspects_A.csv'), 'TextType', 'char');
x = (1 - cos(linspace(0, pi, 150)')) / 2;
S = struct('Re', 1e6, 'objective', 'LDmax', 'design', [], 'weights', [], 'aggregate', 'mean', 'cmMax', Inf, 'clMaxMin', -Inf);
S.flows = {struct('Ncrit', 9)};
V = nan(height(T), 4);
if isempty(gcp('nocreate')), parpool('Processes', 8); end
parfor k = 1:height(T)
    [yu, yl] = cstSurfaces(T{k, compose('Au%d', 0:6)}, T{k, compose('Al%d', 0:6)}, 0, x);
    V(k, :) = [designObjective(x, yu, yl, S, [], false, exe), designObjective(x, yu, yl, S, 200, false, exe), ...
               designObjective(x, yu, yl, S, [], true, exe), designObjective(x, yu, yl, S, 200, true, exe)];
end
T.recomputed = min(V(:, 1:2), [], 2);  T.floor160 = V(:, 3);  T.floor200 = V(:, 4);  T.floor_min = min(V(:, 3:4), [], 2);
writetable(T, fullfile(W, 'surrogate', 'suspects_A_relabelled.csv'));
fprintf('[RELABEL] %d designs; recomputed equals logged within 0.1 %%: %d; with the floor lower by > 5 %%: %d; unusable with the floor: %d\n', ...
    height(T), sum(abs(T.recomputed ./ T.logged - 1) < 1e-3), sum(T.floor_min < 0.95 * T.logged & T.floor_min > 0), sum(T.floor_min == 0));
