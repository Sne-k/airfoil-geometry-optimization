function exportAirfoilDat(p, filename, name)
    % Generate airfoil coordinates from PARSEC parameters and export as .dat
    % (Selig format: trailing edge -> upper surface -> leading edge -> lower
    % surface -> trailing edge), ready for XFLR5 / XFOIL.
    %
    % Source: reference implementation used in El Houd & Hallou (2022),
    % ref. [5] of the project report. Changed for this repository: 100
    % cosine-spaced points per surface (199 in total) instead of 201,
    % because XFLR5 rejects foils with more than 300 points.

    if nargin < 3
        name = 'PARSEC airfoil';
    end

    a = parsec(p);  % Get PARSEC coefficients

    x0 = (1 - cos(linspace(0, pi, 100)')) / 2;   % cosine-spaced x-coordinates
    Z_u0 = zeros(size(x0));
    Z_d0 = zeros(size(x0));
    for k = 1:numel(x0)
        [Z_u0(k), Z_d0(k)] = yCoord2(a, x0(k));  % upper and lower surface
    end

    % Create full airfoil coordinates
    upper = [flipud(x0), flipud(Z_u0)];  % Upper surface: TE -> LE
    lower = [x0(2:end), Z_d0(2:end)];    % Lower surface: LE -> TE (skip point already used)
    coords = [upper; lower];

    % Write to .dat file
    fid = fopen(filename, 'w');
    if fid < 0
        error('exportAirfoilDat: cannot open %s for writing.', filename);
    end
    fprintf(fid, '%s\n', name);
    fprintf(fid, '%.6f %.6f\n', coords.');
    fclose(fid);
end
