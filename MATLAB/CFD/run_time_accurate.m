function run_time_accurate(outDir, pilot, varargin)
%RUN_TIME_ACCURATE  One Transition SST case of the design study in physical time.
%   RUN_TIME_ACCURATE runs NACA 2412 at 4 deg (Re = 1e6, M = 0.15) with the
%   Transition SST model, on the mesh and with the inflow of
%   run_design_study.m, in two Fluent sessions:
%     ta_start  the start of the run of the design study: 400 first-order
%               and 2000 second-order iterations in pseudo-time. The case
%               and the data are saved at the end.
%     ta_run    the same case continued time-accurately from that state
%               (fluentTransientJournal): 8000 time steps of 0.001 chord
%               passages, at most 10 iterations per time step, the forces
%               after every time step, the wall data every 10 time steps
%               over the last 4000 and at each of the last 40, and case and
%               data files every 1000 time steps.
%
%   Background: the Transition SST runs of the design study do not settle
%   in pseudo-time, and their forces are means over whole cycles. This run
%   gives the forces of the same model in physical time for comparison.
%
%   Results go to outDir (default MATLAB/output/cfd/time_accurate): the
%   journals with their plans, the transcripts ta_start.out and ta_run.out,
%   the profile files, meshes.csv and run_info.json.
%
%   RUN_TIME_ACCURATE(outDir, true) runs a few iterations and time steps (a
%   check of the journals).
%
%   Options (name, value) after the two arguments, defaults in brackets:
%     'TimeStep'    time step in units of chord / free-stream speed (0.001)
%     'Steps'       number of time steps                             (8000)
%     'Inner'       largest number of iterations per time step         (10)
%     'Tolerance'   fall of the residuals that ends a time step      (1e-3)
%     'Processes'   solver processes                                     (4)
%     'Run'         false writes the mesh and the journals only. The
%                   sessions can then be started without MATLAB, from
%                   outDir and in this order:
%                     fluent 2ddp -g -t4 -i ta_start.jou
%                     fluent 2ddp -g -t4 -i ta_run.jou              (true)
%   Fluent is needed: set the environment variable FLUENT_EXE to fluent.exe.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
if nargin < 1 || isempty(outDir), outDir = fullfile(root, 'output', 'cfd', 'time_accurate'); end
if nargin < 2 || isempty(pilot), pilot = false; end
ip = inputParser;
ip.PartialMatching = false;
ip.addParameter('TimeStep', 0.001);
ip.addParameter('Steps', 8000);
ip.addParameter('Inner', 10);
ip.addParameter('Tolerance', 1e-3);
ip.addParameter('Processes', 4);
ip.addParameter('Run', true);
ip.parse(varargin{:});
o = ip.Results;
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

% Start: the settings of the Transition SST runs of the design study
start = {'Model', 'transition', 'Re', 1e6, 'Mach', 0.15, 'Intensity', 0.14, 'ViscRatio', 50, 'TimeStep', 1, ...
    'StartTimeStep', 20, 'FirstOrder', 400, 'BlockSize', 50, 'Blocks', 40, 'Probes', [1 0.25]};
run = {'Mach', 0.15, 'TimeStep', o.TimeStep, 'Steps', o.Steps, 'Inner', o.Inner, 'Tolerance', o.Tolerance, ...
    'SurfaceEvery', [10 4000], 'SurfaceLast', 40, 'SaveEvery', 1000};
if pilot
    start = {'Model', 'transition', 'Re', 1e6, 'Mach', 0.15, 'Intensity', 0.14, 'ViscRatio', 50, 'TimeStep', 1, ...
        'StartTimeStep', 20, 'FirstOrder', 20, 'BlockSize', 10, 'Blocks', 3, 'Probes', [1 0.25]};
    run = {'Mach', 0.15, 'TimeStep', o.TimeStep, 'Steps', 12, 'Inner', 5, 'Tolerance', o.Tolerance, ...
        'SurfaceEvery', [2 8], 'SurfaceLast', 3, 'SaveEvery', 5};
end
planStart = fluentJournal(fullfile(outDir, 'ta_start.jou'), 'naca2412.msh', 4, start{:}, 'State', 'ta_start');
planRun = fluentTransientJournal(fullfile(outDir, 'ta_run.jou'), 'ta_start', 4, run{:}, 'Tag', 'ta_run');
writetable(planStart, fullfile(outDir, 'ta_start_plan.csv'));
writetable(planRun, fullfile(outDir, 'ta_run_plan.csv'));
fid = fopen(fullfile(outDir, 'fluent_exit.txt'), 'w');  fprintf(fid, '/exit yes\n');  fclose(fid);   % stdin: never wait for input
fprintf('[JOURNALS] %d iterations in pseudo-time, then %d time steps\n', planStart.iteration(end), height(planRun));

if o.Run
    fluent = getenv('FLUENT_EXE');
    if isempty(fluent) || ~isfile(fluent)
        error('run_time_accurate:fluent', 'fluent.exe not found; set the environment variable FLUENT_EXE.');
    end
    for tag = {'ta_start', 'ta_run'}
        if strcmp(tag{1}, 'ta_run') && ~isfile(fullfile(outDir, 'ta_start.cas.h5'))
            error('run_time_accurate:start', 'The start session did not write ta_start.cas.h5; see ta_start.out.');
        end
        system(sprintf('cd /d "%s" && "%s" 2ddp -g -t%d -wait -i "%s.jou" < "fluent_exit.txt" > "%s.out" 2>&1', ...
            outDir, fluent, o.Processes, tag{1}, tag{1}));
        fprintf('[%s finished %s]\n', tag{1}, char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
    end
end
settings = {'start', cell2struct(start(2:2:end), start(1:2:end), 2), 'run', cell2struct(run(2:2:end), run(1:2:end), 2)};
writeRunInfo(fullfile(outDir, 'run_info.json'), here, started, settings, fullfile(outDir, 'ta_run.out'));
state = {'JOURNALS WRITTEN', 'DONE'};
fprintf('[TIME-ACCURATE RUN %s]\n', state{1 + o.Run});
end
