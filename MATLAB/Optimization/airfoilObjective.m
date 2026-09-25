function f = airfoilObjective(d, S)
%AIRFOILOBJECTIVE  Objective minimised by optimize_airfoil.
%   f = AIRFOILOBJECTIVE(d, S) applies the CST coefficient changes d to the
%   fitted airfoil in S and returns minus its efficiency (XFOIL). Shapes
%   with crossing surfaces, a maximum thickness outside [S.tMin S.tMax], a
%   pitching moment |CM(alpha=0)| above S.cmMax, or no XFOIL convergence
%   get the penalty value 0.

n1 = numel(S.Au);
[yu, yl] = cstSurfaces(S.Au + d(1:n1), S.Al + d(n1+1:end), S.dte, S.x);
t = yu - yl;
if any(~isfinite(t)) || any(t(2:end-1) <= 0) || max(t) < S.tMin || max(t) > S.tMax
    f = 0;
    return;
end
pol = xfoilPolar(S.x, yu, S.x, yl, S.Re, S.alphaRange, S.exe);
if numel(pol.alpha) < 12
    f = 0;
    return;
end
k0 = find(abs(pol.alpha) < 1e-9, 1);
if ~isempty(k0) && abs(pol.CM(k0)) > S.cmMax
    f = 0;
    return;
end
f = -efficiencyValue(pol, S.objective, S.designCL);
end
