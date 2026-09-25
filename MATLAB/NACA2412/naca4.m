function [xu, yu, xl, yl, yc] = naca4(m, p, t, x)
%NACA4  Coordinates of a NACA 4-digit airfoil.
%   [xu, yu, xl, yl, yc] = NACA4(m, p, t, x) returns the upper surface
%   (xu, yu), the lower surface (xl, yl) and the mean camber line yc of a
%   NACA 4-digit section, evaluated at the chordwise stations x (0..1).
%
%   m - maximum camber                 (fraction of chord, NACA 2412: 0.02)
%   p - position of maximum camber     (fraction of chord, NACA 2412: 0.40)
%   t - maximum thickness              (fraction of chord, NACA 2412: 0.12)
%
%   The thickness is laid off normal to the camber line and the trailing
%   edge is closed at (1, 0). This is the same geometry routine that was
%   used to produce the airfoils analysed in XFLR5 for the project report,
%   so x = linspace(0, 1, 100)' reproduces those files exactly.
%
%   Example (NACA 2412):
%       x = linspace(0, 1, 100)';
%       [xu, yu, xl, yl] = naca4(0.02, 0.40, 0.12, x);

x = x(:);

% Mean camber line and its slope (two parabolic arcs joined at x = p)
yc = zeros(size(x));
dyc = zeros(size(x));
fore = x <= p;
yc(fore) = m/p^2 * (2*p*x(fore) - x(fore).^2);
dyc(fore) = 2*m/p^2 * (p - x(fore));
yc(~fore) = m/(1-p)^2 * ((1 - 2*p) + 2*p*x(~fore) - x(~fore).^2);
dyc(~fore) = 2*m/(1-p)^2 * (p - x(~fore));

% Thickness distribution (standard NACA 4-digit polynomial)
yt = 5*t*(0.2969*sqrt(x) - 0.1260*x - 0.3516*x.^2 + 0.2843*x.^3 - 0.1015*x.^4);

% Surfaces: thickness applied normal to the camber line
theta = atan(dyc);
xu = x - yt.*sin(theta);
yu = yc + yt.*cos(theta);
xl = x + yt.*sin(theta);
yl = yc - yt.*cos(theta);

% Close the trailing edge
xu(end) = 1; yu(end) = 0;
xl(end) = 1; yl(end) = 0;
end
