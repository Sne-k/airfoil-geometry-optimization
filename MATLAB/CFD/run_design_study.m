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
%     sst         k-omega SST, fully turbulent (a pessimistic bound), with
%                 the inflow of the NASA verification case (0.052 %, 0.009)
%   Angles of attack: 0, 2, 3, 4, 4.5, 5, 5.5, 6, 7 and 8 deg with
%   Transition SST (every design's XFOIL optimum is among them) and 0, 2, 4,
%   6 and 8 deg with SST. The meshes are those of the medium mesh of
%   verify_naca0012.m with a first cell of 1e-5 chords (y+ about 0.5 at this
%   Reynolds number), and the solver set-up is the verified one: far field
%   500 chords away, fixed pseudo-time step of one chord passage, 400
%   first-order and 3000 second-order iterations, forces every 50
%   iterations.
%
%   Results go to outDir (default MATLAB/output/cfd/designs): forces.csv
%   (one row per run, with the mean and the range of CL and CD over the last
%   1000 iterations), history.csv, meshes.csv, run_info.json and the Fluent
%   transcripts. Complete runs are not repeated, so the batch can be stopped
%   and started again. collect_cfd_results.m makes the tables and figures.
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
M = cell(nD, 1);
for k = 1:nD
    [xu, yu, xl, yl] = readAirfoil(designs{k, 2});
    G = airfoilCGrid(xu, yu, xl, yl, 'Radius', 500, 'WakeLength', 500, 'WakeFirstCell', 0.1, 'NNormal', 180);
    info = writeFluentMesh(fullfile(outDir, [designs{k, 1} '.msh']), G);
    writematrix([G.X(G.iTE(1):G.iTE(2), 1), G.Y(G.iTE(1):G.iTE(2), 1)], fullfile(outDir, [designs{k, 1} '_wall.csv']));
    fprintf('[MESH %s] %d cells, %d negative; growth %.5f, wake growth %.5f\n', designs{k, 1}, info.nCells, ...
        info.nNegative, G.growth, G.wakeGrowth);
    M{k} = {designs{k, 1}, info.nCells, info.nNegative, G.firstCell, G.growth, G.wakeGrowth};
end
M = cell2table(vertcat(M{:}), 'VariableNames', {'design', 'cells', 'negative_cells', 'first_cell', 'growth', 'wake_growth'});
writetable(M, fullfile(outDir, 'meshes.csv'));

common = {'Re', 1e6, 'Mach', 0.15, 'TimeStep', 1, 'FirstOrder', 400, 'BlockSize', 50, 'Blocks', 60, ...
    'Probes', [1 0.25], 'Tail', 20};
models = {'transition', {'Model', 'transition', 'Intensity', 0.14, 'ViscRatio', 50}, [4 5 6 2 0 8 3 7 4.5 5.5]
          'sst', {'Model', 'sst', 'Intensity', 0.052, 'ViscRatio', 0.009}, [4 6 2 0 8]};
if pilot
    common = {'Re', 1e6, 'Mach', 0.15, 'TimeStep', 1, 'FirstOrder', 20, 'BlockSize', 10, 'Blocks', 3, ...
        'Probes', [1 0.25], 'Tail', 20};
    models{1, 3} = 4.5;  models{2, 3} = 4;
end

allT = {};  allH = {};
for m = 1:size(models, 1)
    for a = models{m, 3}                      % the angles near the optima first, for every design
        for k = 1:nD
            try
                [T, H] = run_fluent_cases(fullfile(outDir, [designs{k, 1} '.msh']), a, common{:}, models{m, 2}{:}, ...
                    'Tag', [models{m, 1} '_'], 'Reuse', true, 'WriteTables', false, 'Surface', true);
                T.design = repmat(designs(k, 1), height(T), 1);
                T.model = repmat(models(m, 1), height(T), 1);
                H.design = repmat(designs(k, 1), height(H), 1);
                H.model = repmat(models(m, 1), height(H), 1);
                allT{end+1} = T;  allH{end+1} = H; %#ok<AGROW>
                writetable(vertcat(allT{:}), fullfile(outDir, 'forces.csv'));
                writetable(vertcat(allH{:}), fullfile(outDir, 'history.csv'));
            catch err
                fprintf('[FAIL %s %s alpha %g] %s\n', models{m, 1}, designs{k, 1}, a, ...
                    getReport(err, 'extended', 'hyperlinks', 'off'));
            end
            fprintf('[%s %s alpha %g finished %s]\n', models{m, 1}, designs{k, 1}, a, ...
                char(datetime('now', 'Format', 'HH:mm:ss')));
        end
    end
end
first = dir(fullfile(outDir, '*.out'));
writeRunInfo(fullfile(outDir, 'run_info.json'), here, started, [common, {'transition', models{1, 2}, 'sst', models{2, 2}}], ...
    fullfile(outDir, first(1).name));
fprintf('[DESIGN STUDY DONE]\n');
end
