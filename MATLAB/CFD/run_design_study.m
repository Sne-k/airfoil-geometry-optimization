function run_design_study(outDir, pilot)
%RUN_DESIGN_STUDY  RANS check of the XFOIL-optimised NACA 2412 designs.
%   RUN_DESIGN_STUDY runs Fluent for four airfoils at Re = 1e6 and M = 0.15:
%     naca2412    the original NACA 2412
%     smooth_s1   optimised for peak CL/CD with curvature limits (seed 1,
%                 the best of three; results/paper/runs/NACA_2412_s1)
%     wavy_s1     the same without curvature limits (seed 1, the best of
%                 three; results/paper/runs/NACA_2412_nocurv_s1)
%     parsec_t12  the earlier PARSEC design (results/xfoil)
%   with two models:
%     transition  Transition SST (gamma-Re_theta). The far field has a
%                 turbulence intensity of 0.14 % and a viscosity ratio of
%                 50, so that about 0.07 % reaches the airfoil: the
%                 intensity that corresponds to XFOIL's Ncrit = 9 by
%                 Mack's relation Tu = exp(-(Ncrit + 8.43)/2.4). The value
%                 at the airfoil is read from two probe points one and a
%                 quarter chord upstream of the leading edge.
%                 Angles 0, 2, 3, 4, 5, 6, 7 and 8 deg.
%     sst         k-omega SST, fully turbulent (a pessimistic bound), with
%                 the inflow of the NASA verification case (0.052 %, 0.009).
%                 Angles 0, 2, 4, 6 and 8 deg.
%   The meshes are those of the medium mesh of verify_naca0012.m with a
%   first cell of 1e-5 chords (y+ about 0.5 at this Reynolds number), the
%   far field 500 chords away.
%
%   Solver set-up: as verified, with one difference. The first-order stage
%   (400 iterations) uses a pseudo-time step of 20 chord passages instead of
%   one, because the free-stream turbulence has to travel 500 chords from
%   the far field before it is settled at the airfoil, and the transition
%   location depends on it. The second-order stage uses the verified step of one chord
%   passage: 3000 iterations with SST and 5000 with Transition SST, forces
%   every 50 iterations. The first run repeats the NASA NACA 0012 case
%   (medium mesh, 10 deg) with this start-up, to show that it gives the same
%   forces as verify_naca0012.m.
%
%   The Transition SST runs do not settle. The laminar shear layer of the
%   separation bubble rolls up into a train of small separation cells, and
%   this train drifts slowly during the iterations: for NACA 2412 at 4 deg
%   the drag cycles between 0.0056 and 0.0067 with a period of about 2500
%   iterations (results/cfd/README.md). The other solver settings of
%   transition_tests.m do not remove the cycle. The runs are therefore long
%   enough to hold a whole cycle after the start-up, the wall data are
%   written every 200 iterations over the last 2400, and
%   collect_cfd_results.m takes means over whole cycles and gives the range.
%
%   Order of the runs: the start-up check, the SST runs, the Transition SST
%   runs. Each model ends with NACA 2412 at 4 deg on a mesh refined by
%   sqrt(2) in both directions (a check of the mesh).
%
%   Results go to outDir (default MATLAB/output/cfd/designs): forces.csv
%   (one row per run, with the mean and the range of CL and CD over the last
%   1000 iterations with SST and 2400 with Transition SST), history.csv,
%   meshes.csv, run_info.json, the Fluent transcripts and, for every run,
%   profile files with the pressure and wall shear on the airfoil. Complete
%   runs are not repeated, so the batch can be stopped and started again.
%   collect_cfd_results.m makes the tables and figures.
%
%   RUN_DESIGN_STUDY(outDir, true) runs a few iterations of both models on
%   every mesh (a check of the meshes and journals). Fluent is needed: set
%   the environment variable FLUENT_EXE to fluent.exe.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
repo = fullfile(root, '..');
if nargin < 1 || isempty(outDir), outDir = fullfile(root, 'output', 'cfd', 'designs'); end
if nargin < 2, pilot = false; end
if ~exist(outDir, 'dir'), mkdir(outDir); end
addpath(here, fullfile(root, 'Aerodynamics'), fullfile(root, 'NACA2412'));
started = datetime('now', 'TimeZone', 'UTC');

designs = {'naca2412', 'NACA 2412'
           'smooth_s1', fullfile(repo, 'results', 'paper', 'runs', 'NACA_2412_s1', 'NACA_2412_optimized.dat')
           'wavy_s1', fullfile(repo, 'results', 'paper', 'runs', 'NACA_2412_nocurv_s1', 'NACA_2412_optimized.dat')
           'parsec_t12', fullfile(repo, 'results', 'xfoil', 'NACA2412_parsec_t12_optimized.dat')};
nD = size(designs, 1);
far = {'Radius', 500, 'WakeLength', 500, 'WakeFirstCell', 0.1, 'NNormal', 180};
M = cell(nD + 2, 1);
for k = 1:nD
    [xu, yu, xl, yl] = readAirfoil(designs{k, 2});
    G = airfoilCGrid(xu, yu, xl, yl, far{:});
    M{k} = saveMesh(outDir, designs{k, 1}, G);
end
% NASA NACA 0012, medium mesh of verify_naca0012.m (first cell 2e-6)
x = (1 - cos(linspace(0, pi, 2001)')) / 2;
y = 0.594689181*(0.298222773*sqrt(x) - 0.127125232*x - 0.357907906*x.^2 + 0.291984971*x.^3 - 0.105174606*x.^4);
G = airfoilCGrid(x, y, x, -y, far{:}, 'NSurface', 201, 'NWake', 80, 'FirstCell', 2e-6);
M{nD + 1} = saveMesh(outDir, 'n0012_medium', G);
% NACA 2412 refined by sqrt(2) in both directions, with the same total growth
% away from the wall (as the fine mesh of verify_naca0012.m)
rm = fzero(@(r) 1e-5 * (r^179 - 1) / (r - 1) - 500, [1.0001 2]);
gf = rm^(179 / 253);
[xu, yu, xl, yl] = readAirfoil(designs{1, 2});
G = airfoilCGrid(xu, yu, xl, yl, 'Radius', 500, 'WakeLength', 500, 'WakeFirstCell', 0.1 / sqrt(2), 'NNormal', 254, ...
    'NSurface', 284, 'NWake', 113, 'FirstCell', 500 * (gf - 1) / (rm^179 - 1));
M{nD + 2} = saveMesh(outDir, 'naca2412_fine', G);
M = cell2table(vertcat(M{:}), 'VariableNames', {'design', 'cells', 'negative_cells', 'first_cell', 'growth', 'wake_growth'});
writetable(M, fullfile(outDir, 'meshes.csv'));

common = {'Mach', 0.15, 'TimeStep', 1, 'StartTimeStep', 20, 'FirstOrder', 400, 'BlockSize', 50, 'Probes', [1 0.25]};
models = {'sst', {'Model', 'sst', 'Re', 1e6, 'Intensity', 0.052, 'ViscRatio', 0.009, 'Blocks', 60, 'Tail', 20}, [4 6 2 0 8]
          'transition', {'Model', 'transition', 'Re', 1e6, 'Intensity', 0.14, 'ViscRatio', 50, 'SurfaceEvery', [200 2400], ...
                         'Blocks', 100, 'Tail', 48}, [4 5 6 2 0 8 3 7]};
check = {'Model', 'sst', 'Re', 6e6, 'Intensity', 0.052, 'ViscRatio', 0.009, 'Blocks', 60, 'Tail', 20};
if pilot
    common = {'Mach', 0.15, 'TimeStep', 1, 'StartTimeStep', 20, 'FirstOrder', 20, 'BlockSize', 10, 'Probes', [1 0.25]};
    models{1, 2}(end-3:end) = {'Blocks', 3, 'Tail', 20};  models{1, 3} = 4;
    models{2, 2}(end-5:end) = {'SurfaceEvery', [10 30], 'Blocks', 3, 'Tail', 48};  models{2, 3} = 5;
    check(end-3:end) = {'Blocks', 3, 'Tail', 20};
end

% {model, options, design, alpha}: the start-up check first; then, for each
% model, the angles near the optima for every design and the refined mesh
runs = {'check', check, 'n0012_medium', 10};
for m = 1:size(models, 1)
    for a = models{m, 3}
        for k = 1:nD, runs(end+1, :) = {models{m, 1}, models{m, 2}, designs{k, 1}, a}; end %#ok<AGROW>
    end
    runs(end+1, :) = {models{m, 1}, models{m, 2}, 'naca2412_fine', 4}; %#ok<AGROW>
end

allT = {};  allH = {};
for k = 1:size(runs, 1)
    try
        [T, H] = run_fluent_cases(fullfile(outDir, [runs{k, 3} '.msh']), runs{k, 4}, common{:}, runs{k, 2}{:}, ...
            'Tag', [runs{k, 1} '_'], 'Reuse', true, 'WriteTables', false, 'Surface', true);
        T.design = repmat(runs(k, 3), height(T), 1);
        T.model = repmat(runs(k, 1), height(T), 1);
        H.design = repmat(runs(k, 3), height(H), 1);
        H.model = repmat(runs(k, 1), height(H), 1);
        allT{end+1} = T;  allH{end+1} = H; %#ok<AGROW>
        writetable(vertcat(allT{:}), fullfile(outDir, 'forces.csv'));
        writetable(vertcat(allH{:}), fullfile(outDir, 'history.csv'));
    catch err
        fprintf('[FAIL %s %s alpha %g] %s\n', runs{k, 1}, runs{k, 3}, runs{k, 4}, ...
            getReport(err, 'extended', 'hyperlinks', 'off'));
    end
    fprintf('[%d of %d: %s %s alpha %g finished %s]\n', k, size(runs, 1), runs{k, 1}, runs{k, 3}, runs{k, 4}, ...
        char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
end
first = dir(fullfile(outDir, '*.out'));
writeRunInfo(fullfile(outDir, 'run_info.json'), here, started, ...
    [common, {'sst', models{1, 2}, 'transition', models{2, 2}}], fullfile(outDir, first(1).name));
fprintf('[DESIGN STUDY DONE]\n');
end

function row = saveMesh(outDir, name, G)
info = writeFluentMesh(fullfile(outDir, [name '.msh']), G);
writematrix([G.X(G.iTE(1):G.iTE(2), 1), G.Y(G.iTE(1):G.iTE(2), 1)], fullfile(outDir, [name '_wall.csv']));
fprintf('[MESH %s] %d cells, %d negative; growth %.5f, wake growth %.5f\n', name, info.nCells, info.nNegative, ...
    G.growth, G.wakeGrowth);
row = {name, info.nCells, info.nNegative, G.firstCell, G.growth, G.wakeGrowth};
end
