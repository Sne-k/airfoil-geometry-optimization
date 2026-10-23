% Alternative to step (b): an established tool on the benchmark airfoils. Xoptfoil2 cannot express the
% free+tripped task, so the comparison uses the task it can express closest: peak CL/CD, free transition
% (Ncrit 9), Re 1e6, t/c kept (Xoptfoil2: min_thickness = original t/c - 0.0005, as its own Bezier fit of
% the seed is slightly thinner). Three methods, three runs each, on the six held-out airfoils:
%   GA -> fmincon: the existing 'peak' runs of the population study (population_runs/<tag>_peak_s<k>);
%   surrogate (v5 code, model A, free transition), warm-started like the benchmark;
%   Xoptfoil2 2.0.0 with its default Bezier shapes, particle swarm and automatic curvature control
%   (leading-edge check off, as in the NACA 2412 benchmark). Same start and smoothness rule as ours: its
%   seed is the order-6 CST fit of the original that optimize_airfoil starts from (10 decimals), and it
%   may have as many curvature reversals per surface as the curvature limits of optimize_airfoil allow
%   (counts of the fitted original, population_runs/<tag>_peak_s1/run_info.json; at most 2, the largest
%   value Xoptfoil2 accepts: Clark Y 1/4 -> 1/2, S1223 0/3 -> 0/2). Thickness: min_thickness and a
%   geometry target at the original t/c (min_thickness alone is not enforced on the result). Bezier
%   points: Xoptfoil2's default 6 per surface; 7 where Xoptfoil2 rejects its fit of the seed
%   (bezier_points.txt in the run folder).
%   Xoptfoil2 has no peak objective: max-glide at CLp - 0.2, CLp, CLp + 0.2 (weights 0.25 / 0.5 / 0.25),
%   CLp = CL at the peak of the original (consensus polar). It has no moment limit; CM is reported.
% Every design is then analysed the same way (consensusPolar, exact coordinates where available).
% Output: peak_compare/peak_compare.csv. Finished runs are skipped.
W = getenv('AIRFOIL_WORK');                         % work folder with the logged runs (MATLAB/Surrogate/README.md)
if isempty(W), error('Surrogate:work', 'Set the environment variable AIRFOIL_WORK (MATLAB/Surrogate/README.md).'); end
here = fileparts(mfilename('fullpath'));  ML = fileparts(here);  repo = fileparts(ML);   % MATLAB/Surrogate, MATLAB, repo
addpath(fullfile(W, 'surrogate'), fullfile(ML, 'Optimization'), ...
    fullfile(ML, 'Aerodynamics'), fullfile(ML, 'NACA2412'), ...
    fullfile(ML, 'Paper'));
exe = fullfile(W, 'tools', 'xfoil.exe');  setenv('XFOIL_EXE', exe);
x2exe = fullfile(W, 'tools', 'xoptfoil2', 'x2', 'xoptfoil2.exe');
out = fullfile(W, 'surrogate', 'peak_compare');
if ~exist(out, 'dir'), mkdir(out); end
airfoils = {'NACA_2412', 'NACA_0012', 'NACA_4415', 'CLARK_Y', 'SD7062', 'S1223'};
rows = cell(0, 9);
for a = airfoils
    tag = a{1};
    src = sourceOf(W, tag);
    [xu, yu, xl, yl] = readAirfoil(src);
    po = consensusPolar(xu, yu, xl, yl, 1e6, exe);
    mo = efficiencyMetrics(po);
    tOrig = maxThickness(xu, yu, xl, yl);
    rows(end+1, :) = {tag, 'original', 0, xu, yu, xl, yl, NaN, NaN}; %#ok<AGROW>
    % seed of Xoptfoil2: the CST fit of the original, and the reversal counts of the curvature limits
    F = readtable(fullfile(W, 'feasibility', 'runs_seed_fit.csv'), 'TextType', 'char');
    F = F(find(startsWith(F.tag, [tag '_']), 1), :);
    xs0 = (1 - cos(linspace(0, pi, 161)')) / 2;
    [ys0u, ys0l] = cstSurfaces(F{1, compose('Au%d', 0:6)}, F{1, compose('Al%d', 0:6)}, F.dte, xs0);
    lim = jsondecode(fileread(fullfile(W, 'population_runs', sprintf('%s_peak_s1', tag), 'run_info.json')));
    rev = min([lim.limits.reversalsTop, lim.limits.reversalsBot], 2);   % Xoptfoil2 accepts 0, 1 or 2 per surface
    for s = 1:3
        % GA -> fmincon (population study)
        r = load(fullfile(W, 'population_runs', sprintf('%s_peak_s%d', tag, s), 'result.mat'));  r = r.result;
        if iscell(r.x), xs = r.x; else, xs = {r.x, r.x}; end
        rows(end+1, :) = {tag, 'GA -> fmincon', s, xs{1}, r.yu, xs{2}, r.yl, r.runInfo.runTimeSeconds / 60, r.runInfo.xfoilAnalysedDesigns}; %#ok<AGROW>
        % surrogate
        d = fullfile(out, sprintf('%s_surrogate_s%d', tag, s));
        if ~isfile(fullfile(d, 'result.mat'))
            try, runSurrogateA(W, tag, src, s, d); catch err, fprintf('[FAILED] surrogate %s s%d: %s\n', tag, s, err.message); end
            close all force;
        end
        if isfile(fullfile(d, 'result.mat'))
            r = load(fullfile(d, 'result.mat'));  r = r.result;
            if iscell(r.x), xs = r.x; else, xs = {r.x, r.x}; end
            rows(end+1, :) = {tag, 'surrogate', s, xs{1}, r.yu, xs{2}, r.yl, r.runInfo.runTimeSeconds / 60, r.runInfo.xfoilAnalysedDesigns}; %#ok<AGROW>
        end
        % Xoptfoil2
        d = fullfile(out, sprintf('%s_xoptfoil2_s%d', tag, s));
        f = fullfile(d, 'X2.dat');
        if ~isfile(f)
            if ~exist(d, 'dir'), mkdir(d); end
            writeSeed(fullfile(d, 'seed.dat'), tag, xs0, ys0u(:), xs0, ys0l(:));
            for ncp = [6 7]                          % Xoptfoil2's default Bezier points; 7 only if it rejects its fit of the seed
                writeXo2(fullfile(d, 'task.xo2'), mo.CL_LD, tOrig - 0.0005, rev, tOrig, ncp);
                t0 = tic;
                [st, txt] = system(sprintf('cd /d "%s" && "%s" -i task.xo2 -o X2', d, x2exe));
                secs = toc(t0);
                fid = fopen(fullfile(d, sprintf('log_ncp%d.txt', ncp)), 'w');  fprintf(fid, '%s', txt);  fclose(fid);
                if isfile(f) || ~contains(txt, 'violates curvature constraints too much'), break; end
            end
            fid = fopen(fullfile(d, 'log.txt'), 'w');  fprintf(fid, '%s', txt);  fclose(fid);
            fid = fopen(fullfile(d, 'bezier_points.txt'), 'w');  fprintf(fid, '%d', ncp);  fclose(fid);
            fid = fopen(fullfile(d, 'run_time_seconds.txt'), 'w');  fprintf(fid, '%.1f', secs);  fclose(fid);
            if st ~= 0 || ~isfile(f), fprintf('[FAILED] xoptfoil2 %s s%d (status %d)\n', tag, s, st); end
        end
        if isfile(f)
            [x1, y1, x2, y2] = readAirfoil(f);
            rows(end+1, :) = {tag, 'Xoptfoil2', s, x1, y1, x2, y2, str2double(fileread(fullfile(d, 'run_time_seconds.txt'))) / 60, NaN}; %#ok<AGROW>
        end
    end
    fprintf('[PEAK COMPARE] %s runs done (CLp %.3f, t/c %.4f)\n', tag, mo.CL_LD, tOrig);
end
% Analysis, one protocol for every design
T = cell(size(rows, 1), 1);
parfor k = 1:size(rows, 1)
    [p, info] = consensusPolar(rows{k, 4}, rows{k, 5}, rows{k, 6}, rows{k, 7}, 1e6, exe);
    v = nan(1, 4);
    if numel(p.alpha) >= 12 && p.alpha(1) <= 0 && p.alpha(end) >= 0
        m = efficiencyMetrics(p);  v = [m.LDmax, m.alphaLD, m.CLmax, m.CM0];
    end
    T{k} = {rows{k, 1}, rows{k, 2}, rows{k, 3}, v(1), v(2), v(3), v(4), maxThickness(rows{k, 4}, rows{k, 5}, rows{k, 6}, rows{k, 7}), ...
        rows{k, 8}, rows{k, 9}, info.sensitivityPercent, info.used};
end
T = cell2table(vertcat(T{:}), 'VariableNames', {'airfoil', 'method', 'run', 'LDmax', 'alpha_LDmax', 'CLmax', 'CM0', 'tc', ...
    'run_time_min', 'xfoil_analysed_designs', 'sensitivity_percent', 'polar_used'});
writetable(T, fullfile(out, 'peak_compare.csv'));
disp(T);
fprintf('[PEAK COMPARE DONE]\n');

function src = sourceOf(W, tag)
if startsWith(tag, 'NACA_'), src = strrep(tag, '_', ' ');
elseif strcmp(tag, 'CLARK_Y'), src = fullfile(ML, 'airfoils', 'clarky.dat');
else, src = fullfile(W, 'refs', 'uiuc', [lower(tag) '.dat']); end
end

function runSurrogateA(W, tag, src, seed, outDir)
R = readtable(fullfile(W, 'feasibility', 'runs_seed_fit.csv'), 'TextType', 'char');
names = [compose('Au%d', 0:6), compose('Al%d', 0:6)];
seedOf = @(t) R{find(startsWith(R.tag, [t '_']), 1), names};
m = jsondecode(fileread(fullfile(here, 'models', 'model_A.json')));
train = setdiff(unique(cellfun(@(t) regexprep(t, '_[a-z0-9]+_s\d+$', ''), R.tag, 'UniformOutput', false)), m.held_out);
C = readtable(fullfile(repo, 'results', 'population', 'cst_coefficients.csv'), 'TextType', 'char');
[~, k] = sort(cellfun(@(t) norm(seedOf(t) - seedOf(tag)), train));
warm = zeros(0, 14);
for t = train(k(1:3)).'
    row = C(strcmp(C.tag, [t{1} '_peak_s1']), :);
    if ~isempty(row), warm(end+1, :) = row{1, names}; end %#ok<AGROW>
end
fprintf('[WARM START] %s from %s\n', tag, strjoin(train(k(1:3)), ', '));
t0 = tic;
r = optimize_airfoil(src, 'Seed', seed, 'Algorithm', 'surrogate', 'SurrogateModel', fullfile(here, 'models', 'model_A.json'), ...
    'WarmStart', warm, 'OutputDir', outDir);
fprintf('[PEAK RUN] %s surrogate seed %d: objective %.2f -> %.2f | XFOIL-analysed designs %d | %.0f s\n', tag, seed, ...
    r.runInfo.objectiveOriginalFit, r.runInfo.objectiveFinal, r.runInfo.xfoilAnalysedDesigns, toc(t0));
end

function writeSeed(f, name, xu, yu, xl, yl)
% Selig format: upper surface from the trailing edge to the leading edge, then the lower surface.
% readAirfoil gives both surfaces from the leading edge; they are not sorted by x, because a cambered
% NACA upper surface reaches slightly ahead of x = 0 and sorting would scramble the nose
xu = flipud(xu(:));  yu = flipud(yu(:));
xl = xl(:);  yl = yl(:);
if xl(1) == xu(end) && yl(1) == yu(end), xl = xl(2:end);  yl = yl(2:end); end
fid = fopen(f, 'w');
fprintf(fid, '%s\n', name);
fprintf(fid, '%13.10f %13.10f\n', [xu yu; xl yl].');
fclose(fid);
end

function writeXo2(f, CLp, tMin, rev, tTarget, ncp)
q = char(39);
fid = fopen(f, 'w');
fprintf(fid, '&optimization_options\n  airfoil_file = %sseed.dat%s\n  shape_functions = %sbezier%s\n  cpu_threads = -1\n  show_details = .false.\n/\n\n', q, q, q, q);
fprintf(fid, '&operating_conditions\n  re_default = 1000000\n  noppoint = 3\n');
cl = CLp + [-0.2 0 0.2];  w = [0.25 0.5 0.25];
for k = 1:3
    fprintf(fid, '  op_point(%d) = %.3f\n  optimization_type(%d) = %smax-glide%s\n  weighting(%d) = %.2f\n', k, cl(k), k, q, q, k, w(k));
end
% leading-edge curvature check off, as in results/xoptfoil2/naca2412_weighted.xo2 (the NACA 2412 seed fails it otherwise)
fprintf(fid, '/\n\n&constraints\n  min_thickness = %.4f\n/\n\n&curvature\n  check_le_curvature = .false.\n  max_curv_reverse_top = %d\n  max_curv_reverse_bot = %d\n/\n\n&xfoil_run_options\n  ncrit = 9\n/\n', tMin, rev(1), rev(2));
% min_thickness alone is not enforced on the result (NACA 4415: 0.135 against 0.1497), so the thickness is also
% a geometry target, as in Xoptfoil2's examples
fprintf(fid, '\n&geometry_targets\n  ngeo_targets = 1\n  target_type(1) = %sThickness%s\n  target_value(1) = %.4f\n/\n', q, q, tTarget);
if ncp ~= 6, fprintf(fid, '\n&bezier_options\n  ncp_top = %d\n  ncp_bot = %d\n/\n', ncp, ncp); end
fclose(fid);
end

function t = maxThickness(xu, yu, xl, yl)
xs = linspace(0.01, 0.99, 400)';
iu = xu > 0.005;  il = xl > 0.005;
[a, i] = unique(xu(iu));  b = yu(iu);  b = b(i);
[c, j] = unique(xl(il));  d = yl(il);  d = d(j);
t = max(interp1(a, b, xs, 'pchip') - interp1(c, d, xs, 'pchip'));
end
