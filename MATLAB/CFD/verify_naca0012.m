function verify_naca0012(outDir, pilot)
%VERIFY_NACA0012  Verification of the Fluent set-up on the NASA NACA 0012 case.
%   VERIFY_NACA0012 runs the 2-D NACA 0012 validation case of the NASA
%   Turbulence Modeling Resource (SST, M = 0.15, Re = 6e6, free-stream
%   turbulence intensity 0.052 %, viscosity ratio 0.009) with the solver
%   set-up of the design study (run_design_study.m): fixed pseudo-time step
%   of one chord passage, 400 first-order and 3000 second-order iterations,
%   forces printed every 50 iterations. Runs:
%     coarse, medium and fine mesh, far field 500 chords away:
%                             alpha = 0, 10 and 15 deg (mesh convergence)
%     far field 100 and 20 chords away, resolution of the medium mesh:
%                             alpha = 10 deg (effect of the domain size)
%   The three meshes are geometrically similar (refinement ratio sqrt(2) in
%   both directions, the same total growth from the wall to the far field).
%   The meshes with a nearer far field keep the first cell, the growth
%   ratios and the surface spacing of the medium mesh and only have fewer
%   cells towards the far field and along the wake.
%
%   Results go to outDir (default MATLAB/output/cfd/verification):
%   forces.csv (one row per run), history.csv (forces every 50 iterations),
%   meshes.csv, run_info.json, the Fluent transcripts, and for every run a
%   profile file with the pressure and wall shear on the airfoil (the wall
%   nodes of each mesh are in <mesh>_wall.csv; see fluentSurface). Runs that are
%   already complete are not repeated, so the batch can be stopped and
%   started again. collect_cfd_results.m makes the tables and figures.
%
%   VERIFY_NACA0012(outDir, true) runs a few iterations of every mesh (a
%   check of the journals). Fluent is needed: set the environment variable
%   FLUENT_EXE to fluent.exe.

here = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outDir), outDir = fullfile(here, '..', 'output', 'cfd', 'verification'); end
if nargin < 2, pilot = false; end
if ~exist(outDir, 'dir'), mkdir(outDir); end
addpath(here);
started = datetime('now', 'TimeZone', 'UTC');

% NASA TMR NACA 0012 (sharp trailing edge, chord 1)
x = (1 - cos(linspace(0, pi, 2001)')) / 2;
y = 0.594689181*(0.298222773*sqrt(x) - 0.127125232*x - 0.357907906*x.^2 + 0.291984971*x.^3 - 0.105174606*x.^4);

%% Mesh family (far field 500 chords away)
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
radius = [R R R];

%% Medium resolution with the far field at 100 and 20 chords
% the same first cell and growth ratios as the medium mesh, fewer cells
G = airfoilCGrid(x, y, x, -y, 'NSurface', nSurface(2) + 1, 'NWake', nWake(2), 'NNormal', nNormal(2) + 1, ...
    'FirstCell', h1(2), 'WakeFirstCell', hw(2), 'Radius', R, 'WakeLength', R);
gw = G.wakeGrowth;
h0 = R * (gw - 1) / (gw^nWake(2) - 1);   % first cell of the wake cut behind the trailing edge
for Rk = [100 20]
    names{end+1} = sprintf('R%d', Rk); %#ok<AGROW>
    nNormal(end+1) = round(log(Rk * (rm - 1) / h1m + 1) / log(rm)); %#ok<AGROW>
    nSurface(end+1) = nSurface(2); %#ok<AGROW>
    nWake(end+1) = round(log(Rk * (gw - 1) / h0 + 1) / log(gw)); %#ok<AGROW>
    h1(end+1) = h1m; %#ok<AGROW>
    hw(end+1) = hw(2) * Rk / R;          %#ok<AGROW> the same growth of the first cell along the wake
    radius(end+1) = Rk; %#ok<AGROW>
end

M = cell(numel(names), 1);
for k = 1:numel(names)
    G = airfoilCGrid(x, y, x, -y, 'NSurface', nSurface(k) + 1, 'NWake', nWake(k), 'NNormal', nNormal(k) + 1, ...
        'FirstCell', h1(k), 'WakeFirstCell', hw(k), 'Radius', radius(k), 'WakeLength', radius(k));
    info = writeFluentMesh(fullfile(outDir, ['n0012_' names{k} '.msh']), G);
    writematrix([G.X(G.iTE(1):G.iTE(2), 1), G.Y(G.iTE(1):G.iTE(2), 1)], fullfile(outDir, ['n0012_' names{k} '_wall.csv']));
    fprintf('[MESH %s] %d cells, %d negative; first cell %.3e, growth %.5f, wake growth %.5f\n', ...
        names{k}, info.nCells, info.nNegative, h1(k), G.growth, G.wakeGrowth);
    M{k} = {names{k}, radius(k), info.nCells, info.nNegative, h1(k), G.growth, G.wakeGrowth, hw(k), ...
        nSurface(k), nWake(k), nNormal(k)};
end
M = cell2table(vertcat(M{:}), 'VariableNames', {'mesh', 'far_field_chords', 'cells', 'negative_cells', ...
    'first_cell', 'growth', 'wake_growth', 'wake_first_cell', 'cells_per_surface', 'cells_along_wake', 'cells_normal'});
writetable(M, fullfile(outDir, 'meshes.csv'));

%% Runs (the most important first)
opts = {'Model', 'sst', 'Re', 6e6, 'Mach', 0.15, 'TimeStep', 1, 'FirstOrder', 400, 'BlockSize', 50, 'Blocks', 60};
runs = {'medium', [10 0 15]; 'coarse', 10; 'fine', 10; 'R100', 10; 'R20', 10; 'coarse', [0 15]; 'fine', [0 15]};
if pilot
    opts = {'Model', 'sst', 'Re', 6e6, 'Mach', 0.15, 'TimeStep', 1, 'FirstOrder', 20, 'BlockSize', 10, 'Blocks', 3};
    runs = {'coarse', 10; 'R100', 10; 'R20', 10};
end
allT = {};  allH = {};
for k = 1:size(runs, 1)
    for a = runs{k, 2}
        try
            [T, H] = run_fluent_cases(fullfile(outDir, ['n0012_' runs{k, 1} '.msh']), a, opts{:}, ...
                'Reuse', true, 'WriteTables', false, 'Surface', true);
            T.mesh = repmat(runs(k, 1), height(T), 1);
            H.mesh = repmat(runs(k, 1), height(H), 1);
            allT{end+1} = T;  allH{end+1} = H; %#ok<AGROW>
            writetable(vertcat(allT{:}), fullfile(outDir, 'forces.csv'));
            writetable(vertcat(allH{:}), fullfile(outDir, 'history.csv'));
        catch err
            fprintf('[FAIL %s alpha %g] %s\n', runs{k, 1}, a, getReport(err, 'extended', 'hyperlinks', 'off'));
        end
        fprintf('[%s alpha %g finished %s]\n', runs{k, 1}, a, char(datetime('now', 'Format', 'HH:mm:ss')));
    end
end
first = dir(fullfile(outDir, '*.out'));
writeRunInfo(fullfile(outDir, 'run_info.json'), here, started, opts, fullfile(outDir, first(1).name));
T = vertcat(allT{:});
disp(T(:, {'mesh', 'alpha', 'CL', 'CD', 'CL_range', 'CD_range', 'blocks', 'seconds'}));
fprintf('[VERIFICATION DONE]\n');
end
