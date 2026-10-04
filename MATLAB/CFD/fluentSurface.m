function S = fluentSurface(profFile, wall, qInf)
%FLUENTSURFACE  Pressure and skin friction on the airfoil from a Fluent run.
%   S = FLUENTSURFACE(profFile, wall, qInf) reads the profile file that a
%   journal from fluentJournal writes with the option 'Surface' (pressure
%   coefficient and wall shear stress at the midpoints of the wall faces)
%   and orders the points along the airfoil. wall is the list of the wall
%   nodes of the mesh in grid order (lower trailing edge, leading edge,
%   upper trailing edge; n-by-2, as written to <mesh>_wall.csv by the batch
%   scripts) and qInf the free-stream dynamic pressure in Pa.
%
%   S is a table with one row per wall face, from the lower trailing edge
%   around the leading edge to the upper trailing edge: surface ('lower'
%   or 'upper'), x, y, cp, and cf, the skin friction coefficient along the
%   surface, positive when the wall shear points downstream (towards the
%   trailing edge) and negative in reversed flow.
%
%   [xtr] = transition can be estimated from cf with transitionFromCf.

txt = fileread(profFile);
tok = regexp(txt, '\(([A-Za-z][\w-]*)\s*\n([^()]*)\)', 'tokens');
P = struct();
for k = 1:numel(tok)
    P.(matlab.lang.makeValidName(strrep(tok{k}{1}, '-', '_'))) = sscanf(tok{k}{2}, '%f');
end
mid = (wall(1:end-1, :) + wall(2:end, :)) / 2;
tangent = diff(wall);
tangent = tangent ./ vecnorm(tangent, 2, 2);
[d, j] = min((P.x - mid(:, 1)').^2 + (P.y - mid(:, 2)').^2, [], 2);     % wall face of every profile point
if numel(unique(j)) ~= numel(j) || numel(j) ~= size(mid, 1) || sqrt(max(d)) > 1e-5
    error('fluentSurface:match', 'The profile points do not match the wall faces of the mesh.');
end
[~, order] = sort(j);
[~, iLE] = min(sum(wall.^2, 2));                    % leading-edge node (0, 0)
down = ones(size(mid, 1), 1);
down(1:iLE-1) = -1;                                 % on the lower surface the grid runs upstream
surface = repmat({'upper'}, size(mid, 1), 1);
surface(1:iLE-1) = {'lower'};
tau = P.x_wall_shear(order) .* tangent(:, 1) + P.y_wall_shear(order) .* tangent(:, 2);
S = table(surface, mid(:, 1), mid(:, 2), P.pressure_coefficient(order), down .* tau / qInf, ...
    'VariableNames', {'surface', 'x', 'y', 'cp', 'cf'});
end
