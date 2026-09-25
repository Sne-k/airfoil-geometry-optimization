function [xu, yu, xl, yl, name] = readAirfoil(src)
%READAIRFOIL  Airfoil coordinates from a NACA 4-digit code or a .dat file.
%   [xu, yu, xl, yl, name] = READAIRFOIL('NACA 2412') or READAIRFOIL('2412')
%   builds the section with naca4 (150 cosine-spaced stations, closed
%   trailing edge).
%   READAIRFOIL('file.dat') reads a Selig file (trailing edge -> upper
%   surface -> leading edge -> lower surface -> trailing edge) or a Lednicer
%   file (point counts, then the upper and the lower surface from the
%   leading edge). The name line is optional. Both surfaces are returned
%   from the leading edge to the trailing edge, with the leading edge at
%   (0, 0) and the trailing edge at (1, 0) (translated, rotated and scaled).

src = strtrim(char(src));
code = regexp(upper(src), '^(NACA)?\s*(\d{4})$', 'tokens', 'once');
if ~isempty(code)
    d = code{2} - '0';
    m = d(1) / 100;
    p = d(2) / 10;
    t = (10*d(3) + d(4)) / 100;
    if m == 0, p = 0.4; end                  % symmetric section: p is not used
    x = (1 - cos(linspace(0, pi, 150)')) / 2;
    [xu, yu, xl, yl] = naca4(m, p, t, x, true);
    name = ['NACA ' code{2}];
    return;
end
if ~isempty(regexp(upper(src), '^(NACA)?\s*\d{5,6}$', 'once'))
    error('readAirfoil:code', ['Only NACA 4-digit codes can be generated. ' ...
        'For %s, pass its coordinates as a .dat file.'], src);
end

lines = splitlines(fileread(src));
if numel(sscanf(lines{1}, '%f')) >= 2       % no name line
    [~, name] = fileparts(src);
    first = 1;
else
    name = strtrim(lines{1});
    first = 2;
end
vals = zeros(0, 2);
for k = first:numel(lines)
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

% Leading edge -> (0, 0), trailing-edge midpoint -> (1, 0)
le = up(1, :);
te = (up(end, :) + lo(end, :)) / 2;
c = hypot(te(1) - le(1), te(2) - le(2));
a = atan2(te(2) - le(2), te(1) - le(1));
rot = [cos(a) -sin(a); sin(a) cos(a)] / c;   % rotates by -a and scales
up = (up - le) * rot;
lo = (lo - le) * rot;
xu = up(:, 1);  yu = up(:, 2);
xl = lo(:, 1);  yl = lo(:, 2);
end
