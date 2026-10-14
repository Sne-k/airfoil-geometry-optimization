function validate_e387(airfoilFile, outDir, pilot)
%VALIDATE_E387  Fluent (Transition SST) and XFOIL against the Eppler 387 measurements of NASA TM-4062.
%   VALIDATE_E387(airfoilFile) runs the Eppler 387 airfoil at Re = 300 000
%   and M = 0.09, the condition of McGhee, Walker & Millard (1988), NASA
%   TM-4062 (Langley Low-Turbulence Pressure Tunnel), at 0, 2, 4 and 6 deg:
%     - Fluent with the Transition SST model and the settings of the design
%       study (run_design_study.m): the same C-grid generator, 400
%       first-order and 5000 second-order iterations, wall profiles over
%       the last 2400. The free-stream turbulence is set so that about
%       0.06 % reaches the airfoil, the level the report gives for these
%       runs (total pressure 15 psi); the far-field value is 0.065 % with a
%       viscosity ratio of 50 (decay over 500 chords).
%     - XFOIL with free transition at Ncrit = 9 (Mack's relation gives 9.4
%       for 0.06 %), M = 0.09, 160 panel nodes, -3 to 12 deg.
%   airfoilFile is a coordinate file of the Eppler 387 (for example
%   e387.dat of the UIUC Airfoil Coordinates Database); it is not part of
%   the repository.
%
%   Results go to outDir (default MATLAB/output/cfd/e387): forces.csv,
%   history.csv, meshes.csv, xfoil.csv, run_info.json, the Fluent
%   transcripts and profile files. collect_cfd_results.m compares them with
%   the measured values in results/cfd/e387/reference_ltpt.csv.
%
%   VALIDATE_E387(airfoilFile, outDir, true) runs a few iterations at 4 deg
%   (a check of the set-up). Fluent is needed: set FLUENT_EXE to fluent.exe;
%   XFOIL is needed: set XFOIL_EXE to xfoil.exe.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
if nargin < 2 || isempty(outDir), outDir = fullfile(root, 'output', 'cfd', 'e387'); end
if nargin < 3, pilot = false; end
if ~exist(outDir, 'dir'), mkdir(outDir); end
addpath(here, fullfile(root, 'Aerodynamics'), fullfile(root, 'NACA2412'));
started = datetime('now', 'TimeZone', 'UTC');

[xu, yu, xl, yl] = readAirfoil(airfoilFile);
G = airfoilCGrid(xu, yu, xl, yl, 'Radius', 500, 'WakeLength', 500, 'WakeFirstCell', 0.1, 'NNormal', 180);
info = writeFluentMesh(fullfile(outDir, 'e387.msh'), G);
writematrix([G.X(G.iTE(1):G.iTE(2), 1), G.Y(G.iTE(1):G.iTE(2), 1)], fullfile(outDir, 'e387_wall.csv'));
fprintf('[MESH e387] %d cells, %d negative\n', info.nCells, info.nNegative);
writetable(table({'e387'}, info.nCells, info.nNegative, G.firstCell, G.growth, G.wakeGrowth, 'VariableNames', ...
    {'design', 'cells', 'negative_cells', 'first_cell', 'growth', 'wake_growth'}), fullfile(outDir, 'meshes.csv'));

% XFOIL
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end
p = xfoilPolar(xu, yu, xl, yl, 3e5, [-3 12 0.5], exe, [], true, struct('Mach', 0.09));
writetable(table(p.alpha(:), p.CL(:), p.CD(:), p.CM(:), p.xtrTop(:), p.xtrBot(:), 'VariableNames', ...
    {'alpha', 'CL', 'CD', 'CM', 'xtrTop', 'xtrBot'}), fullfile(outDir, 'xfoil.csv'));
fprintf('[XFOIL] %d angles\n', numel(p.alpha));

% Fluent
base = {'Model', 'transition', 'Re', 3e5, 'Mach', 0.09, 'Intensity', 0.065, 'ViscRatio', 50, 'TimeStep', 1, ...
    'StartTimeStep', 20, 'FirstOrder', 400, 'BlockSize', 50, 'Blocks', 100, 'Probes', [1 0.25], ...
    'SurfaceEvery', [200 2400], 'Tail', 48};
alphas = [4 2 0 6];
if pilot
    base(end-11:end) = {'FirstOrder', 20, 'BlockSize', 10, 'Blocks', 3, 'Probes', [1 0.25], 'SurfaceEvery', [10 30], 'Tail', 48};
    alphas = 4;
end
[T, H] = run_fluent_cases(fullfile(outDir, 'e387.msh'), alphas, base{:}, 'Tag', 'transition_', 'Reuse', true, ...
    'WriteTables', false, 'Surface', true);
writetable(T, fullfile(outDir, 'forces.csv'));
writetable(H, fullfile(outDir, 'history.csv'));
writeRunInfo(fullfile(outDir, 'run_info.json'), here, started, base, fullfile(outDir, T.transcript{1}));
fprintf('[E387 VALIDATION DONE]\n');
end
