function f = airfoilObjective(d, S)
%AIRFOILOBJECTIVE  Objective minimised by optimize_airfoil.
%   f = AIRFOILOBJECTIVE(d, S) applies the CST coefficient changes d to the
%   fitted airfoil in S and returns minus its efficiency (XFOIL). Shapes
%   with crossing surfaces, a maximum thickness outside [S.tMin S.tMax], a
%   pitching moment |CM(alpha=0)| above S.cmMax, or no XFOIL convergence
%   get the penalty value 0.
%
%   The efficiency is computed with XFOIL's default 160 panel nodes and
%   again with 200, and the lower value counts. Optimisers are good at
%   finding numerical artefacts; an XFOIL result that appears with only one
%   panelling does not survive this check.

n1 = numel(S.Au);
[yu, yl] = cstSurfaces(S.Au + d(1:n1), S.Al + d(n1+1:end), S.dte, S.x);
t = yu - yl;
if any(~isfinite(t)) || any(t(2:end-1) <= 0) || max(t) < S.tMin || max(t) > S.tMax
    f = 0;
    return;
end
v = Inf;
for panels = {[], 200}
    pol = xfoilPolar(S.x, yu, S.x, yl, S.Re, S.alphaRange, S.exe, panels{1});
    if numel(pol.alpha) < 12 || pol.alpha(1) > 0 || pol.alpha(end) < 0 || ...
            abs(interp1(pol.alpha, pol.CM, 0)) > S.cmMax
        f = 0;
        return;
    end
    v = min(v, efficiencyValue(pol, S.objective, S.designCL));
end
if ~isfinite(v) || v <= 0
    f = 0;
else
    f = -v;
end
end
