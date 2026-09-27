function [xu, yu, xl, yl, yc] = naca5(code, x, closedTE)
%NACA5  Coordinates of a NACA 5-digit airfoil.
%   [xu, yu, xl, yl, yc] = NACA5(code, x) returns the upper and lower
%   surfaces and the mean camber line of the NACA 5-digit section code
%   (e.g. '23012'), evaluated at the chordwise stations x (0..1).
%
%   Digits L P Q XX: design lift coefficient 0.15*L, position of maximum
%   camber 0.05*P, Q = 0 standard or 1 reflexed mean line, and thickness
%   XX percent. Mean-line constants for P = 1..5 are the standard values
%   (Abbott & von Doenhoff, Theory of Wing Sections), scaled linearly with
%   the design lift coefficient. The thickness distribution and its
%   application normal to the camber line are the same as in naca4;
%   NACA5(code, x, true) uses the closed-trailing-edge coefficient.
%
%   Example:
%       x = (1 - cos(linspace(0, pi, 150)')) / 2;
%       [xu, yu, xl, yl] = naca5('23012', x, true);

if nargin < 3, closedTE = false; end
d = char(code) - '0';
if numel(d) ~= 5 || any(d < 0 | d > 9)
    error('naca5:code', 'Expected a 5-digit code such as ''23012''.');
end
L = d(1); P = d(2); Q = d(3); t = (10*d(4) + d(5)) / 100;
x = x(:);

% Mean line for a design lift coefficient of 0.3, then scaled
if Q == 0
    rTab = [0.0580 0.1260 0.2025 0.2900 0.3910];
    kTab = [361.400 51.640 15.957 6.643 3.230];
    if P < 1 || P > 5, error('naca5:code', 'P must be 1 to 5.'); end
    r = rTab(P); k1 = kTab(P);
    fore = x < r;
    yc = zeros(size(x)); dyc = zeros(size(x));
    yc(fore) = k1/6 * (x(fore).^3 - 3*r*x(fore).^2 + r^2*(3 - r)*x(fore));
    dyc(fore) = k1/6 * (3*x(fore).^2 - 6*r*x(fore) + r^2*(3 - r));
    yc(~fore) = k1*r^3/6 * (1 - x(~fore));
    dyc(~fore) = -k1*r^3/6;
elseif Q == 1
    rTab = [NaN 0.1300 0.2170 0.3180 0.4410];
    kTab = [NaN 51.990 15.793 6.520 3.191];
    k21Tab = [NaN 0.000764 0.00677 0.0303 0.1355];
    if P < 2 || P > 5, error('naca5:code', 'Reflexed mean lines need P = 2 to 5.'); end
    r = rTab(P); k1 = kTab(P); k21 = k21Tab(P);
    fore = x < r;
    yc = zeros(size(x)); dyc = zeros(size(x));
    xf = x(fore); xa = x(~fore);
    yc(fore) = k1/6 * ((xf - r).^3 - k21*(1 - r)^3*xf - r^3*xf + r^3);
    dyc(fore) = k1/6 * (3*(xf - r).^2 - k21*(1 - r)^3 - r^3);
    yc(~fore) = k1/6 * (k21*(xa - r).^3 - k21*(1 - r)^3*xa - r^3*xa + r^3);
    dyc(~fore) = k1/6 * (3*k21*(xa - r).^2 - k21*(1 - r)^3 - r^3);
else
    error('naca5:code', 'The third digit must be 0 or 1.');
end
scale = 0.15*L / 0.3;
yc = scale * yc;
dyc = scale * dyc;

% Thickness (as in naca4)
a4 = -0.1015;
if closedTE, a4 = -0.1036; end
yt = 5*t*(0.2969*sqrt(x) - 0.1260*x - 0.3516*x.^2 + 0.2843*x.^3 + a4*x.^4);
theta = atan(dyc);
xu = x - yt.*sin(theta);
yu = yc + yt.*cos(theta);
xl = x + yt.*sin(theta);
yl = yc - yt.*cos(theta);
xu(end) = 1; yu(end) = 0;
xl(end) = 1; yl(end) = 0;
end
