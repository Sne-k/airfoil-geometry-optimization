function run_project()
%RUN_PROJECT  Runs the whole project pipeline in order.
%   1. NACA 2412 baseline                   NACA2412/naca2412_baseline.m
%   2. report method (camber/thickness)     Optimization/optimize_naca_ga_nlp.m
%   3. morphing sequence                    Morphing/morph_airfoil.m
%   4. PARSEC fit and PARSEC GA             PARSEC/fit_parsec_naca2412.m, Optimization/run_parsec_ga.m
%   5. XFOIL-in-the-loop optimisation       Optimization/optimize_xfoil_naca.m, optimize_xfoil_parsec.m,
%                                           optimize_airfoil('NACA 2412')
%   6. aerodynamic comparison               Aerodynamics/compare_approaches.m
%   7. morph to the PARSEC design           Morphing/morph_to_design.m
%   8. README figures                       make_report_figures.m, Aerodynamics/plot_polars.m
%   Steps 5 to 7 need XFOIL (see Aerodynamics/README.md) and are skipped
%   when it is not found; they take about an hour on 8 cores. Outputs go to
%   MATLAB/output. Step 8 redraws the figures in results/ from the files
%   stored there.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'Optimization'));
steps = {fullfile(here, 'NACA2412', 'naca2412_baseline.m'), ...
         fullfile(here, 'Optimization', 'optimize_naca_ga_nlp.m'), ...
         fullfile(here, 'Morphing', 'morph_airfoil.m'), ...
         fullfile(here, 'PARSEC', 'fit_parsec_naca2412.m'), ...
         fullfile(here, 'Optimization', 'run_parsec_ga.m')};
xfoilSteps = {fullfile(here, 'Optimization', 'optimize_xfoil_naca.m'), ...
              fullfile(here, 'Optimization', 'optimize_xfoil_parsec.m'), ...
              @() optimize_airfoil('NACA 2412'), ...
              fullfile(here, 'Aerodynamics', 'compare_approaches.m'), ...
              fullfile(here, 'Morphing', 'morph_to_design.m')};

exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(here, 'Aerodynamics', 'xfoil.exe'); end
if isfile(exe)
    setenv('XFOIL_EXE', exe);
    steps = [steps, xfoilSteps];
else
    warning('XFOIL not found (%s): skipping the aerodynamic steps.', exe);
end
steps = [steps, {fullfile(here, 'make_report_figures.m'), fullfile(here, 'Aerodynamics', 'plot_polars.m')}];

for k = 1:numel(steps)
    runStep(steps{k});
end
end

function runStep(step)
% Runs one script in its own workspace (the scripts start with "clear"),
% or calls a function handle
if isa(step, 'function_handle')
    fprintf('\n=== %s\n', func2str(step));
    step();
else
    fprintf('\n=== %s\n', step);
    run(step);
end
close all;
end
