function pol = xfoilPolar(xu, yu, xl, yl, Re, alphaRange, exe, panels)
%XFOILPOLAR  Viscous XFOIL polar of an airfoil.
%   pol = XFOILPOLAR(xu, yu, xl, yl, Re, alphaRange) writes the airfoil
%   (both surfaces ordered from the leading edge to the trailing edge) to a
%   temporary .dat file, lets XFOIL re-panel it (PANE) and runs a viscous
%   angle-of-attack sweep alphaRange = [first last step] (degrees) at the
%   Reynolds number Re, Mach 0 and Ncrit 9. pol has the fields alpha, CL,
%   CD and CM for the converged points (empty if XFOIL failed).
%
%   The sweep is split in two XFOIL runs: from the angle closest to 0 up to
%   the last angle, and from there down to the first angle. Angles near 0
%   converge most easily, and a failure at one end (stall, or lower-surface
%   separation of thin cambered sections at negative angles) cannot spoil
%   the other end or use up its time limit.
%
%   pol = XFOILPOLAR(..., exe, panels) re-panels with the given number of
%   panel nodes instead of XFOIL's default (160).
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
if nargin < 8, panels = []; end
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

a = alphaRange(1):alphaRange(3):alphaRange(2);
[~, i0] = min(abs(a));
d = [runSweep(work, exe, Re, a(i0:end), panels, 'up'); ...
     runSweep(work, exe, Re, a(i0-1:-1:1), panels, 'down')];

pol = struct('alpha', [], 'CL', [], 'CD', [], 'CM', []);
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

function d = runSweep(work, exe, Re, angles, panels, tag)
% One XFOIL run over the given angles; returns the rows of its polar file
d = zeros(0, 7);
if isempty(angles), return; end
step = 1;
if numel(angles) > 1, step = angles(2) - angles(1); end
if isempty(panels)
    pane = 'PANE\n';
else
    pane = sprintf('PPAR\nN %d\n\n\n', panels);
end
fid = fopen(fullfile(work, ['cmd_' tag '.txt']), 'w');
fprintf(fid, ['PLOP\nG F\n\nLOAD af.dat\n' pane 'OPER\nVISC %g\nITER 150\n' ...
    'PACC\npol_%s.txt\n\nASEQ %g %g %g\nPACC\n\nQUIT\n'], Re, tag, angles(1), angles(end), step);
fclose(fid);

% Stop XFOIL if it hangs: 10 s plus 0.5 s per angle (timeout.exe ships with
% Git for Windows)
guard = 'C:\Program Files\Git\usr\bin\timeout.exe';
if isfile(guard)
    cmd = sprintf('"%s" %d "%s"', guard, ceil(10 + 0.5*numel(angles)), exe);
else
    cmd = sprintf('"%s"', exe);
end
system(sprintf('cd /d "%s" && %s < cmd_%s.txt > log_%s.txt 2>&1', work, cmd, tag, tag));

polFile = fullfile(work, ['pol_' tag '.txt']);
if ~isfile(polFile), return; end
lines = splitlines(fileread(polFile));
first = find(startsWith(strtrim(lines), '---'), 1);
if isempty(first), return; end
v = sscanf(strjoin(lines(first+1:end), ' '), '%f');
d = reshape(v(1:7*floor(numel(v)/7)), 7, []).';
end
