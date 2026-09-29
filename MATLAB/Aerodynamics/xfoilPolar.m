function [pol, info] = xfoilPolar(xu, yu, xl, yl, Re, alphaRange, exe, panels, restarts, flow)
%XFOILPOLAR  Viscous XFOIL polar of an airfoil.
%   pol = XFOILPOLAR(xu, yu, xl, yl, Re, alphaRange) writes the airfoil
%   (both surfaces ordered from the leading edge to the trailing edge) to a
%   temporary .dat file, lets XFOIL re-panel it (PANE) and runs a viscous
%   angle-of-attack sweep alphaRange = [first last step] (degrees) at the
%   Reynolds number Re, Mach 0 and Ncrit 9. pol has the fields alpha, CL,
%   CD, CM and the transition locations xtrTop and xtrBot (x/c) for the
%   converged points (empty if XFOIL failed).
%
%   The sweep is split in two XFOIL runs: from the angle closest to 0 up to
%   the last angle, and from there down to the first angle. Angles near 0
%   converge most easily, and a failure at one end (stall, or lower-surface
%   separation of thin cambered sections at negative angles) cannot spoil
%   the other end or use up its time limit. If XFOIL stops converging
%   before the end of a part, it is restarted from the last converged angle
%   with half the step, and the restart is kept only if it reproduces that
%   angle (up to three times per part). Points with a drag below the
%   laminar flat-plate value, or on a spurious low-drag branch outside the
%   drag bucket, are removed.
%
%   pol = XFOILPOLAR(..., exe, panels) re-panels with the given number of
%   panel nodes instead of XFOIL's default (160). pol = XFOILPOLAR(..., exe,
%   panels, false) turns the restarts off. The optimisers do this: it is
%   much faster for shapes that do not converge, and a polar that stops
%   early is penalised there anyway.
%
%   pol = XFOILPOLAR(..., restarts, flow) changes the flow settings; flow is
%   a struct with any of the fields Mach (default 0; XFOIL applies the
%   Karman-Tsien correction), Ncrit (default 9, the e^n transition
%   criterion) and Xtr ([top bottom] forced transition x/c, default [1 1] =
%   free transition). [pol, info] = XFOILPOLAR(...) also returns the header
%   of XFOIL's polar file (info.header), which lists the settings XFOIL used.
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
if nargin < 9 || isempty(restarts), restarts = true; end
if nargin < 10 || isempty(flow), flow = struct(); end
if ~isfile(exe)
    error('xfoilPolar:noXfoil', 'XFOIL executable not found: %s', exe);
end
% Flow settings; nothing is added to the commands for the defaults
flowCmd = '';
if isfield(flow, 'Mach') && flow.Mach ~= 0
    flowCmd = sprintf('MACH %g\n', flow.Mach);
end
vpar = '';
if isfield(flow, 'Ncrit') && flow.Ncrit ~= 9
    vpar = [vpar sprintf('N %g\n', flow.Ncrit)];
end
if isfield(flow, 'Xtr') && any(flow.Xtr ~= 1)
    vpar = [vpar sprintf('XTR %g %g\n', flow.Xtr(1), flow.Xtr(2))];
end
if ~isempty(vpar)
    flowCmd = [flowCmd sprintf('VPAR\n') vpar newline];
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
[dUp, info.header] = sweepWithRestarts(work, exe, Re, a(i0:end), panels, 'up', restarts, flowCmd);
d = [dUp; sweepWithRestarts(work, exe, Re, a(i0-1:-1:1), panels, 'down', restarts, flowCmd)];

pol = struct('alpha', [], 'CL', [], 'CD', [], 'CM', [], 'xtrTop', [], 'xtrBot', []);
if isempty(d), return; end
d = sortrows(d, 1);
[~, iu] = unique(d(:, 1));                   % one point per angle
d = d(iu, :);
% Drop non-physical points: profile drag cannot be lower than the skin
% friction of a fully laminar flat plate on both sides, CD = 2.656/sqrt(Re).
% XFOIL occasionally "converges" to such solutions over several angles.
d = d(d(:, 3) >= 0.9 * 2.656 / sqrt(Re), :);
if isempty(d), return; end
d = dragRiseFilter(d);
pol.alpha = d(:, 1);
pol.CL = d(:, 2);
pol.CD = d(:, 3);
pol.CM = d(:, 5);
pol.xtrTop = d(:, 6);
pol.xtrBot = d(:, 7);
end

function d = dragRiseFilter(d)
% Outside the drag bucket, drag grows as the angle of attack moves away from
% it. XFOIL sometimes converges to a spurious low-drag branch there (seen
% after restarts on thin sections: CD 0.006 where the neighbouring angles
% have 0.016). Drop points whose drag is below 80 % of the highest drag
% between them and the drag minimum.
[~, iMin] = min(d(:, 3));
keep = true(size(d, 1), 1);
for dir = [1 -1]
    cdMax = 0;
    for k = iMin + dir : dir : (dir > 0)*size(d, 1) + (dir < 0)
        if d(k, 3) < 0.8 * cdMax
            keep(k) = false;
        else
            cdMax = max(cdMax, d(k, 3));
        end
    end
end
d = d(keep, :);
end

function [d, header] = sweepWithRestarts(work, exe, Re, angles, panels, tag, restarts, flowCmd)
% Sweeps over angles. Once a solution diverges, XFOIL starts every
% following angle from it and usually fails on all of them. If the sweep
% stops converging before the last angle, it is restarted from the last
% converged angle with a fresh boundary layer and half the step (up to
% three times). The restart must first reproduce the last converged point
% (CL/CD within 2 %); otherwise its results are discarded, because a fresh
% start can land on a different, spurious solution.
[d, header] = runSweep(work, exe, Re, angles, panels, [tag '1'], flowCmd);
if ~restarts || isempty(d) || numel(angles) < 2, return; end
step = angles(2) - angles(1);
for attempt = 2:4
    j = find(abs(angles - d(end, 1)) < 1e-6, 1);   % last converged angle
    if isempty(j) || j == numel(angles), break; end
    r = runSweep(work, exe, Re, angles(j):step/2:angles(end), panels, sprintf('%s%d', tag, attempt), flowCmd);
    ld0 = d(end, 2) / d(end, 3);
    if isempty(r) || abs(r(1, 1) - d(end, 1)) > 1e-6 || abs(r(1, 2)/r(1, 3) - ld0) > 0.02*abs(ld0)
        break;
    end
    r = r(2:end, :);                                          % drop the repeated angle
    r = r(any(abs(r(:, 1) - angles(:).') < 1e-6, 2), :);     % original angles only
    if isempty(r), break; end
    d = [d; r]; %#ok<AGROW>
end
end

function [d, header] = runSweep(work, exe, Re, angles, panels, tag, flowCmd)
% One XFOIL run over the given angles; returns the rows of its polar file
% and the header lines above them
d = zeros(0, 7);
header = '';
if isempty(angles), return; end
step = 1;
if numel(angles) > 1, step = angles(2) - angles(1); end
if isempty(panels)
    pane = 'PANE\n';
else
    pane = sprintf('PPAR\nN %d\n\n\n', panels);
end
fid = fopen(fullfile(work, ['cmd_' tag '.txt']), 'w');
fprintf(fid, ['PLOP\nG F\n\nLOAD af.dat\n' pane 'OPER\nVISC %g\n' flowCmd 'ITER 150\n' ...
    'PACC\npol_%s.txt\n\nASEQ %g %g %g\nPACC\n\nQUIT\n'], Re, tag, angles(1), angles(end), step);
fclose(fid);

% Stop XFOIL if it hangs: 60 s plus 2 s per angle (timeout.exe ships with
% Git for Windows). A converging sweep needs a few seconds, so the limit
% only stops a hanging XFOIL. It is generous on purpose: with a tight limit
% (formerly 10 s plus 0.5 s per angle) a machine slowed down by the
% operating system (e.g. a laptop in standby with the screen off) cut
% sweeps short, and the results depended on the speed of the machine.
guard = 'C:\Program Files\Git\usr\bin\timeout.exe';
if isfile(guard)
    cmd = sprintf('"%s" %d "%s"', guard, ceil(60 + 2*numel(angles)), exe);
else
    cmd = sprintf('"%s"', exe);
end
system(sprintf('cd /d "%s" && %s < cmd_%s.txt > log_%s.txt 2>&1', work, cmd, tag, tag));

polFile = fullfile(work, ['pol_' tag '.txt']);
if ~isfile(polFile), return; end
lines = splitlines(fileread(polFile));
first = find(startsWith(strtrim(lines), '---'), 1);
if isempty(first), return; end
header = strjoin(lines(1:first-1), newline);
v = sscanf(strjoin(lines(first+1:end), ' '), '%f');
d = reshape(v(1:7*floor(numel(v)/7)), 7, []).';
end
