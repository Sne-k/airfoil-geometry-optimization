function ld = nacaMaxLD(v, x, Re, exe)
%NACAMAXLD  Maximum lift-to-drag ratio of a NACA 4-digit section (XFOIL).
%   ld = NACAMAXLD([m p t], x, Re, exe) builds the section at the stations
%   x and returns max(CL/CD) over alpha = -2..12 deg (0.5 deg steps), or 0 if XFOIL does
%   not converge.

[xu, yu, xl, yl] = naca4(v(1), v(2), v(3), x);
pol = xfoilPolar(xu, yu, xl, yl, Re, [-2 12 0.5], exe);
if numel(pol.alpha) < 12
    ld = 0;
    return;
end
ld = efficiencyValue(pol, 'LDmax');   % spike-filtered
end
