function [v, yu, yl] = designViolation(d, S, withCurvature)
%DESIGNVIOLATION  How far a design breaks the geometric limits (0 if valid).
%   [v, yu, yl] = DESIGNVIOLATION(d, S, withCurvature) applies the CST
%   coefficient changes d to the fitted airfoil in S and returns the sum of
%   the geometric violations, together with the surfaces at S.x:
%     - thickness below S.tMin or above S.tMax (maximum thickness),
%     - crossing surfaces (negative thickness),
%     - with withCurvature = true and curvature limits in S.curv, the
%       curvature violations from curvatureViolation.
%   No XFOIL analysis is needed, so the check is cheap.

n1 = numel(S.Au);
Au = S.Au + d(1:n1);
Al = S.Al + d(n1+1:end);
[yu, yl] = cstSurfaces(Au, Al, S.dte, S.x);
t = yu - yl;
if any(~isfinite(t))
    v = 1e3;
    return;
end
ti = t(2:end-1);
v = max(0, S.tMin - max(t)) + max(0, max(t) - S.tMax) + sum(max(0, -ti)) + 1e-6 * any(ti <= 0);
if withCurvature && isfield(S, 'curv') && ~isempty(S.curv)
    v = v + sum(curvatureViolation(Au, Al, S.dte, S.curv));
end
end
