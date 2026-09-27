function info = writeFluentMesh(file, G, flipFaces)
%WRITEFLUENTMESH  Writes a C-grid from airfoilCGrid as a Fluent ASCII mesh.
%   info = WRITEFLUENTMESH(file, G) writes the quadrilateral mesh with the
%   zones 'fluid' (cells), 'int_fluid' (interior faces, including the wake
%   cut), 'airfoil' (wall) and 'farfield' (pressure far field: outer
%   boundary and outlet). Nodes on the two sides of the wake cut are merged.
%   Face connectivity follows Fluent's convention for 2-D meshes: walking
%   from n0 to n1, cell c0 is on the left and c1 on the right (c1 = 0 on
%   boundaries); this was verified with Fluent's mesh check (all volumes
%   positive, no left-handed faces). flipFaces = true writes the opposite
%   orientation (for testing). Indices in the file are hexadecimal.

if nargin < 3, flipFaces = false; end
[Ni, Nj] = size(G.X);
iTE = G.iTE;

%% Node numbering (the wake cut shares its nodes)
id = reshape(1:Ni*Nj, Ni, Nj);
iu = iTE(2):Ni;                              % upper wake at j = 1 ...
id(iu, 1) = id(Ni + 1 - iu, 1);              % ... is the lower wake mirrored
[used, ~, newId] = unique(id(:));
id = reshape(newId, Ni, Nj);
xy = [G.X(used), G.Y(used)];
nNodes = size(xy, 1);

%% Cells (counter-clockwise quads)
[I, J] = ndgrid(1:Ni-1, 1:Nj-1);
I = I(:);  J = J(:);
q = [id(sub2ind([Ni Nj], I, J)), id(sub2ind([Ni Nj], I+1, J)), ...
     id(sub2ind([Ni Nj], I+1, J+1)), id(sub2ind([Ni Nj], I, J+1))];
nCells = size(q, 1);
area = polyAreas(xy, q);
info.minArea = min(area);
info.nNegative = sum(area <= 0);

%% Faces: every directed cell edge has its cell on the left
e = [q(:, [1 2]); q(:, [2 3]); q(:, [3 4]); q(:, [4 1])];
c = repmat((1:nCells)', 4, 1);
key = sort(e, 2);
[~, ia, ic] = unique(key, 'rows', 'stable');
count = accumarray(ic, 1);
edgeKind = count(ic);
% interior faces: keep the first occurrence (a -> b, left cell = c), the other cell is on the right
first = false(size(ic));  first(ia) = true;
intIdx = find(first & edgeKind == 2);
other = zeros(numel(ia), 1);
second = find(~first);
other(ic(second)) = c(second);
F_int = [e(intIdx, :), other(ic(intIdx)), c(intIdx)];       % built with c0 on the right of n0 -> n1
% boundary faces: reversed, so that the cell is on the right (c0)
bIdx = find(edgeKind == 1);
F_b = [e(bIdx, [2 1]), c(bIdx), zeros(numel(bIdx), 1)];
if ~flipFaces                                % Fluent: c0 on the left of n0 -> n1
    F_int = F_int(:, [2 1 3 4]);
    F_b = F_b(:, [2 1 3 4]);
end

%% Boundary classification: wall = airfoil nodes at j = 1
wallNode = false(nNodes, 1);
wallNode(id(iTE(1):iTE(2), 1)) = true;
isWall = wallNode(F_b(:, 1)) & wallNode(F_b(:, 2));
F_wall = F_b(isWall, :);
F_far = F_b(~isWall, :);
info.nWall = size(F_wall, 1);  info.nFar = size(F_far, 1);  info.nInterior = size(F_int, 1);
info.nNodes = nNodes;  info.nCells = nCells;

%% Write
nInt = size(F_int, 1);  nWall = size(F_wall, 1);  nFar = size(F_far, 1);
nFaces = nInt + nWall + nFar;
fid = fopen(file, 'w');
cleaner = onCleanup(@() fclose(fid));
fprintf(fid, '(0 "C-grid airfoil mesh written by writeFluentMesh.m")\n');
fprintf(fid, '(2 2)\n');
fprintf(fid, '(10 (0 1 %x 0 2))\n', nNodes);
fprintf(fid, '(10 (1 1 %x 1 2)(\n', nNodes);
fprintf(fid, '%.12e %.12e\n', xy.');
fprintf(fid, '))\n');
fprintf(fid, '(12 (0 1 %x 0))\n', nCells);
fprintf(fid, '(12 (2 1 %x 1 3))\n', nCells);
fprintf(fid, '(13 (0 1 %x 0))\n', nFaces);
writeFaces(fid, 3, 1, nInt, 2, F_int);
writeFaces(fid, 4, nInt + 1, nInt + nWall, 3, F_wall);
writeFaces(fid, 5, nInt + nWall + 1, nFaces, 9, F_far);
fprintf(fid, '(45 (2 fluid fluid)())\n');
fprintf(fid, '(45 (3 interior int_fluid)())\n');
fprintf(fid, '(45 (4 wall airfoil)())\n');
fprintf(fid, '(45 (5 pressure-far-field farfield)())\n');
end

function writeFaces(fid, zone, first, last, bcType, F)
fprintf(fid, '(13 (%x %x %x %x 2)(\n', zone, first, last, bcType);
fprintf(fid, '%x %x %x %x\n', F.');
fprintf(fid, '))\n');
end

function a = polyAreas(xy, q)
x = reshape(xy(q, 1), size(q));  y = reshape(xy(q, 2), size(q));
a = 0.5 * sum(x .* y(:, [2 3 4 1]) - x(:, [2 3 4 1]) .* y, 2);
end
