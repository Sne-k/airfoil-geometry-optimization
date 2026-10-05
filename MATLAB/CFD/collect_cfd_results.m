function collect_cfd_results(runDir, outDir)
%COLLECT_CFD_RESULTS  Tables and figures of the Fluent runs.
%   COLLECT_CFD_RESULTS(runDir, outDir) reads the output folders of
%   timestep_study.m, verify_naca0012.m, run_design_study.m and
%   transition_tests.m in runDir (default MATLAB/output/cfd, with the
%   folders timestep_study, verification, designs and transition_tests;
%   missing folders are skipped) and writes to outDir (default results/cfd):
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
%     designs/          forces.csv (with the pressure and the friction
%                       part of the drag, the turbulence intensity reaching
%                       the airfoil and the transition and separation
%                       locations read from the skin friction), history.csv,
%                       meshes.csv, run_info.json, surface.csv,
%                       startup_check.csv (the NASA case repeated with the
%                       start-up of the design study), mesh_check.csv (NACA
%                       2412 at 4 deg on the refined mesh), comparison.csv
%                       (against XFOIL, if xfoil.csv from
%                       design_study_xfoil.m is in that folder), peaks.csv,
%                       cycle_naca2412_a4.csv, transition_cycle.png,
%                       design_polars.png, design_gains.png,
%                       design_surface.png
%     transition_tests/ forces.csv (one row per solver setting), history.csv,
%                       meshes.csv, run_info.json, transition_tests.png
%   A run counts as steady if, over its last force reports (500 iterations
%   in the NACA 0012 runs; 1000 with SST and 2400 with Transition SST in
%   the design study), CL varies by less than 1e-4 and CD by less than
%   1e-5. The Transition SST runs of the design study cycle: their forces
%   are means over the last whole cycles (cycleStatistics), with the lowest
%   and the highest value in those cycles, and their surface data are means
%   over the wall profiles written during those cycles. Run times and file
%   names of the transcripts are left out.

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
if isfile(fullfile(runDir, 'transition_tests', 'forces.csv'))
    transitionTests(fullfile(runDir, 'transition_tests'), fullfile(outDir, 'transition_tests'), tol);
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
get = @(mesh, a, q) F.(q)(strcmp(F.mesh, mesh) & F.alpha == a & F.steady);      % steady solutions only
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
    % Skin friction on the upper surface between x = 0.05 and 0.95: mean and largest
    % difference from CFL3D, as a percentage of CFL3D's mean value over that range
    % (not point by point: near separation the skin friction passes through zero)
    Q = cell(0, 7);
    for mesh = unique(S.mesh, 'stable')'
        for a = unique(S.alpha(strcmp(S.mesh, mesh{1})))'
            if ~F.steady(strcmp(F.mesh, mesh{1}) & F.alpha == a), continue; end
            u = sortrows(S(strcmp(S.mesh, mesh{1}) & S.alpha == a & strcmp(S.surface, 'upper'), :), 'x');
            zf = cfRef(refAlpha(cfRef) == a);  zp = cpRef(refAlpha(cpRef) == a);
            if isempty(zf) || isempty(zp) || isempty(u), continue; end
            in95 = u.x >= 0.05 & u.x <= 0.95;
            [xr, k] = unique(zf.data(:, 1));
            cfC = interp1(xr, zf.data(k, 2), u.x(in95));
            Q(end+1, :) = {mesh{1}, a, min(u.cp), min(zp.data(:, 2)), 100 * mean(abs(u.cf(in95) - cfC)) / mean(cfC), ...
                100 * max(abs(u.cf(in95) - cfC)) / mean(cfC), sum(in95)}; %#ok<AGROW>
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
                    plot(m.x, m.cp, 'o', 'Color', [0.85 0.33 0.10], 'MarkerSize', 3, 'DisplayName', 'Fluent, medium mesh');
                    plot(zp.data(:, 1), zp.data(:, 2), 'k-', 'LineWidth', 0.9, 'DisplayName', 'CFL3D (NASA TMR)');
                    set(gca, 'YDir', 'reverse');  ylabel('C_p');  title(sprintf('\\alpha = %g\\circ', a));
                    if a == angles(1), legend('Location', 'southeast'); end
                else
                    zf = cfRef(refAlpha(cfRef) == a);
                    u = sortrows(m(strcmp(m.surface, 'upper'), :), 'x');
                    plot(u.x, u.cf, 'o', 'Color', [0.85 0.33 0.10], 'MarkerSize', 3);
                    plot(zf.data(:, 1), zf.data(:, 2), 'k-', 'LineWidth', 0.9);
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
    r = sortrows(F(strcmp(F.mesh, names{k}) & F.steady, :), 'alpha');
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
        r = ref(ref.alpha == a, :);
        for v = unique(r.CD)'                               % codes with the same value share a label
            yline(v, ':', strjoin(r.code(r.CD == v), ', '), 'Color', [0.3 0.3 0.3], 'HandleVisibility', 'off', ...
                'LabelHorizontalAlignment', 'right');
        end
        xlabel('cell size / cell size of the fine mesh');  ylabel('C_D');  xlim([-0.1 2.2]);
        title(sprintf('\\alpha = %g\\circ', a));
        if a == angles(1), legend('Location', 'south'); end
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
M = readtable(fullfile(in, 'meshes.csv'));

% Forces. The SST runs settle; the Transition SST runs cycle (the train of separation cells in the
% laminar separation bubble drifts during the iterations), so their forces are means over whole
% cycles, with the lowest and the highest value in those cycles (cycleStatistics).
window = struct('transition', 2400, 'sst', 1000, 'check', 500);
names = {'iterations', 'steady', 'period_iterations', 'period_mismatch', 'cycles_averaged', 'window_iterations', ...
    'window_first_iteration', 'CL', 'CD', 'LD', 'CL_min', 'CL_max', 'CD_min', 'CD_max', 'LD_min', 'LD_max', ...
    'CD_pressure', 'CD_viscous'};
stat = nan(height(T), numel(names));
Hp = cell(height(T), 1);                               % histories with the pressure and viscous parts
for i = 1:height(T)
    file = fullfile(in, T.transcript{i});
    if ~isfile(file), continue; end
    [cd, cl, it, parts] = fluentForces(file);
    h = H(strcmp(H.transcript, T.transcript{i}), :);
    n = min(height(h), numel(cd));
    if n < 3, continue; end
    h = h(1:n, {'model', 'design', 'alpha', 'order'});
    h.iteration = it(1:n);  h.CL = cl(1:n);  h.CD = cd(1:n);
    h = [h, parts(1:n, :)]; %#ok<AGROW>
    Hp{i} = h;
    k = h.order == 2;
    s = cycleStatistics(h.iteration(k), h.CL(k), h.CD(k), 'Window', window.(T.model{i}), 'Tol', [tol.CL tol.CD]);
    p = h(k, :);
    stat(i, :) = [max(h.iteration), s.steady, s.period, s.mismatch, s.cycles, s.window, s.first, s.CL, s.CD, s.LD, ...
        s.CL_min, s.CL_max, s.CD_min, s.CD_max, s.LD_min, s.LD_max, mean(p.CD_pressure(s.use)), mean(p.CD_viscous(s.use))];
end
F = [T(:, {'model', 'design', 'alpha'}), array2table(stat, 'VariableNames', names)];
F.steady = F.steady == 1;
F.Tu_1chord_percent = T.Tu_probe_1;                  % one chord upstream of the leading edge
F.Tu_quarter_chord_percent = T.Tu_probe_2;
F.viscosity_ratio_1chord = T.visc_ratio_probe_1;
F.Ncrit_equivalent = -8.43 - 2.4 * log(T.Tu_probe_1 / 100);     % Mack's relation
F.Ncrit_equivalent(~strcmp(F.model, 'transition')) = NaN;        % has a meaning for the transition model only
F = [F, T(:, {'res_continuity', 'res_x_velocity', 'res_y_velocity', 'res_energy', 'res_k', 'res_omega', ...
    'res_intermit', 'res_retheta'})];

% Pressure and skin friction on the airfoil: the profile at the last iteration and, for the runs
% that cycle, the further profiles written during the averaging window; mean, lowest and highest
% skin friction over these snapshots. Transition and separation are read from the mean skin friction.
T0 = 288.15;  Rgas = 8314.47 / 28.966;                 % as in fluentJournal
qInf = 0.5 * (101325 / (Rgas * T0)) * (0.15 * sqrt(1.4 * Rgas * T0))^2;
loc = nan(height(T), 5);                               % xtr upper, xtr lower, xsep upper, xsep lower, snapshots
S = cell(0, 1);
snap = cell(height(T), 1);                             % per run: iterations, x, surface, cf of every snapshot
sides = {'upper', 'lower'};
for i = 1:height(T)
    tag = strrep(T.transcript{i}, '.out', '');
    wallFile = fullfile(in, [T.design{i} '_wall.csv']);
    if ~isfile(fullfile(in, [tag '.prof'])) || ~isfile(wallFile) || isnan(stat(i, 1)), continue; end
    files = {fullfile(in, [tag '.prof'])};
    its = stat(i, 1);
    d = dir(fullfile(in, [tag '_it*.prof']));
    for k = 1:numel(d)
        v = sscanf(d(k).name(numel(tag)+1:end), '_it%d.prof');
        if ~isempty(v) && v >= F.window_first_iteration(i)
            files{end+1} = fullfile(in, d(k).name);  its(end+1) = v; %#ok<AGROW>
        end
    end
    [its, k] = sort(its);  files = files(k);
    wall = readmatrix(wallFile);
    cf = [];  cp = [];
    for k = 1:numel(files)
        s = fluentSurface(files{k}, wall, qInf);
        cf(:, k) = s.cf;  cp(:, k) = s.cp; %#ok<AGROW>
    end
    s.cp = mean(cp, 2);
    s.cf = mean(cf, 2);
    s.cf_min = min(cf, [], 2);
    s.cf_max = max(cf, [], 2);
    for side = 1:2
        u = s(strcmp(s.surface, sides{side}), :);
        [loc(i, side), loc(i, side + 2)] = transitionFromCf(u.x, u.cf);
    end
    loc(i, 5) = numel(files);
    snap{i} = struct('iteration', its, 'x', s.x, 'surface', {s.surface}, 'cf', cf);
    s.model = repmat(T.model(i), height(s), 1);
    s.design = repmat(T.design(i), height(s), 1);
    s.alpha = repmat(T.alpha(i), height(s), 1);
    S{end+1, 1} = s(:, {'model', 'design', 'alpha', 'surface', 'x', 'y', 'cp', 'cf', 'cf_min', 'cf_max'}); %#ok<AGROW>
end
F.xtr_upper = loc(:, 1);  F.xtr_lower = loc(:, 2);  F.xsep_upper = loc(:, 3);  F.xsep_lower = loc(:, 4);
F.surface_snapshots = loc(:, 5);

% The first run repeats the NASA NACA 0012 case with the start-up of the design study
isCheck = strcmp(F.model, 'check');
if any(isCheck)
    writetable(F(isCheck, {'model', 'design', 'alpha', 'iterations', 'steady', 'CL', 'CD', 'LD', 'CL_min', 'CL_max', ...
        'CD_min', 'CD_max', 'res_continuity', 'res_x_velocity', 'res_y_velocity', 'res_energy', 'res_k', 'res_omega'}), ...
        fullfile(out, 'startup_check.csv'));
end

% NACA 2412 at 4 deg on the refined mesh, against the mesh of the design study
isFine = strcmp(F.design, 'naca2412_fine');
if any(isFine)
    C = cell(0, 13);
    for i = find(isFine)'
        j = find(strcmp(F.model, F.model{i}) & strcmp(F.design, 'naca2412') & F.alpha == F.alpha(i), 1);
        if isempty(j) || isnan(F.CD(i)) || isnan(F.CD(j)), continue; end
        for k = [j i]
            C(end+1, :) = {F.model{k}, F.design{k}, M.cells(strcmp(M.design, F.design{k})), F.alpha(k), F.steady(k), ...
                F.period_iterations(k), F.CL(k), F.CD(k), F.LD(k), F.CD_min(k), F.CD_max(k), ...
                F.xtr_upper(k), 100 * (F.CD(k) - F.CD(i)) / F.CD(i)}; %#ok<AGROW>
        end
    end
    if ~isempty(C)
        C = cell2table(C, 'VariableNames', {'model', 'mesh', 'cells', 'alpha', 'steady', 'period_iterations', 'CL', 'CD', ...
            'LD', 'CD_min', 'CD_max', 'xtr_upper', 'CD_difference_from_fine_percent'});
        writetable(C, fullfile(out, 'mesh_check.csv'));
    end
end

keep = ~isCheck & ~isFine & ~isnan(F.CD);
if ~any(keep), return; end                           % only the start-up check has run so far
F = F(keep, :);
Hp = Hp(keep);
Hp = vertcat(Hp{~cellfun(@isempty, Hp)});
snap = snap(keep);
[F, idx] = sortrows(F, {'model', 'design', 'alpha'});
snap = snap(idx);
writetable(F, fullfile(out, 'forces.csv'));
writetable(Hp(:, {'model', 'design', 'alpha', 'iteration', 'order', 'CL', 'CD', 'CD_pressure', 'CD_viscous'}), ...
    fullfile(out, 'history.csv'));
if ~isempty(S)
    S = vertcat(S{:});
    S = S(~strcmp(S.model, 'check') & ~strcmp(S.design, 'naca2412_fine'), :);
    if ~isempty(S), writetable(S, fullfile(out, 'surface.csv')); end
end

D = designStudyAirfoils();
D = D(ismember(D.name, F.design), :);                % the airfoils that have been run, NACA 2412 first
order = D.name';
label = cell2struct(D.label, D.name, 1);
pairs ={'transition', 'free'; 'sst', 'tripped'};    % CFD model and the XFOIL condition it is compared with
hasX = isfile(fullfile(out, 'xfoil.csv'));
if hasX, X = readtable(fullfile(out, 'xfoil.csv')); end

% CFD against XFOIL at the same angles
if hasX
    C = cell(0, 20);
    for i = 1:height(F)
        cond = pairs{strcmp(pairs(:, 1), F.model{i}), 2};
        x = X(strcmp(X.condition, cond) & strcmp(X.design, F.design{i}) & abs(X.alpha - F.alpha(i)) < 1e-9, :);
        if isempty(x) || isnan(x.CL) || isnan(F.CD(i)), continue; end
        C(end+1, :) = {F.model{i}, F.design{i}, F.alpha(i), F.steady(i), F.CL(i), F.CD(i), F.LD(i), F.LD_min(i), F.LD_max(i), ...
            x.CL, x.CD, x.CL / x.CD, 100 * (F.CL(i) - x.CL) / x.CL, 100 * (F.CD(i) - x.CD) / x.CD, ...
            100 * (F.LD(i) - x.CL / x.CD) / (x.CL / x.CD), F.xtr_upper(i), x.xtrTop, F.xtr_lower(i), x.xtrBot, ...
            F.xsep_upper(i)}; %#ok<AGROW>
    end
    if ~isempty(C)
        C = cell2table(C, 'VariableNames', {'model', 'design', 'alpha', 'steady', 'CL_cfd', 'CD_cfd', 'LD_cfd', 'LD_cfd_min', ...
            'LD_cfd_max', 'CL_xfoil', 'CD_xfoil', 'LD_xfoil', 'CL_difference_percent', 'CD_difference_percent', ...
            'LD_difference_percent', 'xtr_upper_cfd', 'xtr_upper_xfoil', 'xtr_lower_cfd', 'xtr_lower_xfoil', 'xsep_upper_cfd'});
        writetable(C, fullfile(out, 'comparison.csv'));
    end
end

% Best CL/CD over the angles that were run, and the gain over NACA 2412. For CFD the lowest and the
% highest CL/CD within the averaging window at that angle are given as well.
P = cell(0, 10);
for m = 1:size(pairs, 1)
    for src = {'cfd', 'xfoil'}
        if strcmp(src{1}, 'xfoil') && ~hasX, continue; end
        best = nan(numel(order), 5);
        for k = 1:numel(order)
            f = F(strcmp(F.model, pairs{m, 1}) & strcmp(F.design, order{k}) & ~isnan(F.LD), :);
            if isempty(f), continue; end
            if strcmp(src{1}, 'cfd')
                [v, j] = max(f.LD);
                best(k, :) = [v, f.alpha(j), f.CL(j), f.LD_min(j), f.LD_max(j)];
            else                                          % XFOIL at the angles of the CFD runs
                x = X(strcmp(X.condition, pairs{m, 2}) & strcmp(X.design, order{k}) & ...
                    ismember(round(X.alpha, 6), round(f.alpha, 6)), :);
                if isempty(x), continue; end
                [v, j] = max(x.CL ./ x.CD);
                best(k, :) = [v, x.alpha(j), x.CL(j), NaN, NaN];
            end
        end
        for k = 1:numel(order)
            if isnan(best(k, 1)), continue; end           % no runs of this airfoil with this model yet
            if strcmp(src{1}, 'cfd'), method = pairs{m, 1}; else, method = ['xfoil_' pairs{m, 2}]; end
            sel = strcmp(F.model, pairs{m, 1}) & strcmp(F.design, order{k});
            P(end+1, :) = {method, order{k}, sum(sel), best(k, 1), best(k, 2), best(k, 3), best(k, 4), best(k, 5), ...
                100 * (best(k, 1) / best(1, 1) - 1), all(F.steady(sel))}; %#ok<AGROW>
        end
    end
end
P = cell2table(P, 'VariableNames', {'method', 'design', 'angles', 'best_LD', 'alpha_best', 'CL_best', 'LD_min_at_best', ...
    'LD_max_at_best', 'gain_over_naca2412_percent', 'all_cfd_runs_steady'});
writetable(P, fullfile(out, 'peaks.csv'));

% The force cycle of the Transition SST runs, shown for NACA 2412 at 4 deg: forces of every
% report, and the separation points of every wall snapshot
i = find(strcmp(F.model, 'transition') & strcmp(F.design, 'naca2412') & F.alpha == 4, 1);
if ~isempty(i) && ~isempty(snap{i})
    h = Hp(strcmp(Hp.model, 'transition') & strcmp(Hp.design, 'naca2412') & Hp.alpha == 4 & Hp.order == 2, :);
    sn = snap{i};
    Q = cell(0, 9);
    for k = 1:numel(sn.iteration)
        j = find(h.iteration == sn.iteration(k), 1);
        if isempty(j), continue; end
        row = {sn.iteration(k), h.CL(j), h.CD(j), h.CD_pressure(j), h.CD_viscous(j)};
        for side = 1:2
            u = strcmp(sn.surface, sides{side});
            [xs, k2] = sort(sn.x(u));
            c = sn.cf(u, k);  c = c(k2);
            neg = find(c < 0 & xs >= 0.03);
            if isempty(neg), row = [row, {NaN, NaN}]; else, row = [row, {xs(neg(1)), xs(neg(end))}]; end %#ok<AGROW>
        end
        Q(end+1, :) = row; %#ok<AGROW>
    end
    if ~isempty(Q)
        Q = cell2table(Q, 'VariableNames', {'iteration', 'CL', 'CD', 'CD_pressure', 'CD_viscous', 'upper_first_reversed', ...
            'upper_last_reversed', 'lower_first_reversed', 'lower_last_reversed'});
        writetable(Q, fullfile(out, 'cycle_naca2412_a4.csv'));
    end

    f = figure('Color', 'w', 'Position', [60 60 1250 430], 'Visible', 'off');
    tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    nexttile;  hold on;  box on;  grid on;
    plot(h.iteration, h.CD, 'k-', 'LineWidth', 1.3, 'DisplayName', 'total');
    plot(h.iteration, h.CD_pressure, '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.1, 'DisplayName', 'pressure');
    plot(h.iteration, h.CD_viscous, '-', 'Color', [0 0.45 0.74], 'LineWidth', 1.1, 'DisplayName', 'friction');
    xline(F.window_first_iteration(i), ':', 'averaged from here', 'HandleVisibility', 'off', ...
        'LabelVerticalAlignment', 'top', 'LabelOrientation', 'horizontal');
    xlabel('iteration');  ylabel('C_D');  ylim([0 0.009]);  plainTicks(gca, '%.3f');  legend('Location', 'southeast');
    title('NACA 2412, \alpha = 4\circ, Transition SST');
    nexttile;  hold on;  box on;  grid on;
    plot(h.iteration, h.CL, 'k-', 'LineWidth', 1.3);
    xline(F.window_first_iteration(i), ':', 'HandleVisibility', 'off');
    xlabel('iteration');  ylabel('C_L');  plainTicks(gca, '%.3f');
    nexttile;  hold on;  box on;  grid on;
    u = strcmp(sn.surface, 'upper');
    [xs, k2] = sort(sn.x(u));
    c = sn.cf(u, :);  c = c(k2, :);
    plot(xs, c, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5, 'HandleVisibility', 'off');
    plot(xs, mean(c, 2), 'k-', 'LineWidth', 1.4, 'DisplayName', 'mean of the snapshots');
    yline(0, '-', 'Color', [0.85 0.33 0.10], 'HandleVisibility', 'off');
    xlabel('x / c');  ylabel('C_f, upper surface');  xlim([0.2 1]);  ylim([-0.003 0.006]);  plainTicks(gca, '%.3f');
    legend('Location', 'northwest');
    title(sprintf('%d wall snapshots (grey)', size(c, 2)));
    exportgraphics(f, fullfile(out, 'transition_cycle.png'), 'Resolution', 130);
    close(f);
end

% Figures
col = lines(numel(order));
f = figure('Color', 'w', 'Position', [60 60 1250 820], 'Visible', 'off');
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
qty = {'CL', 'CD', 'LD'};  ylab = {'C_L', 'C_D', 'C_L / C_D'};
amax = max([8; F.alpha]);                            % XFOIL lines over the angles of the CFD runs
for m = 1:size(pairs, 1)
    for q = 1:3
        nexttile;  hold on;  box on;  grid on;
        shown = false;
        for k = 1:numel(order)
            if hasX
                x = sortrows(X(strcmp(X.condition, pairs{m, 2}) & strcmp(X.design, order{k}) & X.alpha >= -0.01 & ...
                    X.alpha <= amax + 0.01, :), 'alpha');
                xv = struct('CL', x.CL, 'CD', x.CD, 'LD', x.CL ./ x.CD);
                plot(x.alpha, xv.(qty{q}), '-', 'Color', col(k, :), 'LineWidth', 1.1, 'HandleVisibility', 'off');
            end
            c = sortrows(F(strcmp(F.model, pairs{m, 1}) & strcmp(F.design, order{k}) & ~isnan(F.LD), :), 'alpha');
            if isempty(c), continue; end
            lo = c.([qty{q} '_min']);  hi = c.([qty{q} '_max']);
            errorbar(c.alpha, c.(qty{q}), c.(qty{q}) - lo, hi - c.(qty{q}), 'o', 'Color', col(k, :), ...
                'MarkerFaceColor', col(k, :), 'MarkerSize', 5, 'CapSize', 3, 'DisplayName', label.(order{k}));
            shown = true;
        end
        xlabel('\alpha (deg)');  ylabel(ylab{q});  xlim([0 amax]);
        if q == 1
            if m == 1, title('Transition SST (symbols) and XFOIL, free transition (lines)');
            else, title('SST, fully turbulent (symbols) and XFOIL, tripped (lines)'); end
            if shown, legend('Location', 'northwest'); end
        end
    end
end
exportgraphics(f, fullfile(out, 'design_polars.png'), 'Resolution', 130);
close(f);

methods = unique(P.method, 'stable');
V = nan(numel(order), numel(methods));
for j = 1:numel(methods)
    for k = 1:numel(order)
        v = P.best_LD(strcmp(P.method, methods{j}) & strcmp(P.design, order{k}));
        if ~isempty(v), V(k, j) = v; end
    end
end
methodLabel = struct('transition', 'Fluent, Transition SST', 'xfoil_free', 'XFOIL, free transition', ...
    'sst', 'Fluent, SST (fully turbulent)', 'xfoil_tripped', 'XFOIL, tripped at 5 % chord');
f = figure('Color', 'w', 'Position', [80 80 900 470], 'Visible', 'off');
bar(V);  box on;  grid on;
set(gca, 'XTick', 1:numel(order), 'XTickLabel', cellfun(@(d) label.(d), order, 'UniformOutput', false));
ylabel('best C_L / C_D over the angles run');
legend(cellfun(@(s) methodLabel.(s), methods, 'UniformOutput', false), 'Location', 'northoutside', 'Orientation', 'horizontal');
exportgraphics(f, fullfile(out, 'design_gains.png'), 'Resolution', 130);
close(f);

% Pressure and skin friction of the four designs at 4 deg (Transition SST, means over the cycle),
% with the transition locations of XFOIL
if ~isempty(S) && any(strcmp(S.model, 'transition') & S.alpha == 4)
    f = figure('Color', 'w', 'Position', [60 60 1150 760], 'Visible', 'off');
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    ax = gobjects(1, 4);
    for t = 1:4, ax(t) = nexttile;  hold on;  box on;  grid on; end
    for k = 1:numel(order)
        s = S(strcmp(S.model, 'transition') & strcmp(S.design, order{k}) & S.alpha == 4, :);
        if isempty(s), continue; end
        for side = 1:2
            u = sortrows(s(strcmp(s.surface, sides{side}), :), 'x');
            if side == 1, vis = 'on'; else, vis = 'off'; end
            plot(ax(1), u.x, u.cp, '-', 'Color', col(k, :), 'LineWidth', 1.1, 'DisplayName', label.(order{k}), ...
                'HandleVisibility', vis);
            plot(ax(1 + side), u.x, u.cf, '-', 'Color', col(k, :), 'LineWidth', 1.1);
            if hasX
                x = X(strcmp(X.condition, 'free') & strcmp(X.design, order{k}) & abs(X.alpha - 4) < 1e-9, :);
                if ~isempty(x)
                    xt = [x.xtrTop, x.xtrBot];
                    plot(ax(1 + side), xt(side), 0, 'v', 'Color', col(k, :), 'MarkerFaceColor', col(k, :), 'MarkerSize', 7);
                end
            end
        end
        c = sortrows(F(strcmp(F.model, 'transition') & strcmp(F.design, order{k}) & ~isnan(F.LD), :), 'alpha');
        errorbar(ax(4), c.alpha, c.CD, c.CD - c.CD_min, c.CD_max - c.CD, 'o-', 'Color', col(k, :), ...
            'MarkerFaceColor', col(k, :), 'MarkerSize', 4, 'CapSize', 3);
    end
    set(ax(1), 'YDir', 'reverse');
    xlabel(ax(1), 'x / c');  ylabel(ax(1), 'C_p');  title(ax(1), 'Transition SST, \alpha = 4\circ');
    legend(ax(1), 'Location', 'southeast');
    xlabel(ax(2), 'x / c');  ylabel(ax(2), 'C_f, upper surface');  ylim(ax(2), [-0.002 0.008]);
    plainTicks(ax(2), '%.3f');  title(ax(2), 'triangles: transition in XFOIL');
    xlabel(ax(3), 'x / c');  ylabel(ax(3), 'C_f, lower surface');  ylim(ax(3), [-0.002 0.008]);
    plainTicks(ax(3), '%.3f');
    xlabel(ax(4), '\alpha (deg)');  ylabel(ax(4), 'C_D (mean and range)');  plainTicks(ax(4), '%.4f');
    title(ax(4), 'drag at all angles');
    exportgraphics(f, fullfile(out, 'design_surface.png'), 'Resolution', 130);
    close(f);
end
end

%% ------------------------------------------------------------------ transition tests
function transitionTests(in, out, tol)
if ~exist(out, 'dir'), mkdir(out); end
T = readtable(fullfile(in, 'forces.csv'), 'Delimiter', ',');
if isfile(fullfile(in, 'meshes.csv')), copyfile(fullfile(in, 'meshes.csv'), fullfile(out, 'meshes.csv')); end
if isfile(fullfile(in, 'run_info.json')), copyfile(fullfile(in, 'run_info.json'), fullfile(out, 'run_info.json')); end
label = struct('S', 'settings of the design study', 'R', 'relaxation factor 0.3 for the transition equations', ...
    'U', 'first-order upwinding for the transition equations', 'O', 'step of one chord passage from the start', ...
    'A', 'automatic pseudo-time step');
rows = cell(0, 15);
Hall = cell(0, 1);
for i = 1:height(T)
    file = fullfile(in, T.transcript{i});
    if ~isfile(file), continue; end
    [cd, cl, it, parts] = fluentForces(file);
    n = numel(cd);
    if n < 3, continue; end
    h = table(repmat(T.setting(i), n, 1), it, [1; 2 * ones(n - 1, 1)], cl, cd, parts.CD_pressure, parts.CD_viscous, ...
        'VariableNames', {'setting', 'iteration', 'order', 'CL', 'CD', 'CD_pressure', 'CD_viscous'});
    Hall{end+1, 1} = h; %#ok<AGROW>
    k = h.order == 2;
    s = cycleStatistics(h.iteration(k), h.CL(k), h.CD(k), 'Window', 2400, 'Tol', [tol.CL tol.CD]);
    rows(end+1, :) = {T.setting{i}, label.(T.setting{i}), max(it), s.steady, s.period, s.mismatch, s.cycles, s.window, ...
        s.CL, s.CD, s.LD, s.CL_min, s.CL_max, s.CD_min, s.CD_max}; %#ok<AGROW>
end
if isempty(rows), return; end
F = cell2table(rows, 'VariableNames', {'setting', 'description', 'iterations', 'steady', 'period_iterations', ...
    'period_mismatch', 'cycles_averaged', 'window_iterations', 'CL', 'CD', 'LD', 'CL_min', 'CL_max', 'CD_min', 'CD_max'});
writetable(F, fullfile(out, 'forces.csv'));
Hall = vertcat(Hall{:});
writetable(Hall, fullfile(out, 'history.csv'));

col = lines(height(F));
f = figure('Color', 'w', 'Position', [80 80 1150 430], 'Visible', 'off');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
qty = {'CD', 'CL'};  ylab = {'C_D', 'C_L'};
for q = 1:2
    nexttile;  hold on;  box on;  grid on;
    for i = 1:height(F)
        h = Hall(strcmp(Hall.setting, F.setting{i}) & Hall.order == 2, :);
        plot(h.iteration, h.(qty{q}), '-', 'Color', col(i, :), 'LineWidth', 1.1, ...
            'DisplayName', [F.setting{i} ': ' F.description{i}]);
    end
    xlabel('iteration');  ylabel(ylab{q});  plainTicks(gca, '%.4f');
    if q == 1
        ylim([0.005 0.0075]);  legend('Location', 'southoutside');
        title('NACA 2412, \alpha = 4\circ, Transition SST');
    end
end
exportgraphics(f, fullfile(out, 'transition_tests.png'), 'Resolution', 130);
close(f);
end

%% ------------------------------------------------------------------ helpers
function plainTicks(ax, fmt)
% Tick labels of the y axis as plain decimal numbers (no common power of ten)
ax.YAxis.Exponent = 0;
ytickformat(ax, fmt);
end

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
