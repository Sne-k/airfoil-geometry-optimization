function [xu, yu, xl, yl, name] = readAirfoil(src)
%READAIRFOIL  Airfoil coordinates from a NACA 4-digit code or a .dat file.
%   [xu, yu, xl, yl, name] = READAIRFOIL('NACA 2412') or READAIRFOIL('2412')
%   builds the section with naca4 (150 cosine-spaced stations).
%   READAIRFOIL('file.dat') reads a Selig file (trailing edge -> upper
%   surface -> leading edge -> lower surface -> trailing edge) or a Lednicer
%   file (point counts, then the upper and the lower surface from the
%   leading edge). Both surfaces are returned from the leading edge to the
%   trailing edge, scaled to unit chord with the leading edge at (0, 0).

src = strtrim(char(src));
code = regexp(upper(src), '^(NACA)?\s*(\d{4})$', 'tokens', 'once');
if ~isempty(code)
    d = code{2} - '0';
    m = d(1) / 100;
    p = d(2) / 10;
    t = (10*d(3) + d(4)) / 100;
    if m == 0, p = 0.4; end                  % symmetric section: p is not used
    x = (1 - cos(linspace(0, pi, 150)')) / 2;
    [xu, yu, xl, yl] = naca4(m, p, t, x);
    name = ['NACA ' code{2}];
    return;
end

lines = splitlines(fileread(src));
name = strtrim(lines{1});
vals = zeros(0, 2);
for k = 2:numel(lines)
    v = sscanf(lines{k}, '%f').';
    if numel(v) >= 2
        vals(end+1, :) = v(1:2); %#ok<AGROW>
    end
end
if vals(1, 1) > 1.5                          % Lednicer: first row holds the point counts
    nu = round(vals(1, 1));
    nl = round(vals(1, 2));
    up = vals(2:1+nu, :);
    lo = vals(2+nu:1+nu+nl, :);
else                                         % Selig
    [~, iLE] = min(vals(:, 1));
    up = flipud(vals(1:iLE, :));
    lo = vals(iLE:end, :);
end

le = up(1, :);                               % leading edge -> origin, unit chord
c = (up(end, 1) + lo(end, 1)) / 2 - le(1);
xu = (up(:, 1) - le(1)) / c;  yu = (up(:, 2) - le(2)) / c;
xl = (lo(:, 1) - le(1)) / c;  yl = (lo(:, 2) - le(2)) / c;
end
