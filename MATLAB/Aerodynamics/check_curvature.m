%% Curvature check of the optimised airfoils
% Looks for curvature reversals and trailing-edge curvature artefacts in
% every optimised airfoil in results/ (see curvatureReport.m) and compares
% them with the seed airfoils. Writes results/curvature_check.csv.

clear; clc;

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(here, fullfile(root, 'NACA2412'));
res = fullfile(root, '..', 'results');
oa = fullfile(res, 'optimize_airfoil');

files = {'NACA 2412 (seed)', 'NACA 2412';
         'NACA 0012 (seed)', 'NACA 0012';
         'NACA 4412 (seed)', 'NACA 4412';
         'NACA 23012 (seed)', 'NACA 23012';
         'Clark Y (seed)', fullfile(root, 'airfoils', 'clarky.dat');
         'PARSEC, t >= 12 % (recommended)', fullfile(res, 'xfoil', 'NACA2412_parsec_t12_optimized.dat');
         'NACA [m p t], t >= 12 %', fullfile(res, 'xfoil', 'NACA2412_naca_t12_optimized.dat');
         'CST NACA 2412', fullfile(res, 'xfoil', 'NACA2412_cst_optimized.dat')};
dirs = dir(oa);
for k = 1:numel(dirs)
    if dirs(k).isdir && dirs(k).name(1) ~= '.'
        dat = dir(fullfile(oa, dirs(k).name, '*_optimized.dat'));
        if ~isempty(dat)
            files(end+1, :) = {['CST ' strrep(dirs(k).name, '_', ' ')], fullfile(oa, dirs(k).name, dat(1).name)}; %#ok<SAGROW>
        end
    end
end
x2 = fullfile(res, 'xoptfoil2', 'NACA2412_X2.dat');
if isfile(x2), files(end+1, :) = {'Xoptfoil2 NACA 2412 (Bezier, PSO)', x2}; end

n = size(files, 1);
T = table('Size', [n 6], 'VariableTypes', [{'string'}, repmat({'double'}, 1, 5)], ...
    'VariableNames', {'Airfoil', 'reversals_top', 'reversals_bot', 'te_curv_top', 'te_curv_bot', 'fit_error'});
for k = 1:n
    [xu, yu, xl, yl] = readAirfoil(files{k, 2});
    r = curvatureReport(xu, yu, xl, yl);
    T(k, :) = {files{k, 1}, r.reversalsTop, r.reversalsBot, r.teCurvTop, r.teCurvBot, r.fitError};
end
disp(T);
writetable(T, fullfile(res, 'curvature_check.csv'));
