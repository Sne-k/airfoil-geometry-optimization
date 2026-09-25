function pol = xfoilPolar(xu, yu, xl, yl, Re, alphaRange, exe)
%XFOILPOLAR  Viscous XFOIL polar of an airfoil.
%   pol = XFOILPOLAR(xu, yu, xl, yl, Re, alphaRange) writes the airfoil
%   (both surfaces ordered from the leading edge to the trailing edge) to a
%   temporary .dat file, lets XFOIL re-panel it (PANE) and runs a viscous
%   angle-of-attack sweep alphaRange = [first last step] (degrees) at the
%   Reynolds number Re, Mach 0 and Ncrit 9. pol has the fields alpha, CL,
%   CD and CM for the converged points (empty if XFOIL failed).
%
%   XFOIL is not part of this repository. Download it from
%   https://web.mit.edu/drela/Public/web/xfoil/ and put xfoil.exe in this
%   folder, set the environment variable XFOIL_EXE, or pass the path of the
%   executable as the 7th argument.

if nargin < 7 || isempty(exe)
    exe = getenv('XFOIL_EXE');
    if isempty(exe)
        exe = fullfile(fileparts(mfilename('fullpath')), 'xfoil.exe');
    end
end
if ~isfile(exe)
    error('xfoilPolar:noXfoil', 'XFOIL executable not found: %s', exe);
end

work = tempname;
mkdir(work);
cleaner = onCleanup(@() rmdir(work, 's'));

coords = [flipud([xu(:) yu(:)]); [xl(2:end) yl(2:end)]];
fid = fopen(fullfile(work, 'af.dat'), 'w');
fprintf(fid, 'airfoil\n');
fprintf(fid, '%.7f %.7f\n', coords.');
fclose(fid);

fid = fopen(fullfile(work, 'cmd.txt'), 'w');
fprintf(fid, ['PLOP\nG F\n\nLOAD af.dat\nPANE\nOPER\nVISC %g\nITER 150\n' ...
    'PACC\npol.txt\n\nASEQ %g %g %g\nPACC\n\nQUIT\n'], Re, alphaRange);
fclose(fid);

% Stop XFOIL after 20 s if it hangs (timeout.exe ships with Git for Windows)
guard = 'C:\Program Files\Git\usr\bin\timeout.exe';
if isfile(guard)
    cmd = sprintf('"%s" 20 "%s"', guard, exe);
else
    cmd = sprintf('"%s"', exe);
end
system(sprintf('cd /d "%s" && %s < cmd.txt > log.txt 2>&1', work, cmd));

pol = struct('alpha', [], 'CL', [], 'CD', [], 'CM', []);
polFile = fullfile(work, 'pol.txt');
if ~isfile(polFile), return; end
lines = splitlines(fileread(polFile));
first = find(startsWith(strtrim(lines), '---'), 1);
if isempty(first), return; end
d = sscanf(strjoin(lines(first+1:end), ' '), '%f');
d = reshape(d(1:7*floor(numel(d)/7)), 7, []).';
if isempty(d), return; end
d = sortrows(d, 1);
% Drop non-physical points: profile drag cannot be lower than the skin
% friction of a fully laminar flat plate on both sides, CD = 2.656/sqrt(Re).
% XFOIL occasionally "converges" to such solutions over several angles.
d = d(d(:, 3) >= 0.9 * 2.656 / sqrt(Re), :);
if isempty(d), return; end
pol.alpha = d(:, 1);
pol.CL = d(:, 2);
pol.CD = d(:, 3);
pol.CM = d(:, 5);
end
