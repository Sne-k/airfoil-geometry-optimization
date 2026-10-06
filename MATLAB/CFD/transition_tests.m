function transition_tests(outDir, pilot)
%TRANSITION_TESTS  Solver settings tried for the Transition SST runs.
%   TRANSITION_TESTS runs NACA 2412 at 4 deg (Re = 1e6, M = 0.15) with the
%   Transition SST model, on the mesh and with the inflow of
%   run_design_study.m, with five solver settings:
%     S  the settings of the design study: 400 first-order iterations with
%        a pseudo-time step of 20 chord passages, then second-order
%        upwinding for all equations with a step of one chord passage
%     R  as S, with a pseudo-time relaxation factor of 0.3 instead of 0.75
%        for the two equations of the transition model
%     U  as S, with first-order upwinding kept for those two equations
%     O  as S, with the step of one chord passage from the start
%     A  Fluent's automatic pseudo-time step throughout
%   Every run has 4000 second-order iterations, and the forces are printed
%   every 50 iterations.
%
%   Background: with setting S the forces do not settle. The laminar shear
%   layer of the separation bubble rolls up into a train of small
%   separation cells, which drifts during the iterations, and the drag
%   cycles. The other settings were tried to see whether the cycle is a
%   matter of the solver settings (see results/cfd/README.md for the
%   outcome).
%
%   Results go to outDir (default MATLAB/output/cfd/transition_tests):
%   forces.csv, history.csv, meshes.csv, run_info.json and the Fluent
%   transcripts. Complete runs are not repeated. collect_cfd_results.m
%   makes the table and the figure.
%
%   TRANSITION_TESTS(outDir, true) runs a few iterations of every setting
%   (a check of the journals). Fluent is needed: set the environment
%   variable FLUENT_EXE to fluent.exe.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
if nargin < 1 || isempty(outDir), outDir = fullfile(root, 'output', 'cfd', 'transition_tests'); end
if nargin < 2, pilot = false; end
if ~exist(outDir, 'dir'), mkdir(outDir); end
addpath(here, fullfile(root, 'Aerodynamics'), fullfile(root, 'NACA2412'));
started = datetime('now', 'TimeZone', 'UTC');

% The mesh of the design study
[xu, yu, xl, yl] = readAirfoil('NACA 2412');
G = airfoilCGrid(xu, yu, xl, yl, 'Radius', 500, 'WakeLength', 500, 'WakeFirstCell', 0.1, 'NNormal', 180);
info = writeFluentMesh(fullfile(outDir, 'naca2412.msh'), G);
fprintf('[MESH naca2412] %d cells, %d negative\n', info.nCells, info.nNegative);
writetable(table({'naca2412'}, info.nCells, info.nNegative, G.firstCell, G.growth, G.wakeGrowth, 'VariableNames', ...
    {'design', 'cells', 'negative_cells', 'first_cell', 'growth', 'wake_growth'}), fullfile(outDir, 'meshes.csv'));

base = {'Model', 'transition', 'Re', 1e6, 'Mach', 0.15, 'Intensity', 0.14, 'ViscRatio', 50, 'FirstOrder', 400, ...
    'BlockSize', 50, 'Blocks', 80, 'Probes', [1 0.25], 'Tail', 48};
if pilot
    base = {'Model', 'transition', 'Re', 1e6, 'Mach', 0.15, 'Intensity', 0.14, 'ViscRatio', 50, 'FirstOrder', 20, ...
        'BlockSize', 10, 'Blocks', 3, 'Probes', [1 0.25], 'Tail', 48};
end
design = {'TimeStep', 1, 'StartTimeStep', 20};
runs = {'S', design
        'R', [design, {'TransitionRelax', 0.3}]
        'U', [design, {'TransitionOrder', 1}]
        'O', {'TimeStep', 1}
        'A', {}};

allT = {};  allH = {};
for k = 1:size(runs, 1)
    try
        [T, H] = run_fluent_cases(fullfile(outDir, 'naca2412.msh'), 4, base{:}, runs{k, 2}{:}, ...
            'Tag', [runs{k, 1} '_'], 'Reuse', true, 'WriteTables', false);
        T.setting = repmat(runs(k, 1), height(T), 1);
        H.setting = repmat(runs(k, 1), height(H), 1);
        allT{end+1} = T;  allH{end+1} = H; %#ok<AGROW>
        writetable(vertcat(allT{:}), fullfile(outDir, 'forces.csv'));
        writetable(vertcat(allH{:}), fullfile(outDir, 'history.csv'));
    catch err
        fprintf('[FAIL %s] %s\n', runs{k, 1}, getReport(err, 'extended', 'hyperlinks', 'off'));
    end
    fprintf('[%d of %d: setting %s finished %s]\n', k, size(runs, 1), runs{k, 1}, ...
        char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
end
first = dir(fullfile(outDir, '*.out'));
writeRunInfo(fullfile(outDir, 'run_info.json'), here, started, base, fullfile(outDir, first(1).name));
fprintf('[TRANSITION TESTS DONE]\n');
end
