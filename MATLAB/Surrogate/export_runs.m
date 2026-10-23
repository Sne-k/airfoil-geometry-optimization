% Exports, for every population run, the seed CST fit and the settings needed to rebuild absolute shapes
% from the evaluation logs (history/eval_*.csv: time, stage, f, nXfoil, seconds, d(1:14)).
W = getenv('AIRFOIL_WORK');                         % work folder with the logged runs (MATLAB/Surrogate/README.md)
if isempty(W), error('Surrogate:work', 'Set the environment variable AIRFOIL_WORK (MATLAB/Surrogate/README.md).'); end
here = fileparts(mfilename('fullpath'));  ML = fileparts(here);  repo = fileparts(ML);   % MATLAB/Surrogate, MATLAB, repo
d = dir(fullfile(W, 'population_runs', '*', 'result.mat'));
fid = fopen(fullfile(W, 'feasibility', 'runs_seed_fit.csv'), 'w');
fprintf(fid, 'tag,objective,aggregate,flows,curvature,objective_final,dte,%s,%s\n', strjoin(compose('Au%d', 0:6), ','), strjoin(compose('Al%d', 0:6), ','));
for k = 1:numel(d)
    [~, tag] = fileparts(d(k).folder);
    s = load(fullfile(d(k).folder, 'result.mat'));  r = s.result;  o = r.options;
    flows = 'free';  if isfield(o, 'Conditions') && numel(o.Conditions) == 2, flows = 'free+tripped'; end
    if numel(o.Ncrit) > 1, flows = sprintf('ncrit%s', strjoin(compose('%g', o.Ncrit), '+')); end
    fprintf(fid, '%s,%s,%s,%s,%d,%.10g,%.17g%s%s\n', tag, o.Objective, o.Aggregate, flows, o.Curvature, ...
        r.runInfo.objectiveFinal, r.dte, sprintf(',%.17g', r.Au), sprintf(',%.17g', r.Al));
end
fclose(fid);
fprintf('%d runs exported\n', numel(d));
