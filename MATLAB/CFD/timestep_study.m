function timestep_study(outDir, pilot)
%TIMESTEP_STUDY  Finds the Fluent settings that give a steady solution.
%   TIMESTEP_STUDY runs the NASA Turbulence Modeling Resource NACA 0012 case
%   (SST, M = 0.15, Re = 6e6) on a domain reaching 500 chords, with different
%   solver settings, and writes the results to outDir (default
%   MATLAB/output/cfd/timestep_study). collect_cfd_results.m makes the tables.
%
%   Background: on a 20-chord domain the fine mesh at alpha = 10 deg did not
%   reach a steady state with second-order upwinding (the residuals stalled
%   50 times higher than on the medium mesh and CD wandered by about 1 %),
%   and alpha = 15 deg fell onto a stalled solution during the first-order
%   stage. The settings compared:
%     A  Fluent's automatic pseudo-time step
%     B  a fixed pseudo-time step of one chord passage (chord / U)
%     C  alpha = 15 deg reached by continuation 10 - 12 - 14 - 15 deg,
%        automatic pseudo-time step
%     D  the same continuation with the fixed pseudo-time step
%     F  the fine mesh with the differentiable slope limiter, automatic
%        pseudo-time step
%     H  M = 0.1 with the fixed pseudo-time step (with the automatic one it
%        diverged)
%   Every run has 400 first-order and 3000 second-order iterations (1500
%   per angle in the continuations, 400 in H); the forces are printed every
%   50 iterations.
%
%   The three meshes are geometrically similar: refinement ratio sqrt(2) in
%   both directions and the same total growth from the wall to the far
%   field.
%
%   TIMESTEP_STUDY(outDir, true) runs a few iterations of each kind of run on
%   the coarse mesh (a check of the journals). Fluent is needed: set the
%   environment variable FLUENT_EXE to fluent.exe.

here = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outDir), outDir = fullfile(here, '..', 'output', 'cfd', 'timestep_study'); end
if nargin < 2, pilot = false; end
if ~exist(outDir, 'dir'), mkdir(outDir); end
addpath(here);

% NASA TMR NACA 0012 (sharp trailing edge, chord 1)
x = (1 - cos(linspace(0, pi, 2001)')) / 2;
y = 0.594689181*(0.298222773*sqrt(x) - 0.127125232*x - 0.357907906*x.^2 + 0.291984971*x.^3 - 0.105174606*x.^4);

R = 500;
names = {'coarse', 'medium', 'fine'};
nNormal = [127 179 253];                 % cells from the wall to the far field
nSurface = [141 200 283];                % cells per surface
nWake = [57 80 113];                     % cells along the wake cut
h1m = 2e-6;                              % medium mesh: y+ about 0.5 at Re = 6e6
rm = fzero(@(r) h1m * (r^nNormal(2) - 1) / (r - 1) - R, [1.0001 2]);
growth = rm.^(nNormal(2) ./ nNormal);    % the same total growth for the three meshes
h1 = R * (growth - 1) ./ (rm^nNormal(2) - 1);
hw = 0.1 * sqrt(2).^[1 0 -1];            % first cell next to the wake cut at the outlet
M = cell(3, 1);
for k = 1:3
    G = airfoilCGrid(x, y, x, -y, 'NSurface', nSurface(k) + 1, 'NWake', nWake(k), 'NNormal', nNormal(k) + 1, ...
        'FirstCell', h1(k), 'WakeFirstCell', hw(k), 'Radius', R, 'WakeLength', R);
    info = writeFluentMesh(fullfile(outDir, ['n0012_' names{k} '.msh']), G);
    fprintf('[MESH %s] %d cells, %d negative; first cell %.3e, growth %.5f (requested %.5f), wake growth %.5f\n', ...
        names{k}, info.nCells, info.nNegative, h1(k), G.growth, growth(k), G.wakeGrowth);
    M{k} = {names{k}, info.nCells, h1(k), G.growth, hw(k), nSurface(k), nWake(k), nNormal(k)};
end
M = cell2table(vertcat(M{:}), 'VariableNames', {'mesh', 'cells', 'first_cell', 'growth', 'wake_first_cell', ...
    'cells_per_surface', 'cells_along_wake', 'cells_normal'});
writetable(M, fullfile(outDir, 'meshes.csv'));

base = {'Model', 'sst', 'Re', 6e6, 'Mach', 0.15, 'FirstOrder', 400, 'BlockSize', 50};
long = {'Blocks', 60};                   % 3000 second-order iterations
step = {'Blocks', 30};                   % 1500 per angle in a sweep
dt = {'TimeStep', 1};
runs = {'A', 'medium', 10, false, long
        'B', 'medium', 10, false, [long, dt]
        'A', 'medium', 0, false, long
        'A', 'coarse', 10, false, long
        'A', 'fine', 10, false, long
        'B', 'coarse', 10, false, [long, dt]
        'B', 'fine', 10, false, [long, dt]
        'A', 'medium', 15, false, long
        'B', 'medium', 15, false, [long, dt]
        'C', 'medium', [10 12 14 15], true, step
        'D', 'medium', [10 12 14 15], true, [step, dt]
        'F', 'fine', 10, false, [long, {'Limiter', 'differentiable'}]
        'H', 'medium', 0, false, [dt, {'Mach', 0.1, 'Blocks', 8}]};
if pilot                                 % a few iterations of every kind of run on the coarse mesh
    base = {'Model', 'sst', 'Re', 6e6, 'Mach', 0.15, 'FirstOrder', 20, 'BlockSize', 10};
    long = {'Blocks', 3};
    runs = {'A', 'coarse', 10, false, long
            'B', 'coarse', 10, false, [long, dt]
            'D', 'coarse', [10 12], true, [long, dt]
            'F', 'coarse', 10, false, [long, {'Limiter', 'differentiable'}]
            'H', 'coarse', 0, false, [dt, {'Mach', 0.1, 'Blocks', 2}]};
end

allT = {};  allH = {};
for k = 1:size(runs, 1)
    tag = sprintf('r%02d%s_', k, runs{k, 1});
    try
        opts = [base, runs{k, 5}];                       % a later value replaces an earlier one
        [~, last] = unique(opts(1:2:end), 'last');
        last = sort(last(:)).';
        opts = reshape([opts(2*last - 1); opts(2*last)], 1, []);
        [T, H] = run_fluent_cases(fullfile(outDir, ['n0012_' runs{k, 2} '.msh']), runs{k, 3}, opts{:}, ...
            'Sweep', runs{k, 4}, 'Tag', tag);
        T.run = repmat({tag(1:end-1)}, height(T), 1);
        T.setting = repmat(runs(k, 1), height(T), 1);
        T.mesh = repmat(runs(k, 2), height(T), 1);
        H.run = repmat({tag(1:end-1)}, height(H), 1);
        H.setting = repmat(runs(k, 1), height(H), 1);
        H.mesh = repmat(runs(k, 2), height(H), 1);
        allT{end+1} = T;  allH{end+1} = H; %#ok<AGROW>
        writetable(vertcat(allT{:}), fullfile(outDir, 'verification_forces.csv'));
        writetable(vertcat(allH{:}), fullfile(outDir, 'verification_history.csv'));
    catch err
        fprintf('[FAIL %s] %s\n', tag, getReport(err, 'extended', 'hyperlinks', 'off'));
    end
    fprintf('[RUN %d of %d finished %s]\n', k, size(runs, 1), char(datetime('now', 'Format', 'HH:mm:ss')));
end
T = vertcat(allT{:});
disp(T(:, {'run', 'setting', 'mesh', 'alpha', 'CL', 'CD', 'CL_range', 'CD_range', 'blocks', 'seconds'}));
fprintf('[TIMESTEP STUDY DONE]\n');
end
