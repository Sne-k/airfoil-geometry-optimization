%% PARSEC + genetic algorithm (reference approach, El Houd & Hallou 2022)
% Runs the genetic algorithm of GAairfoil.m on the 11 PARSEC parameters,
% starting from the PARSEC fit of NACA 2412. The fitness is the airfoil's
% cross-sectional area (see GAairfoil.m), so the result is a thinner airfoil,
% not an aerodynamically optimised one. Kept as the PARSEC branch of the
% project; the report results come from optimize_naca_ga_nlp.m.
%
% Output folder: MATLAB/output/parsec_ga

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'PARSEC'));
outDir = fullfile(here, '..', 'output', 'parsec_ga');
if ~exist(outDir, 'dir'), mkdir(outDir); end

rng(1);

%% Initial individual: PARSEC fit of NACA 2412 (PARSEC/fit_parsec_naca2412.m)
p0 = [0.01495 0.32556 0.07946 -0.63759 0.22209 -0.04144 0.22360 0 0 -2.81359 19.52005];

% +/- variation of each parameter around p0
range = [0.002 0.03 0.01 0.1 0.03 0.01 0.1 0 0 1 1];

%% Genetic solution
genNo = 100;       % number of generations
[AAoriginal, AAfittest, fittest, fitness] = GAairfoil(genNo, p0, range);
fprintf(' Original   area = %f\n Optimized  area = %f\n', AAoriginal, AAfittest);
axis('equal');

exportAirfoilDat(p0, fullfile(outDir, 'parsec_original.dat'), 'PARSEC NACA 2412');
exportAirfoilDat(fittest, fullfile(outDir, 'parsec_ga_optimized.dat'), 'PARSEC GA minimum area');
