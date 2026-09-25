function r = camberThicknessRatio(v, x)
%CAMBERTHICKNESSRATIO  Geometric objective used in the project.
%   r = CAMBERTHICKNESSRATIO([m p t], x) returns the maximum camber divided
%   by the maximum thickness of the NACA 4-digit section with parameters
%   m, p, t, both measured from the surface coordinates at the stations x
%   (same definition as in the project code, gian.m).
%
%   This is a geometric stand-in for lift-to-drag ratio: no lift or drag is
%   computed. It grows with camber and falls with thickness, so maximising
%   it drives m to its upper bound and t to its lower bound.

[~, yu, ~, yl] = naca4(v(1), v(2), v(3), x);
camber = max(abs(yu + yl) / 2);
thickness = max(yu - yl);
r = camber / thickness;
end
