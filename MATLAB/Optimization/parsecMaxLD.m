function ld = parsecMaxLD(q, x, Re, exe, tRange)
%PARSECMAXLD  Maximum lift-to-drag ratio of a PARSEC airfoil (XFOIL).
%   ld = PARSECMAXLD(q, x, Re, exe, tRange) with
%   q = [rle Xup Yup YXXup Xlow Ylow YXXlow alpha_te beta_te] (closed
%   trailing edge at y = 0). Returns max(CL/CD) over alpha = -2..12 deg (0.5 deg steps), or
%   0 if the shape is invalid (crossing surfaces, maximum thickness outside
%   tRange = [tmin tmax]) or XFOIL does not converge.

p = [q(1:7), 0, 0, q(8), q(9)];
[yu, yl] = parsecSurfaces(p, x);
t = yu - yl;
if any(~isfinite(t)) || any(t(2:end-1) <= 0) || ...
        max(t) < tRange(1) - 1e-3 || max(t) > tRange(2)
    ld = 0;
    return;
end
pol = xfoilPolar(x, yu, x, yl, Re, [-2 12 0.5], exe);
if numel(pol.alpha) < 12
    ld = 0;
    return;
end
ld = efficiencyValue(pol, 'LDmax');   % spike-filtered
end
