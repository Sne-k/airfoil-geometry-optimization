function T = benchmark_xoptfoil2(x2exe, nRuns, outDir)
%BENCHMARK_XOPTFOIL2  optimize_airfoil against Xoptfoil2 on the same task.
%   T = BENCHMARK_XOPTFOIL2(x2exe) runs Xoptfoil2 (x2exe: path of
%   xoptfoil2.exe, version 2.0.0, https://github.com/jxjo/Xoptfoil2) three
%   times on results/xoptfoil2/naca2412_weighted.xo2 with the seed
%   results/xoptfoil2/NACA2412.dat: CL/CD at CL = 0.4 (weight 0.2) and 1.0
%   (weight 0.8), t/c >= 12 %. Its designs, the three optimize_airfoil
%   designs of the same task in the paper batch (NACA_2412_weighted_s1..s3)
%   and NACA 2412 are then analysed with one protocol: XFOIL, Re = 10^6,
%   alpha from -2 to 18 deg in 0.5 deg steps, 160 panel nodes, the friction
%   floor and the rule against false solutions of the population study
%   (consensusPolar: exact and rounded coordinates, 200 nodes where they
%   disagree); the optimize_airfoil designs at their exact CST coordinates.
%   The curvature of every design is
%   measured like the curvature limits (12th-order CST fit of the
%   coordinates; reversals counted with thresholds 0.01 and 0.1).
%   T = BENCHMARK_XOPTFOIL2(x2exe, nRuns, outDir) sets the number of
%   Xoptfoil2 runs and the output folder (default results/paper); the table
%   is written to xoptfoil2_benchmark.csv there. With x2exe empty, the
%   Xoptfoil2 designs of an earlier call (MATLAB/output/xoptfoil2_benchmark)
%   are analysed again, with the run times of the table in outDir.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'Optimization'), fullfile(root, 'NACA2412'));
if nargin < 2 || isempty(nRuns), nRuns = 3; end
if nargin < 3 || isempty(outDir), outDir = fullfile(root, '..', 'results', 'paper'); end
if ~exist(outDir, 'dir'), mkdir(outDir); end
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end
x2dir = fullfile(root, '..', 'results', 'xoptfoil2');
work = fullfile(root, 'output', 'xoptfoil2_benchmark');

designs = {'NACA 2412', 'NACA 2412', NaN};
if isempty(x2exe)                                    % analyse the designs of an earlier call again
    old = readtable(fullfile(outDir, 'xoptfoil2_benchmark.csv'), 'TextType', 'char');
    for k = 1:nRuns
        name = sprintf('Xoptfoil2 run %d', k);
        designs(end+1, :) = {name, fullfile(work, sprintf('run%d', k), sprintf('X2_run%d.dat', k)), ...
            old.run_time_min(strcmp(old.design, name))}; %#ok<AGROW>
    end
end
for k = 1:nRuns * ~isempty(x2exe)
    w = fullfile(work, sprintf('run%d', k));
    if ~exist(w, 'dir'), mkdir(w); end
    copyfile(fullfile(x2dir, 'naca2412_weighted.xo2'), w);
    copyfile(fullfile(x2dir, 'NACA2412.dat'), w);
    prefix = sprintf('X2_run%d', k);
    t0 = tic;
    [status, out] = system(sprintf('cd /d "%s" && "%s" -i naca2412_weighted.xo2 -o %s', w, x2exe, prefix));
    secs = toc(t0);
    fid = fopen(fullfile(w, 'log.txt'), 'w');
    fprintf(fid, '%s', out);
    fclose(fid);
    f = fullfile(w, [prefix '.dat']);
    if status ~= 0 || ~isfile(f)
        warning('benchmark_xoptfoil2:run', 'Xoptfoil2 run %d failed (status %d).', k, status);
        continue;
    end
    copyfile(f, outDir);
    designs(end+1, :) = {sprintf('Xoptfoil2 run %d', k), f, secs / 60}; %#ok<AGROW>
end
paperRuns = fullfile(root, 'output', 'paper');
for s = 1:3
    folder = fullfile(paperRuns, sprintf('NACA_2412_weighted_s%d', s));
    f = fullfile(folder, 'NACA_2412_optimized.dat');
    if isfile(f)
        info = jsondecode(fileread(fullfile(folder, 'run_info.json')));
        r = load(fullfile(folder, 'result.mat'));      % exact CST coordinates
        r = r.result;
        if iscell(r.x), xs = r.x; else, xs = {r.x, r.x}; end
        designs(end+1, :) = {sprintf('optimize_airfoil seed %d', s), {xs{1}, r.yu, xs{2}, r.yl}, info.runTimeSeconds / 60}; %#ok<AGROW>
    end
end

rows = cell(size(designs, 1), 1);
for k = 1:size(designs, 1)
    if iscell(designs{k, 2})
        [xu, yu, xl, yl] = designs{k, 2}{:};
    else
        [xu, yu, xl, yl] = readAirfoil(designs{k, 2});
    end
    [p, pinfo] = consensusPolar(xu, yu, xl, yl, 1e6, exe);
    m = efficiencyMetrics(p);
    v = [efficiencyValue(p, 'LDatCL', 0.4), efficiencyValue(p, 'LDatCL', 1.0), ...
         efficiencyValue(p, 'LDatCL', [0.4 1.0], [0.2 0.8]), m.LDmax, m.E15max, m.CLmax, m.CM0];
    c1 = curvatureOfCoordinates(xu, yu, xl, yl, 0.01);
    c2 = curvatureOfCoordinates(xu, yu, xl, yl, 0.1);
    rows{k} = {designs{k, 1}, designs{k, 3}, v(1), v(2), v(3), v(4), v(5), v(6), v(7), ...
        maxThickness(xu, yu, xl, yl), c1.top, c1.bot, c2.top, c2.bot, c1.teTop, c1.teBot, c1.fitError, ...
        pinfo.sensitivityPercent, pinfo.used};
end
T = cell2table(vertcat(rows{:}), 'VariableNames', {'design', 'run_time_min', 'LD_at_CL_0p4', ...
    'LD_at_CL_1p0', 'weighted_objective', 'LDmax', 'E15max', 'CLmax_160', 'CM0_160', 'tc', ...
    'reversals_top_0p01', 'reversals_bottom_0p01', 'reversals_top_0p1', 'reversals_bottom_0p1', ...
    'te_curvature_top', 'te_curvature_bottom', 'cst12_fit_error', 'sensitivity_percent', 'polar_used'});
writetable(T, fullfile(outDir, 'xoptfoil2_benchmark.csv'));
disp(T);
end

function c = curvatureOfCoordinates(xu, yu, xl, yl, threshold)
% Curvature measures of an airfoil given by coordinates, on a 12th-order
% CST fit (the same definitions as curvatureLimits)
[Au, Al, dte] = cstFit(xu, yu, xl, yl, 12);
iu = xu >= 0;  il = xl >= 0;
c.fitError = max(abs([cstBasis(xu(iu), 12)*Au.' + xu(iu)*dte/2 - yu(iu); ...
                      cstBasis(xl(il), 12)*Al.' - xl(il)*dte/2 - yl(il)]));
x = linspace(0.1, 1, 451)';
kt = cstCurvature(Au, dte, x, 'upper');
kb = cstCurvature(Al, dte, x, 'lower');
c.top = curvatureSegments(kt, threshold);
c.bot = curvatureSegments(kb, threshold);
c.teTop = kt(end);
c.teBot = kb(end);
end

function t = maxThickness(xu, yu, xl, yl)
xs = linspace(0.01, 0.99, 400)';
iu = xu > 0.005;  il = xl > 0.005;
t = max(interp1(xu(iu), yu(iu), xs, 'pchip') - interp1(xl(il), yl(il), xs, 'pchip'));
end
