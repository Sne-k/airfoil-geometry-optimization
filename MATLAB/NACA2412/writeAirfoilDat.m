function writeAirfoilDat(filename, name, xu, yu, xl, yl)
%WRITEAIRFOILDAT  Save airfoil coordinates as a .dat file for XFLR5 / XFOIL.
%   WRITEAIRFOILDAT(filename, name, xu, yu, xl, yl) writes the airfoil in
%   the Selig format: one line with the airfoil name, then x y pairs that
%   start at the trailing edge, run over the upper surface to the leading
%   edge and return along the lower surface to the trailing edge. Both
%   surfaces must be ordered from the leading edge to the trailing edge
%   (as returned by naca4); the shared leading-edge point is written once.
%
%   XFLR5 refuses foils with more than 300 points ("Panel number cannot
%   exceed 300"), so larger files are rejected here instead of failing
%   later inside XFLR5. Use about 100 points per surface.

upper = flipud([xu(:), yu(:)]);             % trailing edge -> leading edge
lower = [xl(:), yl(:)];
coords = [upper; lower(2:end, :)];          % leading edge -> trailing edge

if any(~isfinite(coords(:)))
    error('writeAirfoilDat:nonFinite', 'Coordinates contain NaN or Inf values.');
end
if size(coords, 1) > 300
    error('writeAirfoilDat:tooManyPoints', ...
        ['%d points: XFLR5 accepts at most 300 points per foil. ' ...
         'Reduce the number of chordwise stations.'], size(coords, 1));
end
if any(sqrt(sum(diff(coords).^2, 2)) < 1e-9)
    error('writeAirfoilDat:duplicate', 'Consecutive duplicate points found.');
end
if numel(yu) == numel(yl) && any(yu(:) < yl(:) - 1e-9)
    error('writeAirfoilDat:crossing', 'Upper surface lies below the lower surface.');
end

fid = fopen(filename, 'w');
if fid < 0
    error('writeAirfoilDat:open', 'Cannot open %s for writing.', filename);
end
fprintf(fid, '%s\n', name);
fprintf(fid, '%.6f %.6f\n', coords.');
fclose(fid);
end
