function D = designStudyAirfoils()
%DESIGNSTUDYAIRFOILS  The airfoils of the CFD design study.
%   D = DESIGNSTUDYAIRFOILS returns a table with one row per airfoil: name
%   (used in file names), source (an airfoil name or a coordinate file, as
%   readAirfoil takes it) and label (for figures and tables).
%     naca2412        the original NACA 2412
%     smooth_s1       optimised for peak CL/CD with curvature limits (seed 1,
%                     the best of three; results/paper/runs/NACA_2412_s1)
%     wavy_s1         the same without curvature limits (seed 1, the best of
%                     three; results/paper/runs/NACA_2412_nocurv_s1)
%     parsec_t12      the earlier PARSEC design (results/xfoil)
%     robust_trip_s3  optimised for the mean of the peak CL/CD with free
%                     transition and with tripped boundary layers (seed 3,
%                     the best of three; results/population/airfoils)
%     trip_worst_s1   optimised for the lower of those two values
%                     (results/population/airfoils)
%   run_design_study.m, design_study_xfoil.m and collect_cfd_results.m use
%   this list.

repo = fullfile(fileparts(mfilename('fullpath')), '..', '..');
paper = fullfile(repo, 'results', 'paper', 'runs');
population = fullfile(repo, 'results', 'population', 'airfoils');
D = cell2table({
    'naca2412',       'NACA 2412',                                                    'NACA 2412'
    'smooth_s1',      fullfile(paper, 'NACA_2412_s1', 'NACA_2412_optimized.dat'),        'optimised, smooth'
    'wavy_s1',        fullfile(paper, 'NACA_2412_nocurv_s1', 'NACA_2412_optimized.dat'), 'optimised, no curvature limits'
    'parsec_t12',     fullfile(repo, 'results', 'xfoil', 'NACA2412_parsec_t12_optimized.dat'), 'PARSEC design'
    'robust_trip_s3', fullfile(population, 'NACA_2412_robusttrip_s3.dat'),             'optimised for free and tripped flow (mean)'
    'trip_worst_s1',  fullfile(population, 'NACA_2412_robusttripworst_s1.dat'),        'optimised for the worse of free and tripped'
    }, 'VariableNames', {'name', 'source', 'label'});
end
