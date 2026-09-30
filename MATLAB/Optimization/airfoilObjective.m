function f = airfoilObjective(d, S)
%AIRFOILOBJECTIVE  Objective minimised by optimize_airfoil.
%   f = AIRFOILOBJECTIVE(d, S) applies the CST coefficient changes d to the
%   fitted airfoil in S and returns minus its efficiency (XFOIL).
%
%   The geometric limits are checked first, without XFOIL (designViolation):
%   thickness, crossing surfaces and, if S.curvReject is true, the curvature
%   limits in S.curv. A design that breaks them gets the size of the
%   violation, a positive value. It therefore ranks behind every valid
%   design, and designs that break the limits less rank first (Deb's
%   feasibility rule). With S.curvReject = false the curvature limits are
%   left to the caller (fmincon treats them as nonlinear constraints).
%
%   Designs with a pitching moment |CM(alpha=0)| above S.cmMax or a maximum
%   lift below S.clMaxMin, and designs that XFOIL cannot analyse, get the
%   value S.failValue (0 = worse than any valid design; NaN for bayesopt,
%   which treats it as a failed evaluation).
%
%   The efficiency is computed with XFOIL's default 160 panel nodes and
%   again with 200, and the lower value counts. Optimisers are good at
%   finding numerical artefacts; an XFOIL result that appears with only one
%   panelling does not survive this check. The second analysis is skipped
%   when the first already scores below S.checkAbove (normally the original
%   airfoil's value): such a shape cannot be the result, so its exact score
%   does not matter, and skipping it saves much of the search time.
%
%   If S.historyDir is set, every evaluation is appended to a file in that
%   folder (one file per process, so parallel workers do not collide): time
%   (seconds since 1970, UTC), stage, objective value, number of XFOIL
%   analyses, duration of the evaluation (s) and d. The durations show
%   whether the machine ran at its normal speed.

clock0 = tic;
[f, nXfoil] = evaluate(d, S);
if isfield(S, 'historyDir') && ~isempty(S.historyDir)
    logEvaluation(S.historyDir, S.stage, d, f, nXfoil, toc(clock0));
end
end

function [f, nXfoil] = evaluate(d, S)
nXfoil = 0;
[v, yu, yl] = designViolation(d, S, S.curvReject);
if v > 0
    f = v;
    return;
end
e = Inf;
for panels = {[], 200}
    pol = xfoilPolar(S.x, yu, S.x, yl, S.Re, S.alphaRange, S.exe, panels{1}, false);
    nXfoil = nXfoil + 1;
    if numel(pol.alpha) < 12 || pol.alpha(1) > 0 || pol.alpha(end) < 0 || ...
            abs(interp1(pol.alpha, pol.CM, 0)) > S.cmMax || max(pol.CL) < S.clMaxMin
        f = S.failValue;
        return;
    end
    e = min(e, efficiencyValue(pol, S.objective, S.designCL, S.weights));
    if e < S.checkAbove, break; end
end
if ~isfinite(e) || e <= 0
    f = S.failValue;
else
    f = -e;
end
end

function logEvaluation(folder, stage, d, f, nXfoil, seconds)
file = fullfile(folder, sprintf('eval_%d.csv', feature('getpid')));
fid = fopen(file, 'a');
if fid < 0, return; end
fprintf(fid, '%.3f,%s,%.10g,%d,%.2f%s\n', posixtime(datetime('now', 'TimeZone', 'local')), ...
    stage, f, nXfoil, seconds, sprintf(',%.8g', d));
fclose(fid);
end
