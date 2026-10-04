function G = airfoilCGrid(xu, yu, xl, yl, varargin)
%AIRFOILCGRID  Structured C-grid around an airfoil for 2-D CFD.
%   G = AIRFOILCGRID(xu, yu, xl, yl) builds a C-type grid around the airfoil
%   (both surfaces from the leading edge to a closed trailing edge at
%   (1, 0)). The grid wraps around the airfoil and a wake cut that runs
%   from the trailing edge to the outlet. G.X and G.Y are Ni x Nj node
%   arrays: i runs from the lower outlet along the wake cut, clockwise
%   around the airfoil (lower surface, leading edge, upper surface) and back
%   along the wake cut to the upper outlet; j runs from the wall (j = 1) to
%   the far field. G.iTE = [i of the lower trailing edge, i of the upper
%   trailing edge]; nodes 1..iTE(1) and iTE(2)..Ni at j = 1 lie on the wake
%   cut and coincide pairwise.
%
%   Options (name, value), defaults in brackets:
%     'NSurface'  points per surface, leading to trailing edge   (201)
%     'NWake'     points along the wake cut                        (80)
%     'NNormal'   points from the wall to the far field           (150)
%     'Radius'    far-field radius in chords                       (20)
%     'WakeLength' wake length in chords                           (20)
%     'FirstCell' first cell height at the wall in chords        (1e-5)
%     'WakeFirstCell' first cell height at the outlet, next to the
%                 wake cut (it grows linearly along the wake)      (5e-3)
%
%   The grid is marched outwards from the wall along smoothed normals up to
%   about one chord, so the near-wall cells are orthogonal and grid lines do
%   not cross. From there straight lines lead to a C-shaped far-field
%   boundary: lines y = -Radius and y = +Radius behind the trailing edge and a
%   half circle of that radius around the airfoil. With
%   FirstCell = 1e-5 the first cell is at y+ < 1 for Re = 1e6.

ip = inputParser;
ip.addParameter('NSurface', 201);
ip.addParameter('NWake', 80);
ip.addParameter('NNormal', 150);
ip.addParameter('Radius', 20);
ip.addParameter('WakeLength', 20);
ip.addParameter('FirstCell', 1e-5);
ip.addParameter('WakeFirstCell', 5e-3);
ip.parse(varargin{:});
o = ip.Results;

%% Surface points: clustered at the leading edge, moderately at the trailing edge
% The points are placed by arc length along each surface. Just behind the
% nose of a cambered section the upper surface reaches slightly ahead of
% x = 0 (NACA 2412: x = -7.5e-5), so y is not a function of x there;
% interpolating y(x) corrupted the nose and made the CFD diverge.
t = linspace(0, 1, o.NSurface)';
w = 0.8;
f = w * (1 - cos(pi*t)) / 2 + (1 - w) * (1 - cos(pi*t/2));
[xus, yus] = alongSurface(xu, yu, f);
[xls, yls] = alongSurface(xl, yl, f);
xus([1 end]) = [0 1];  yus([1 end]) = 0;          % closed at (0,0) and (1,0)
xls([1 end]) = [0 1];  yls([1 end]) = 0;

%% Wake cut: geometric growth from the trailing-edge spacing to the outlet
h0 = mean([hypot(1 - xus(end-1), yus(end-1)), hypot(1 - xls(end-1), yls(end-1))]);
r = fzero(@(r) h0 * (r^(o.NWake) - 1) / (r - 1) - o.WakeLength, [1.0001 2]);
xw = 1 + h0 * (r.^(1:o.NWake)' - 1) / (r - 1);

%% Inner boundary (j = 1), clockwise: lower wake -> lower surface -> upper surface -> upper wake
xin = [flipud(xw); flipud(xls); xus(2:end); xw];
yin = [zeros(o.NWake, 1); flipud(yls); yus(2:end); zeros(o.NWake, 1)];
Ni = numel(xin);
iTE = [o.NWake + 1, o.NWake + 2*o.NSurface - 1];

%% March outwards from the wall, layer by layer
% Each layer moves along the smoothed normals of the previous one by a
% geometrically growing step, so the near-wall cells are orthogonal and grid
% lines cannot cross. The normals are smoothed more the further the layer is
% from the wall (none at the wall); along the wake cut the lines are
% vertical.
R = o.Radius;
Nj = o.NNormal;
rj = fzero(@(r) o.FirstCell * (r^(Nj - 1) - 1) / (r - 1) - R, [1.0001 2]);
ds = o.FirstCell * rj.^(0:Nj-2)';
X = zeros(Ni, Nj);  Y = zeros(Ni, Nj);
X(:, 1) = xin;  Y(:, 1) = yin;
% Behind the maximum thickness the surface slopes towards the wake cut, so
% its normals lean backwards and would converge with the vertical lines of
% the wake. From 30 % to 50 % chord they are turned gradually to the
% vertical; ahead of that the lines fan out around the nose.
w = zeros(Ni, 1);
ia = iTE(1):iTE(2);
w(ia) = min(1, max(0, (xin(ia) - 0.3) / 0.2));
up = (1:Ni)' > (iTE(1) + iTE(2)) / 2;                 % upper half of the C
vert = [zeros(Ni, 1), 2*up - 1];
dist = [0; cumsum(ds)];
jSwitch = find(dist >= 1, 1);                     % march out to about one chord
% Next to the wake cut there is no wall, so the first cell grows along the
% wake (a 1e-5 cell 20 chords downstream would give aspect ratios near 1e5,
% which the solver does not tolerate). Every point keeps the same marching
% distance with its own growth ratio.
n = jSwitch - 1;
D = dist(jSwitch);
h1 = o.FirstCell * ones(Ni, 1);
wk = [1:iTE(1)-1, iTE(2)+1:Ni];
h1(wk) = o.FirstCell + (o.WakeFirstCell - o.FirstCell) * (xin(wk) - 1) / o.WakeLength;
DS = repmat(ds(1:n).', Ni, 1);
for i = wk
    if h1(i) * n >= D
        DS(i, :) = D / n;
    else
        ri = fzero(@(r) h1(i) * (r^n - 1) / (r - 1) - D, [1 + 1e-9, 2]);
        DS(i, :) = h1(i) * ri.^(0:n-1);
    end
end
for k = 1:jSwitch-1
    P = [X(:, k), Y(:, k)];
    T = [P(2, :) - P(1, :); P(3:end, :) - P(1:end-2, :); P(end, :) - P(end-1, :)];
    Nrm = [-T(:, 2), T(:, 1)];                      % the fluid is to the left (clockwise boundary)
    Nrm = Nrm ./ vecnorm(Nrm, 2, 2);
    Nrm(wk, :) = vert(wk, :);                       % wake lines vertical (also before smoothing)
    Nrm = (1 - w) .* Nrm + w .* vert;
    Nrm = Nrm ./ vecnorm(Nrm, 2, 2);
    for p = 1:floor(40*k/Nj)
        Nrm(2:end-1, :) = (Nrm(1:end-2, :) + 2*Nrm(2:end-1, :) + Nrm(3:end, :)) / 4;
        Nrm = Nrm ./ vecnorm(Nrm, 2, 2);
    end
    Nrm(wk, :) = vert(wk, :);
    X(:, k+1) = P(:, 1) + DS(:, k) .* Nrm(:, 1);
    Y(:, k+1) = P(:, 2) + DS(:, k) .* Nrm(:, 2);
end

%% Beyond one chord: straight lines to a C-shaped outer boundary
% lines y = -R and y = +R behind the trailing edge and a half circle around
% the airfoil, matched to the last marched layer by relative arc length
P = [X(:, jSwitch), Y(:, jSwitch)];
B = zeros(Ni, 2);
seg = {1:iTE(1), iTE(1):iTE(2), iTE(2):Ni};
for m = 1:3
    idx = seg{m};
    u = [0; cumsum(vecnorm(diff(P(idx, :)), 2, 2))];
    u = u / u(end);
    switch m
        case 1, B(idx, :) = [xin(1) + (1 - xin(1)) * u, -R * ones(numel(idx), 1)];
        case 2, phi = 3*pi/2 - pi*u;  B(idx, :) = [1 + R*cos(phi), R*sin(phi)];
        case 3, B(idx, :) = [1 + (xin(end) - 1) * u, R * ones(numel(idx), 1)];
    end
end
rest = dist(jSwitch:end) - dist(jSwitch);
rest = rest / rest(end);
for k = jSwitch+1:Nj
    X(:, k) = P(:, 1) + rest(k - jSwitch + 1) * (B(:, 1) - P(:, 1));
    Y(:, k) = P(:, 2) + rest(k - jSwitch + 1) * (B(:, 2) - P(:, 2));
end

G = struct('X', X, 'Y', Y, 'iTE', iTE, 'firstCell', o.FirstCell, 'growth', rj, 'wakeGrowth', r);
end

function [xs, ys] = alongSurface(x, y, f)
% Points at the fractions f of the arc length of a surface (x, y), ordered
% from the leading edge to the trailing edge
x = x(:);  y = y(:);
s = [0; cumsum(hypot(diff(x), diff(y)))];
[s, i] = unique(s);
s = s / s(end);
xs = interp1(s, x(i), f, 'pchip');
ys = interp1(s, y(i), f, 'pchip');
end
