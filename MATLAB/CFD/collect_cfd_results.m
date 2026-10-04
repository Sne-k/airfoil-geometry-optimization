function collect_cfd_results(runDir, outDir)
%COLLECT_CFD_RESULTS  Tables and figures of the Fluent runs.
%   COLLECT_CFD_RESULTS(runDir, outDir) reads the output folders of
%   timestep_study.m, verify_naca0012.m and run_design_study.m in runDir
%   (default MATLAB/output/cfd, with the folders timestep_study,
%   verification and designs; missing folders are skipped) and writes to
%   outDir (default results/cfd):
%     timestep_study/   forces.csv, history.csv, meshes.csv,
%                       timestep_history.png
%     verification/     forces.csv, history.csv, meshes.csv, run_info.json,
%                       comparison.csv (against the three codes of the NASA
%                       Turbulence Modeling Resource, read from
%                       reference_tmr.csv in that folder),
%                       grid_convergence.csv (Celik et al. 2008),
%                       farfield.csv, surface.csv (pressure and skin
%                       friction on the airfoil), surface_comparison.csv
%                       (against the CFL3D distributions in the folder
%                       reference), verification_forces.png,
%                       grid_convergence.png, farfield.png,
%                       verification_surface.png
%     designs/          forces.csv, history.csv, meshes.csv, run_info.json,
%                       comparison.csv (against XFOIL, if xfoil.csv from
%                       design_study_xfoil.m is in that folder),
%                       peaks.csv, design_polars.png, design_gains.png
%   A run counts as steady if, over its last force reports (500 iterations
%   in the NACA 0012 runs, 1000 in the design study), CL varies by less
%   than 1e-4 and CD by less than 1e-5. The tables give the mean over those
%   reports as well as the last value. Run times and file names of the
%   transcripts are left out.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(here);
if nargin < 1 || isempty(runDir), runDir = fullfile(root, 'output', 'cfd'); end
if nargin < 2 || isempty(outDir), outDir = fullfile(root, '..', 'results', 'cfd'); end
tol = struct('CL', 1e-4, 'CD', 1e-5);
if isfile(fullfile(runDir, 'timestep_study', 'verification_forces.csv'))
    timestepStudy(fullfile(runDir, 'timestep_study'), fullfile(outDir, 'timestep_study'), tol);
end
if isfile(fullfile(runDir, 'verification', 'forces.csv'))
    verification(fullfile(runDir, 'verification'), fullfile(outDir, 'verification'), tol, ...
        fullfile(root, '..', 'results', 'validation', 'experimental', 'CLCD_Ladson_expdata.dat'));
end
if isfile(fullfile(runDir, 'designs', 'forces.csv'))
    designs(fullfile(runDir, 'designs'), fullfile(outDir, 'designs'), tol);
end
end

%% ------------------------------------------------------------------ time-step study
function timestepStudy(in, out, tol)
if ~exist(out, 'dir'), mkdir(out); end
T = readtable(fullfile(in, 'verification_forces.csv'));
H = readtable(fullfile(in, 'verification_history.csv'));
copyfile(fullfile(in, 'meshes.csv'), fullfile(out, 'meshes.csv'));
% This batch recorded the planned iteration of each force report; the
% iteration that Fluent printed is read from the transcripts (a first-order
% stage can end early when all residuals are below the criteria)
for t = unique(H.transcript)'
    [~, ~, it] = fluentForces(fullfile(in, t{1}));
    rows = find(strcmp(H.transcript, t{1}));
    H.iteration(rows) = it(1:numel(rows));
end
resNames = {'continuity', 'x_velocity', 'y_velocity', 'energy', 'k', 'omega'};
res = nan(height(T), numel(resNames));
its = nan(height(T), 1);
for i = 1:height(T)
    h = H(strcmp(H.run, T.run{i}) & H.alpha == T.alpha(i), :);
    its(i) = max(h.iteration);
    R = fluentResiduals(fullfile(in, T.transcript{i}));
    j = find(R.iter == its(i), 1);
    for c = 1:numel(resNames), res(i, c) = R.(resNames{c})(j); end
end
F = T(:, {'run', 'setting', 'mesh', 'alpha'});
F.iterations = its;
F = [F, T(:, {'CL', 'CD', 'CL_mean', 'CD_mean', 'CL_range', 'CD_range'})];
F.steady = T.CL_range <= tol.CL & T.CD_range <= tol.CD;
F = [F, array2table(res, 'VariableNames', strcat('res_', resNames))];
writetable(F, fullfile(out, 'forces.csv'));
writetable(H(:, {'run', 'setting', 'mesh', 'alpha', 'iteration', 'order', 'CL', 'CD'}), fullfile(out, 'history.csv'));

% Force histories: fine mesh at 10 deg, and 15 deg on the medium mesh
f = figure('Color', 'w', 'Position', [80 80 1150 430], 'Visible', 'off');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;  hold on;  box on;  grid on;
sel = {'r05A', 'automatic time step'; 'r12F', 'automatic, differentiable limiter'; 'r07B', 'fixed time step'};
for k = 1:size(sel, 1)
    h = H(strcmp(H.run, sel{k, 1}) & H.order == 2, :);
    plot(h.iteration, h.CD, '-', 'LineWidth', 1.2, 'DisplayName', sel{k, 2});
end
xlabel('iteration');  ylabel('C_D');  title('Fine mesh, \alpha = 10\circ');
ylim([0.010 0.022]);  legend('Location', 'northeast');
nexttile;  hold on;  box on;  grid on;
sel = {'r08A', 'automatic time step, direct start'; 'r09B', 'fixed time step, direct start'};
for k = 1:size(sel, 1)
    h = H(strcmp(H.run, sel{k, 1}) & H.order == 2, :);
    plot(h.iteration, h.CL, '-', 'LineWidth', 1.2, 'DisplayName', sel{k, 2});
end
h = H(strcmp(H.run, 'r10C') & H.alpha == 15, :);
plot(h.iteration - h.iteration(1) + 450, h.CL, '--', 'LineWidth', 1.2, ...
    'DisplayName', 'automatic time step, continued from 14\circ');
xlabel('iteration (continuation: iterations at 15\circ)');  ylabel('C_L');
title('Medium mesh, \alpha = 15\circ');  legend('Location', 'southeast');
exportgraphics(f, fullfile(out, 'timestep_history.png'), 'Resolution', 130);
close(f);
end

%% ------------------------------------------------------------------ verification
function verification(in, out, tol, ladsonFile)
if ~exist(out, 'dir'), mkdir(out); end
T = readtable(fullfile(in, 'forces.csv'));
H = readtable(fullfile(in, 'history.csv'));
M = readtable(fullfile(in, 'meshes.csv'));
ref = readtable(fullfile(out, 'reference_tmr.csv'));
copyfile(fullfile(in, 'meshes.csv'), fullfile(out, 'meshes.csv'));
if isfile(fullfile(in, 'run_info.json')), copyfile(fullfile(in, 'run_info.json'), fullfile(out, 'run_info.json')); end

[~, im] = ismember(T.mesh, M.mesh);
F = T(:, {'mesh', 'alpha'});
F.far_field_chords = M.far_field_chords(im);
F.cells = M.cells(im);
F.iterations = arrayfun(@(i) max(H.iteration(strcmp(H.mesh, T.mesh{i}) & H.alpha == T.alpha(i))), (1:height(T))');
F = [F, T(:, {'CL', 'CD', 'CL_mean', 'CD_mean', 'CL_range', 'CD_range'})];
F.steady = T.CL_range <= tol.CL & T.CD_range <= tol.CD;
F = [F, T(:, {'res_continuity', 'res_x_velocity', 'res_y_velocity', 'res_energy', 'res_k', 'res_omega'})];
F = sortrows(F, {'far_field_chords', 'cells', 'alpha'}, {'descend', 'ascend', 'ascend'});
writetable(F, fullfile(out, 'forces.csv'));
writetable(H(:, {'mesh', 'alpha', 'iteration', 'order', 'CL', 'CD'}), fullfile(out, 'history.csv'));

% Against the three codes of the Turbulence Modeling Resource
codes = unique(ref.code, 'stable');
C = cell(0, 8);
for i = 1:height(F)
    for c = 1:numel(codes)
        r = ref(strcmp(ref.code, codes{c}) & ref.alpha == F.alpha(i), :);
        if isempty(r), continue; end
        if r.CL == 0, dcl = NaN; else, dcl = 100 * (F.CL(i) - r.CL) / r.CL; end
        C(end+1, :) = {F.mesh{i}, F.alpha(i), codes{c}, r.CL, r.CD, F.CL(i) - r.CL, dcl, 100 * (F.CD(i) - r.CD) / r.CD}; %#ok<AGROW>
    end
end
C = cell2table(C, 'VariableNames', {'mesh', 'alpha', 'code', 'CL_reference', 'CD_reference', 'CL_difference', ...
    'CL_difference_percent', 'CD_difference_percent'});
writetable(C, fullfile(out, 'comparison.csv'));

% Mesh convergence (far field 500 chords away)
get = @(mesh, a, q) F.(q)(strcmp(F.mesh, mesh) & F.alpha == a);
cells = [M.cells(strcmp(M.mesh, 'fine')), M.cells(strcmp(M.mesh, 'medium')), M.cells(strcmp(M.mesh, 'coarse'))];
G = cell(0, 15);
for a = unique(F.alpha)'
    for q = {'CL', 'CD'}
        phi = [get('fine', a, q{1}), get('medium', a, q{1}), get('coarse', a, q{1})];
        if numel(phi) < 3 || (strcmp(q{1}, 'CL') && a == 0), continue; end
        g = gridConvergence(phi, cells);
        G(end+1, :) = {a, q{1}, phi(3), phi(2), phi(1), g.r32, g.r21, g.kind, g.order, g.extrapolated, ...
            100 * g.gciFine, 100 * g.gciMedium, 100 * g.errMedium, 100 * g.errCoarse, g.asymptotic}; %#ok<AGROW>
    end
end
G = cell2table(G, 'VariableNames', {'alpha', 'quantity', 'coarse', 'medium', 'fine', 'ratio_coarse_medium', ...
    'ratio_medium_fine', 'convergence', 'apparent_order', 'extrapolated', 'GCI_fine_percent', 'GCI_medium_percent', ...
    'medium_minus_extrapolated_percent', 'coarse_minus_extrapolated_percent', 'asymptotic_ratio'});
writetable(G, fullfile(out, 'grid_convergence.csv'));

% Far-field distance (resolution of the medium mesh, alpha = 10 deg)
D = F(F.alpha == 10 & ismember(F.mesh, {'medium', 'R100', 'R20'}), {'mesh', 'far_field_chords', 'cells', 'CL', 'CD'});
D = sortrows(D, 'far_field_chords');
if any(D.far_field_chords == 500)
    base = D(D.far_field_chords == 500, :);
    D.CL_difference_percent = 100 * (D.CL - base.CL) / base.CL;
    D.CD_difference = D.CD - base.CD;
    D.CD_difference_percent = 100 * D.CD_difference / base.CD;
    D.CD_difference_times_distance = D.CD_difference .* D.far_field_chords;
end
writetable(D, fullfile(out, 'farfield.csv'));

% Pressure and skin friction on the airfoil, against CFL3D (897 x 257 grid)
T0 = 288.15;  Rgas = 8314.47 / 28.966;                 % as in fluentJournal
qInf = 0.5 * (101325 / (Rgas * T0)) * (0.15 * sqrt(1.4 * Rgas * T0))^2;
S = cell(0, 1);
for i = 1:height(T)
    prof = fullfile(in, strrep(T.transcript{i}, '.out', '.prof'));
    wallFile = fullfile(in, ['n0012_' T.mesh{i} '_wall.csv']);
    if ~isfile(prof) || ~isfile(wallFile), continue; end
    s = fluentSurface(prof, readmatrix(wallFile), qInf);
    s.mesh = repmat(T.mesh(i), height(s), 1);
    s.alpha = repmat(T.alpha(i), height(s), 1);
    S{end+1, 1} = s(:, {'mesh', 'alpha', 'surface', 'x', 'y', 'cp', 'cf'}); %#ok<AGROW>
end
S = vertcat(S{:});
refDir = fullfile(out, 'reference');
if ~isempty(S) && isfile(fullfile(refDir, 'n0012cf_cfl3d_sst.dat'))
    writetable(S, fullfile(out, 'surface.csv'));
    cfRef = readZones(fullfile(refDir, 'n0012cf_cfl3d_sst.dat'));     % upper surface, alpha 0, 10, 15
    cpRef = readZones(fullfile(refDir, 'n0012cp_cfl3d_sst.dat'));
    refAlpha = @(Z) cellfun(@(n) sscanf(n, 'alpha=%f'), {Z.name});
    Q = cell(0, 7);
    for mesh = unique(S.mesh, 'stable')'
        for a = unique(S.alpha(strcmp(S.mesh, mesh{1})))'
            u = sortrows(S(strcmp(S.mesh, mesh{1}) & S.alpha == a & strcmp(S.surface, 'upper'), :), 'x');
            zf = cfRef(refAlpha(cfRef) == a);  zp = cpRef(refAlpha(cpRef) == a);
            if isempty(zf) || isempty(zp) || isempty(u), continue; end
            in95 = u.x >= 0.05 & u.x <= 0.95;
            [xr, k] = unique(zf.data(:, 1));
            cfC = interp1(xr, zf.data(k, 2), u.x(in95));
            Q(end+1, :) = {mesh{1}, a, min(u.cp), min(zp.data(:, 2)), 100 * mean(abs(u.cf(in95) - cfC) ./ cfC), ...
                100 * max(abs(u.cf(in95) - cfC) ./ cfC), sum(in95)}; %#ok<AGROW>
        end
    end
    Q = cell2table(Q, 'VariableNames', {'mesh', 'alpha', 'cp_min', 'cp_min_CFL3D', ...
        'cf_upper_mean_difference_percent', 'cf_upper_max_difference_percent', 'points_x_0p05_to_0p95'});
    writetable(Q, fullfile(out, 'surface_comparison.csv'));

    angles = unique(S.alpha(strcmp(S.mesh, 'medium')))';
    if ~isempty(angles)
        f = figure('Color', 'w', 'Position', [60 60 400 * numel(angles) 720], 'Visible', 'off');
        tiledlayout(2, numel(angles), 'TileSpacing', 'compact', 'Padding', 'compact');
        for row = 1:2
            for a = angles
                nexttile;  hold on;  box on;  grid on;
                m = S(strcmp(S.mesh, 'medium') & S.alpha == a, :);
                if row == 1
                    zp = cpRef(refAlpha(cpRef) == a);
                    plot(zp.data(:, 1), zp.data(:, 2), 'k-', 'LineWidth', 1.0, 'DisplayName', 'CFL3D (NASA TMR)');
                    plot(m.x, m.cp, '.', 'Color', [0.85 0.33 0.10], 'MarkerSize', 7, 'DisplayName', 'Fluent, medium mesh');
                    set(gca, 'YDir', 'reverse');  ylabel('C_p');  title(sprintf('\\alpha = %g\\circ', a));
                    if a == angles(1), legend('Location', 'southeast'); end
                else
                    zf = cfRef(refAlpha(cfRef) == a);
                    u = sortrows(m(strcmp(m.surface, 'upper'), :), 'x');
                    plot(zf.data(:, 1), zf.data(:, 2), 'k-', 'LineWidth', 1.0);
                    plot(u.x, u.cf, '.', 'Color', [0.85 0.33 0.10], 'MarkerSize', 7);
                    ylabel('C_f, upper surface');  ylim([-0.002 0.03]);
                end
                xlabel('x / c');  xlim([0 1]);
            end
        end
        exportgraphics(f, fullfile(out, 'verification_surface.png'), 'Resolution', 130);
        close(f);
    end
end

% Figures
col = lines(7);
mk = struct('CFL3D', 's', 'FUN3D', 'd', 'NTS', '^');
f = figure('Color', 'w', 'Position', [80 80 1150 440], 'Visible', 'off');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile;  hold on;  box on;  grid on;
ax2 = nexttile;  hold on;  box on;  grid on;
if isfile(ladsonFile)
    Z = readZones(ladsonFile);
    for k = 1:numel(Z)
        plot(ax1, Z(k).data(:, 1), Z(k).data(:, 2), '.', 'Color', [0.6 0.6 0.6], 'MarkerSize', 9, 'HandleVisibility', 'off');
        if k == 1, vis = 'on'; else, vis = 'off'; end
        plot(ax2, Z(k).data(:, 2), Z(k).data(:, 3), '.', 'Color', [0.6 0.6 0.6], 'MarkerSize', 9, ...
            'DisplayName', 'Ladson (1988), tripped', 'HandleVisibility', vis);
    end
end
for c = 1:numel(codes)
    r = ref(strcmp(ref.code, codes{c}), :);
    plot(ax1, r.alpha, r.CL, mk.(codes{c}), 'Color', 'k', 'MarkerSize', 9, 'HandleVisibility', 'off');
    plot(ax2, r.CL, r.CD, mk.(codes{c}), 'Color', 'k', 'MarkerSize', 9, 'DisplayName', [codes{c} ' (NASA TMR)']);
end
names = {'coarse', 'medium', 'fine'};
for k = 1:3
    r = sortrows(F(strcmp(F.mesh, names{k}), :), 'alpha');
    plot(ax1, r.alpha, r.CL, 'o', 'Color', col(k, :), 'MarkerFaceColor', col(k, :), 'MarkerSize', 5, 'HandleVisibility', 'off');
    plot(ax2, r.CL, r.CD, 'o', 'Color', col(k, :), 'MarkerFaceColor', col(k, :), 'MarkerSize', 5, ...
        'DisplayName', ['Fluent, ' names{k} ' mesh']);
end
xlabel(ax1, '\alpha (deg)');  ylabel(ax1, 'C_L');  xlim(ax1, [-1 17]);
xlabel(ax2, 'C_L');  ylabel(ax2, 'C_D');  xlim(ax2, [-0.1 1.7]);  ylim(ax2, [0.006 0.026]);
legend(ax2, 'Location', 'northwest');
title(ax1, 'NACA 0012, SST, M = 0.15, Re = 6 \times 10^6');
exportgraphics(f, fullfile(out, 'verification_forces.png'), 'Resolution', 130);
close(f);

if ~isempty(G)
    angles = unique(G.alpha(strcmp(G.quantity, 'CD')))';
    f = figure('Color', 'w', 'Position', [80 80 380 * numel(angles) 400], 'Visible', 'off');
    tiledlayout(1, numel(angles), 'TileSpacing', 'compact', 'Padding', 'compact');
    for a = angles
        nexttile;  hold on;  box on;  grid on;
        g = G(G.alpha == a & strcmp(G.quantity, 'CD'), :);
        hh = 1 ./ sqrt(cells);                              % fine, medium, coarse
        plot(hh / hh(1), [g.fine, g.medium, g.coarse], 'o-', 'Color', col(1, :), 'MarkerFaceColor', col(1, :), ...
            'DisplayName', 'Fluent');
        plot(0, g.extrapolated, 'p', 'Color', col(1, :), 'MarkerSize', 11, 'DisplayName', 'extrapolated');
        for c = 1:numel(codes)
            r = ref(strcmp(ref.code, codes{c}) & ref.alpha == a, :);
            yline(r.CD, ':', codes{c}, 'Color', [0.3 0.3 0.3], 'HandleVisibility', 'off', 'LabelHorizontalAlignment', 'left');
        end
        xlabel('cell size / cell size of the fine mesh');  ylabel('C_D');  xlim([-0.1 2.2]);
        title(sprintf('\\alpha = %g\\circ', a));
        if a == angles(1), legend('Location', 'northwest'); end
    end
    exportgraphics(f, fullfile(out, 'grid_convergence.png'), 'Resolution', 130);
    close(f);
end

if height(D) > 1 && any(D.far_field_chords == 500)
    f = figure('Color', 'w', 'Position', [80 80 560 420], 'Visible', 'off');
    hold on;  box on;  grid on;
    plot(1 ./ D.far_field_chords, D.CD, 'o-', 'Color', col(1, :), 'MarkerFaceColor', col(1, :));
    text(1 ./ D.far_field_chords + 0.001, D.CD, compose('  %g chords', D.far_field_chords), 'VerticalAlignment', 'top');
    xlabel('1 / distance of the far field (chords^{-1})');  ylabel('C_D');
    title('NACA 0012, \alpha = 10\circ: effect of the domain size');  xlim([0 0.06]);
    exportgraphics(f, fullfile(out, 'farfield.png'), 'Resolution', 130);
    close(f);
end
end

%% ------------------------------------------------------------------ design study
function designs(in, out, tol)
if ~exist(out, 'dir'), mkdir(out); end
T = readtable(fullfile(in, 'forces.csv'));
H = readtable(fullfile(in, 'history.csv'));
copyfile(fullfile(in, 'meshes.csv'), fullfile(out, 'meshes.csv'));
if isfile(fullfile(in, 'run_info.json')), copyfile(fullfile(in, 'run_info.json'), fullfile(out, 'run_info.json')); end

F = T(:, {'model', 'design', 'alpha'});
F.iterations = arrayfun(@(i) max(H.iteration(strcmp(H.model, T.model{i}) & strcmp(H.design, T.design{i}) & ...
    H.alpha == T.alpha(i))), (1:height(T))');
F = [F, T(:, {'CL', 'CD', 'CL_mean', 'CD_mean', 'CL_range', 'CD_range'})];
F.steady = T.CL_range <= tol.CL & T.CD_range <= tol.CD;
F.LD = T.CL_mean ./ T.CD_mean;                       % from the means over the last reports
F.Tu_1chord_percent = T.Tu_probe_1;                  % one chord upstream of the leading edge
F.Tu_quarter_chord_percent = T.Tu_probe_2;
F.viscosity_ratio_1chord = T.visc_ratio_probe_1;
F.Ncrit_equivalent = -8.43 - 2.4 * log(T.Tu_probe_1 / 100);     % Mack's relation
F = [F, T(:, {'res_continuity', 'res_x_velocity', 'res_y_velocity', 'res_energy', 'res_k', 'res_omega', ...
    'res_intermit', 'res_retheta'})];
F = sortrows(F, {'model', 'design', 'alpha'});
writetable(F, fullfile(out, 'forces.csv'));
writetable(H(:, {'model', 'design', 'alpha', 'iteration', 'order', 'CL', 'CD'}), fullfile(out, 'history.csv'));

order = {'naca2412', 'smooth_s1', 'wavy_s1', 'parsec_t12'};
label = struct('naca2412', 'NACA 2412', 'smooth_s1', 'optimised, smooth', 'wavy_s1', 'optimised, no curvature limits', ...
    'parsec_t12', 'PARSEC design');
pairs = {'transition', 'free'; 'sst', 'tripped'};    % CFD model and the XFOIL condition it is compared with
hasX = isfile(fullfile(out, 'xfoil.csv'));
if hasX, X = readtable(fullfile(out, 'xfoil.csv')); end

% CFD against XFOIL at the same angles
if hasX
    C = cell(0, 12);
    for i = 1:height(F)
        cond = pairs{strcmp(pairs(:, 1), F.model{i}), 2};
        x = X(strcmp(X.condition, cond) & strcmp(X.design, F.design{i}) & abs(X.alpha - F.alpha(i)) < 1e-9, :);
        if isempty(x) || isnan(x.CL), continue; end
        C(end+1, :) = {F.model{i}, F.design{i}, F.alpha(i), F.CL_mean(i), F.CD_mean(i), F.LD(i), x.CL, x.CD, x.CL / x.CD, ...
            100 * (F.CL_mean(i) - x.CL) / x.CL, 100 * (F.CD_mean(i) - x.CD) / x.CD, 100 * (F.LD(i) - x.CL / x.CD) / (x.CL / x.CD)}; %#ok<AGROW>
    end
    C = cell2table(C, 'VariableNames', {'model', 'design', 'alpha', 'CL_cfd', 'CD_cfd', 'LD_cfd', 'CL_xfoil', 'CD_xfoil', ...
        'LD_xfoil', 'CL_difference_percent', 'CD_difference_percent', 'LD_difference_percent'});
    writetable(C, fullfile(out, 'comparison.csv'));
end

% Best CL/CD over the angles that were run, and the gain over NACA 2412
P = cell(0, 8);
for m = 1:size(pairs, 1)
    for src = {'cfd', 'xfoil'}
        if strcmp(src{1}, 'xfoil') && ~hasX, continue; end
        best = nan(numel(order), 3);
        for k = 1:numel(order)
            f = F(strcmp(F.model, pairs{m, 1}) & strcmp(F.design, order{k}), :);
            if isempty(f), continue; end
            if strcmp(src{1}, 'cfd')
                a = f.alpha;  ld = f.LD;  cl = f.CL_mean;
            else                                          % XFOIL at the angles of the CFD runs
                x = X(strcmp(X.condition, pairs{m, 2}) & strcmp(X.design, order{k}) & ismember(round(X.alpha, 6), round(f.alpha, 6)), :);
                a = x.alpha;  ld = x.CL ./ x.CD;  cl = x.CL;
            end
            [v, j] = max(ld);
            if ~isempty(j), best(k, :) = [v, a(j), cl(j)]; end
        end
        for k = 1:numel(order)
            if strcmp(src{1}, 'cfd'), method = pairs{m, 1}; else, method = ['xfoil_' pairs{m, 2}]; end
            n = sum(strcmp(F.model, pairs{m, 1}) & strcmp(F.design, order{k}));
            P(end+1, :) = {method, order{k}, n, best(k, 1), best(k, 2), best(k, 3), 100 * (best(k, 1) / best(1, 1) - 1), ...
                all(F.steady(strcmp(F.model, pairs{m, 1}) & strcmp(F.design, order{k})))}; %#ok<AGROW>
        end
    end
end
P = cell2table(P, 'VariableNames', {'method', 'design', 'angles', 'best_LD', 'alpha_best', 'CL_best', ...
    'gain_over_naca2412_percent', 'all_cfd_runs_steady'});
writetable(P, fullfile(out, 'peaks.csv'));

% Figures
col = lines(numel(order));
f = figure('Color', 'w', 'Position', [60 60 1250 820], 'Visible', 'off');
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
qty = {'CL', 'CD', 'LD'};  ylab = {'C_L', 'C_D', 'C_L / C_D'};
for m = 1:size(pairs, 1)
    for q = 1:3
        nexttile;  hold on;  box on;  grid on;
        for k = 1:numel(order)
            if hasX
                x = sortrows(X(strcmp(X.condition, pairs{m, 2}) & strcmp(X.design, order{k}) & X.alpha >= -0.01 & X.alpha <= 8.01, :), 'alpha');
                xv = struct('CL', x.CL, 'CD', x.CD, 'LD', x.CL ./ x.CD);
                plot(x.alpha, xv.(qty{q}), '-', 'Color', col(k, :), 'LineWidth', 1.1, 'HandleVisibility', 'off');
            end
            c = sortrows(F(strcmp(F.model, pairs{m, 1}) & strcmp(F.design, order{k}), :), 'alpha');
            cv = struct('CL', c.CL_mean, 'CD', c.CD_mean, 'LD', c.LD);
            plot(c.alpha, cv.(qty{q}), 'o', 'Color', col(k, :), 'MarkerFaceColor', col(k, :), 'MarkerSize', 5, ...
                'DisplayName', label.(order{k}));
        end
        xlabel('\alpha (deg)');  ylabel(ylab{q});
        if q == 1
            if m == 1, title('Transition SST (symbols) and XFOIL, free transition (lines)');
            else, title('SST, fully turbulent (symbols) and XFOIL, tripped (lines)'); end
            legend('Location', 'northwest');
        end
    end
end
exportgraphics(f, fullfile(out, 'design_polars.png'), 'Resolution', 130);
close(f);

f = figure('Color', 'w', 'Position', [80 80 760 430], 'Visible', 'off');
methods = unique(P.method, 'stable');
V = nan(numel(order), numel(methods));
for j = 1:numel(methods)
    for k = 1:numel(order)
        v = P.best_LD(strcmp(P.method, methods{j}) & strcmp(P.design, order{k}));
        if ~isempty(v), V(k, j) = v; end
    end
end
bar(V);  box on;  grid on;
set(gca, 'XTickLabel', cellfun(@(d) label.(d), order, 'UniformOutput', false));
ylabel('best C_L / C_D over the angles run');
legend(strrep(methods, '_', ' '), 'Location', 'northwest');
exportgraphics(f, fullfile(out, 'design_gains.png'), 'Resolution', 130);
close(f);
end

%% ------------------------------------------------------------------ helpers
function Z = readZones(file)
% Zones of a Tecplot-style text file from the NASA Turbulence Modeling
% Resource: struct array with the fields name and data
Z = struct('name', {}, 'data', {});
fid = fopen(file, 'r');
cleaner = onCleanup(@() fclose(fid));
while true
    line = fgetl(fid);
    if ~ischar(line), break; end
    line = strtrim(line);
    if isempty(line) || line(1) == '#' || startsWith(lower(line), 'variables'), continue; end
    if startsWith(lower(line), 'zone')
        name = regexp(line, '"([^"]*)"', 'tokens', 'once');
        if isempty(name), name = {''}; end
        Z(end+1) = struct('name', name{1}, 'data', zeros(0, 3)); %#ok<AGROW>
        continue;
    end
    v = sscanf(line, '%f')';
    if isempty(v), continue; end
    if isempty(Z), Z(1) = struct('name', '', 'data', zeros(0, numel(v))); end
    if isempty(Z(end).data), Z(end).data = zeros(0, numel(v)); end
    if numel(v) == size(Z(end).data, 2), Z(end).data(end+1, :) = v; end
end
end
