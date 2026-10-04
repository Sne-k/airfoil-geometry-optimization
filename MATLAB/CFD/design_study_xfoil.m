function T = design_study_xfoil(outDir)
%DESIGN_STUDY_XFOIL  XFOIL polars of the airfoils of the CFD design study.
%   T = DESIGN_STUDY_XFOIL analyses the four airfoils of run_design_study.m
%   with XFOIL at Re = 1e6 (160 panel nodes, alpha from -2 to 12 deg in
%   0.5 deg steps) under three conditions:
%     free      free transition, Ncrit = 9, M = 0.15 (compared with
%               Transition SST)
%     tripped   transition fixed at x/c = 0.05 on both surfaces, M = 0.15
%               (compared with fully turbulent SST)
%     free_M0   free transition, Ncrit = 9, M = 0: the condition of the
%               optimisation, to show the effect of the Mach number
%   and writes xfoil.csv to outDir (default results/cfd/designs):
%   design, condition, alpha, CL, CD, CM, xtrTop, xtrBot.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
repo = fullfile(root, '..');
addpath(fullfile(root, 'Aerodynamics'), fullfile(root, 'NACA2412'));
if nargin < 1 || isempty(outDir), outDir = fullfile(repo, 'results', 'cfd', 'designs'); end
if ~exist(outDir, 'dir'), mkdir(outDir); end
exe = getenv('XFOIL_EXE');
if isempty(exe), exe = fullfile(root, 'Aerodynamics', 'xfoil.exe'); end

designs = {'naca2412', 'NACA 2412'
           'smooth_s1', fullfile(repo, 'results', 'paper', 'runs', 'NACA_2412_s1', 'NACA_2412_optimized.dat')
           'wavy_s1', fullfile(repo, 'results', 'paper', 'runs', 'NACA_2412_nocurv_s1', 'NACA_2412_optimized.dat')
           'parsec_t12', fullfile(repo, 'results', 'xfoil', 'NACA2412_parsec_t12_optimized.dat')};
conditions = {'free', struct('Mach', 0.15)
              'tripped', struct('Mach', 0.15, 'Xtr', [0.05 0.05])
              'free_M0', struct()};
T = cell(0, 1);
for k = 1:size(designs, 1)
    [xu, yu, xl, yl] = readAirfoil(designs{k, 2});
    for c = 1:size(conditions, 1)
        p = xfoilPolar(xu, yu, xl, yl, 1e6, [-2 12 0.5], exe, [], true, conditions{c, 2});
        n = numel(p.alpha);
        T{end+1, 1} = table(repmat(designs(k, 1), n, 1), repmat(conditions(c, 1), n, 1), p.alpha, p.CL, p.CD, p.CM, ...
            p.xtrTop, p.xtrBot, 'VariableNames', {'design', 'condition', 'alpha', 'CL', 'CD', 'CM', 'xtrTop', 'xtrBot'}); %#ok<AGROW>
        [ld, i] = max(p.CL ./ p.CD);
        fprintf('%-11s %-8s %2d angles, best CL/CD %.1f at %.1f deg\n', designs{k, 1}, conditions{c, 1}, n, ld, p.alpha(i));
    end
end
T = vertcat(T{:});
writetable(T, fullfile(outDir, 'xfoil.csv'));
end
