function summary = validate_xfoil(outDir)
%VALIDATE_XFOIL  Checks the XFOIL analysis of this project against wind-tunnel data.
%   summary = VALIDATE_XFOIL runs XFOIL through xfoilPolar, with the
%   settings used everywhere in this project (re-panelling with PANE, 160
%   panel nodes, Ncrit 9), at the conditions of NACA 0012 experiments and
%   compares lift and drag:
%     A. free transition, M = 0.15, Re = 2.00, 3.94 and 5.97 million:
%        Ladson (1988), NASA TM-4074, Table I, transcribed from the report
%        (results/validation/experimental/Ladson1988_TableI_M015_free.csv)
%     B. transition fixed at x/c = 0.05 on both surfaces (carborundum strips,
%        Ladson 1988, p. 3), M = 0.15, Re = 6 million: Ladson (1988), 80, 120
%        and 180 grit (file from the NASA Turbulence Modeling Resource)
%     C. free transition, Re = 6 million: Abbott & von Doenhoff (1959),
%        digitised by the NASA Turbulence Modeling Resource (approximate)
%     D. lift-curve slope at Re = 1 million (the design condition of this
%        project) and at the conditions of A: McCroskey's (1988) correlation
%        of many wind-tunnel tests
%   Ladson's model had the standard NACA 0012 ordinates, whose trailing edge
%   is 0.25 % of the chord thick, so that geometry is analysed; the
%   closed-trailing-edge variant used by the optimisation is run as a
%   sensitivity check, and so are 200 panel nodes and Ncrit = 12 (a
%   low-turbulence tunnel; XFOIL's documentation lists 10-12 for a clean
%   tunnel).
%
%   Lift is compared at the measured angle of attack and drag at the
%   measured lift coefficient (XFOIL interpolated; only pre-stall points).
%   Results go to outDir (default results/validation/xfoil): summary.csv,
%   the XFOIL polars, and figures.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'NACA2412'));
repo = fullfile(root, '..');
expDir = fullfile(repo, 'results', 'validation', 'experimental');
if nargin < 1, outDir = fullfile(repo, 'results', 'validation', 'xfoil'); end
if ~exist(outDir, 'dir'), mkdir(outDir); end
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end

%% Geometries
x = (1 - cos(linspace(0, pi, 150)')) / 2;
yt = @(a4) 5*0.12*(0.2969*sqrt(x) - 0.1260*x - 0.3516*x.^2 + 0.2843*x.^3 + a4*x.^4);
geo.standard = struct('yu', yt(-0.1015), 'yl', -yt(-0.1015));     % open TE, 0.25 % c
geo.closed = struct('yu', yt(-0.1036), 'yl', -yt(-0.1036));       % as in the optimisation

%% Experimental data
L = readtable(fullfile(expDir, 'Ladson1988_TableI_M015_free.csv'));
trip = readZones(fullfile(expDir, 'CLCD_Ladson_expdata.dat'));
abbCL = readZones(fullfile(expDir, '0012.abbottdata.cl.dat'));
abbCD = readZones(fullfile(expDir, '0012.abbottdata.cd.dat'));
greg = readZones(fullfile(expDir, 'CL_Gregory_expdata.dat'));
mcSlope = @(Re, M) (0.1025 + 0.00485*log10(Re/1e6)) / sqrt(1 - M^2);   % per degree

%% Cases: {name, Re, Mach, Xtr, Ncrit, panels, geometry}
cases = {};
for Re = [2.00e6 3.94e6 5.97e6]
    cases(end+1, :) = {['free_Re' reTag(Re) 'M'], Re, 0.15, [1 1], 9, [], 'standard'}; %#ok<AGROW>
    cases(end+1, :) = {['free_Re' reTag(Re) 'M_N200'], Re, 0.15, [1 1], 9, 200, 'standard'}; %#ok<AGROW>
    cases(end+1, :) = {['free_Re' reTag(Re) 'M_Ncrit12'], Re, 0.15, [1 1], 12, [], 'standard'}; %#ok<AGROW>
    cases(end+1, :) = {['free_Re' reTag(Re) 'M_closedTE'], Re, 0.15, [1 1], 9, [], 'closed'}; %#ok<AGROW>
end
cases(end+1, :) = {'tripped_Re6M', 6e6, 0.15, [0.05 0.05], 9, [], 'standard'};
cases(end+1, :) = {'tripped_Re6M_closedTE', 6e6, 0.15, [0.05 0.05], 9, [], 'closed'};
cases(end+1, :) = {'free_Re3M', 3e6, 0.15, [1 1], 9, [], 'standard'};
cases(end+1, :) = {'tripped_Re3M', 3e6, 0.15, [0.05 0.05], 9, [], 'standard'};
cases(end+1, :) = {'free_Re1M_M0', 1e6, 0, [1 1], 9, [], 'standard'};
cases(end+1, :) = {'free_Re1M_M0_closedTE', 1e6, 0, [1 1], 9, [], 'closed'};

pols = struct();
for k = 1:size(cases, 1)
    [name, Re, M, xtr, nc, panels, g] = cases{k, :};
    flow = struct('Mach', M, 'Ncrit', nc, 'Xtr', xtr);
    [p, info] = xfoilPolar(x, geo.(g).yu, x, geo.(g).yl, Re, [-6 20 0.25], exe, panels, true, flow);
    checkHeader(info.header, Re, M, nc, xtr, name);
    pols.(name) = p;
    writetable(struct2table(p), fullfile(outDir, ['polar_' name '.csv']));
    fprintf('%-26s %3d points, alpha %5.2f .. %5.2f\n', name, numel(p.alpha), min(p.alpha), max(p.alpha));
end

%% Comparisons
rows = {};
for Re = [2.00e6 3.94e6 5.97e6]
    e = L(abs(L.Re - Re) < 1, :);
    for suffix = {'', '_N200', '_Ncrit12', '_closedTE'}
        name = ['free_Re' reTag(Re) 'M' suffix{1}];
        rows(end+1, :) = compare(sprintf('A. Ladson free transition (Table I), Re %.2fe6, M 0.15', Re/1e6), ...
            name, pols.(name), e.alpha_deg, e.cl, e.cl, e.cd, mcSlope(Re, 0.15)); %#ok<AGROW>
    end
end
for z = 1:numel(trip)
    for name = {'tripped_Re6M', 'tripped_Re6M_closedTE'}
        rows(end+1, :) = compare(['B. Ladson transition fixed at 0.05c, ' trip(z).name ', Re 6e6, M 0.15'], ...
            name{1}, pols.(name{1}), trip(z).data(:, 1), trip(z).data(:, 2), trip(z).data(:, 2), ...
            trip(z).data(:, 3), mcSlope(6e6, 0.15)); %#ok<AGROW>
    end
end
rows(end+1, :) = compare('C. Abbott & von Doenhoff free transition (digitised), Re 6e6', 'free_Re5p97M', ...
    pols.free_Re5p97M, abbCL.data(:, 1), abbCL.data(:, 2), abbCD.data(:, 1), abbCD.data(:, 2), mcSlope(6e6, 0.15));
for name = {'free_Re3M', 'tripped_Re3M'}
    rows(end+1, :) = compare('C. Gregory & O''Reilly lift (digitised; tripped), Re 3e6', name{1}, ...
        pols.(name{1}), greg.data(:, 1), greg.data(:, 2), [], [], mcSlope(3e6, 0.15)); %#ok<AGROW>
end
for name = {'free_Re1M_M0', 'free_Re1M_M0_closedTE'}
    rows(end+1, :) = compare('D. McCroskey lift-curve slope correlation, Re 1e6, M 0', name{1}, ...
        pols.(name{1}), [], [], [], [], mcSlope(1e6, 0)); %#ok<AGROW>
end
summary = cell2table(rows, 'VariableNames', {'data', 'xfoil_case', 'n_lift_points', ...
    'CL_mean_abs_error', 'CL_max_abs_error', 'lift_slope_exp_per_deg', 'lift_slope_xfoil_per_deg', ...
    'lift_slope_McCroskey_per_deg', 'CLmax_exp', 'CLmax_xfoil', 'alpha_CLmax_exp', 'alpha_CLmax_xfoil', ...
    'n_drag_points', 'CD_mean_abs_error_percent', 'CD_max_abs_error_percent', 'CD_mean_error_percent', ...
    'LDmax_exp', 'LDmax_xfoil'});
writetable(summary, fullfile(outDir, 'summary.csv'));
disp(summary(:, [1 2 4 5 6 7 8 9 10 14 16 17 18]));

%% Figures
f = figure('Color', 'w', 'Position', [60 60 1300 800]);
Res = [2.00e6 3.94e6 5.97e6];
for i = 1:3
    e = L(abs(L.Re - Res(i)) < 1, :);
    p = pols.(['free_Re' reTag(Res(i)) 'M']);
    p12 = pols.(['free_Re' reTag(Res(i)) 'M_Ncrit12']);
    subplot(2, 3, i);
    plot(p.alpha, p.CL, 'r-', p12.alpha, p12.CL, 'r:', e.alpha_deg, e.cl, 'ko', 'LineWidth', 1.2);
    grid on; xlabel('\alpha (deg)'); ylabel('C_L');
    title(sprintf('Free transition, Re = %.2f\\times10^6, M = 0.15', Res(i)/1e6));
    if i == 1, legend('XFOIL N_{crit} 9', 'XFOIL N_{crit} 12', 'Ladson (1988)', 'Location', 'southeast'); end
    subplot(2, 3, 3 + i);
    plot(p.CD, p.CL, 'r-', p12.CD, p12.CL, 'r:', e.cd, e.cl, 'ko', 'LineWidth', 1.2);
    grid on; xlabel('C_D'); ylabel('C_L'); xlim([0 0.03]);
end
exportgraphics(f, fullfile(outDir, 'validation_free_transition.png'), 'Resolution', 130);

f2 = figure('Color', 'w', 'Position', [60 60 1100 450]);
p = pols.tripped_Re6M;
marks = {'ko', 'ks', 'k^'};
subplot(1, 2, 1);
plot(p.alpha, p.CL, 'r-', 'LineWidth', 1.2); hold on;
for z = 1:numel(trip), plot(trip(z).data(:, 1), trip(z).data(:, 2), marks{z}); end
grid on; xlabel('\alpha (deg)'); ylabel('C_L');
title('Transition fixed at 0.05c, Re = 6\times10^6, M = 0.15');
legend([{'XFOIL'}, strcat({'Ladson (1988), '}, {trip.name})], 'Location', 'southeast');
subplot(1, 2, 2);
plot(p.CD, p.CL, 'r-', 'LineWidth', 1.2); hold on;
for z = 1:numel(trip), plot(trip(z).data(:, 3), trip(z).data(:, 2), marks{z}); end
grid on; xlabel('C_D'); ylabel('C_L'); xlim([0 0.03]);
exportgraphics(f2, fullfile(outDir, 'validation_tripped.png'), 'Resolution', 130);
end

function row = compare(dataName, caseName, p, aL, cl, clD, cd, slopeMc)
% Lift at the measured angles, drag at the measured lift, pre-stall only
row = {dataName, caseName, 0, NaN, NaN, NaN, NaN, slopeMc, NaN, NaN, NaN, NaN, 0, NaN, NaN, NaN, NaN, NaN};
% XFOIL: pre-stall branch, lift slope from -4..4 deg
[clmaxX, iX] = max(p.CL);
lin = abs(p.alpha) <= 4;
cX = polyfit(p.alpha(lin), p.CL(lin), 1);
row([7 10 12]) = {cX(1), clmaxX, p.alpha(iX)};
ldX = supportedMax(p.alpha, p.CL ./ p.CD);
row{18} = ldX;
pre = [];
if ~isempty(aL)
    [clmaxE, iE] = max(cl);
    pre = aL <= aL(iE);                                   % before the measured stall
    use = pre & abs(aL) <= 10 & aL >= min(p.alpha) & aL <= max(p.alpha);
    dCL = interp1(p.alpha, p.CL, aL(use)) - cl(use);
    row([3 4 5 9 11]) = {sum(use), mean(abs(dCL)), max(abs(dCL)), clmaxE, aL(iE)};
    linE = pre & abs(aL) <= 4.5;
    if sum(linE) >= 2
        cE = polyfit(aL(linE), cl(linE), 1);
        row{6} = cE(1);
    end
end
if ~isempty(cd)
    ok = ~isnan(cd);
    if isequal(clD, cl)
        ok = ok & pre;             % lift and drag from the same runs: drop the points after stall
    end
    clD = clD(ok);  cd = cd(ok);
    % XFOIL drag as a function of lift on the branch below its CL max
    br = 1:iX;
    [clS, is] = unique(p.CL(br));
    cdS = p.CD(br(is));
    use = abs(clD) <= 1.0 & clD >= min(clS) & clD <= max(clS);
    if clD(1) < 0 && all(p.CL(br) >= -0.05)
        use = use & clD >= 0;                             % XFOIL branch starts near zero lift
    end
    rel = 100 * (interp1(clS, cdS, clD(use)) - cd(use)) ./ cd(use);
    row(13:16) = {sum(use), mean(abs(rel)), max(abs(rel)), mean(rel)};
    row{17} = max(clD ./ cd);                             % from the measured drag polar
end
end

function s = reTag(Re)
% Reynolds number in millions for field and file names, e.g. 2p00
s = strrep(sprintf('%.2f', Re/1e6), '.', 'p');
end

function Z = readZones(file)
% Tecplot-style data file from the NASA Turbulence Modeling Resource:
% comment lines (#), a 'variables=' line, optional 'zone, t="..."' lines
lines = splitlines(fileread(file));
Z = struct('name', {}, 'data', {});
cur = struct('name', 'data', 'data', []);
for i = 1:numel(lines)
    s = strtrim(lines{i});
    if isempty(s) || startsWith(s, '#') || startsWith(lower(s), 'variables'), continue; end
    if startsWith(lower(s), 'zone')
        if ~isempty(cur.data), Z(end+1) = cur; end %#ok<AGROW>
        t = regexp(s, 't="([^"]*)"', 'tokens', 'once');
        cur = struct('name', t{1}, 'data', []);
        continue;
    end
    v = sscanf(s, '%f').';
    cur.data(end+1, :) = v;
end
if ~isempty(cur.data), Z(end+1) = cur; end
end

function checkHeader(h, Re, M, nc, xtr, name)
% The settings in XFOIL's polar file header must be the requested ones
num = @(pat) str2double(regexp(h, pat, 'tokens', 'once'));
ok = abs(num('Mach\s*=\s*([\d.]+)') - M) < 1e-6 && ...
     abs(num('Re\s*=\s*([\d.]+)\s*e\s*6') * 1e6 - Re) < 0.0015e6 && ...
     abs(num('Ncrit\s*=\s*([\d.]+)') - nc) < 1e-6 && ...
     abs(num('xtrf\s*=\s*([\d.]+)') - xtr(1)) < 1e-6;
if ~ok
    error('validate_xfoil:settings', 'XFOIL did not use the requested settings for %s:\n%s', name, h);
end
end
