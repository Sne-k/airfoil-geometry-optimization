function fluentJournal(file, meshFile, alpha, varargin)
%FLUENTJOURNAL  Writes a Fluent batch journal for one airfoil case.
%   FLUENTJOURNAL(file, meshFile, alpha) sets up a 2-D steady RANS case on a
%   mesh from writeFluentMesh: ideal-gas air at Mach 0.1 with the viscosity
%   chosen for Re = 1e6 (chord 1 m), pressure far field at angle of attack
%   alpha (degrees), second-order discretisation, and prints the lift and
%   drag coefficients after every block of iterations.
%
%   Options (name, value), defaults in brackets:
%     'Model'       'transition' (Transition SST, gamma-Re_theta) or 'sst'
%                   (fully turbulent k-omega SST)                ('transition')
%     'Intensity'   free-stream turbulence intensity in percent     (0.1)
%     'ViscRatio'   free-stream turbulent viscosity ratio            (10)
%     'Blocks'      number of iteration blocks                        (8)
%     'BlockSize'   iterations per block                            (250)
%
%   The prompt sequences were checked against Fluent 2026 R1 (student).

ip = inputParser;
ip.addParameter('Model', 'transition');
ip.addParameter('Intensity', 0.1);
ip.addParameter('ViscRatio', 10);
ip.addParameter('Blocks', 8);
ip.addParameter('BlockSize', 250);
ip.parse(varargin{:});
o = ip.Results;
ca = cosd(alpha);  sa = sind(alpha);
transition = strcmpi(o.Model, 'transition');

fid = fopen(file, 'w');
cleaner = onCleanup(@() fclose(fid));
w = @(varargin) fprintf(fid, [varargin{1} '\n'], varargin{2:end});
w('/file/read-case %s', meshFile);
w('/define/models/energy yes'); w(''); w(''); w(''); w('');
w('/define/models/viscous/kw-sst yes');
if transition
    w('/define/models/viscous/transition-sst yes');
end
% ideal gas; viscosity for Re = rho*U*c/mu = 1e6 at Mach 0.1, 288.15 K, 101325 Pa
w('/define/materials/change-create air air yes ideal-gas no no yes constant 4.1687e-05 no no no');
if transition
    w('/define/boundary-conditions/pressure-far-field farfield no 0 no 0.1 no 288.15 no %.6f no %.6f no no yes no 1 %g %g', ...
        ca, sa, o.Intensity, o.ViscRatio);
else
    w('/define/boundary-conditions/pressure-far-field farfield no 0 no 0.1 no 288.15 no %.6f no %.6f no no yes %g %g', ...
        ca, sa, o.Intensity, o.ViscRatio);
end
w('/report/reference-values/compute/pressure-far-field farfield');
w('/solve/set/discretization-scheme');
eqs = {'mom', 'k', 'omega', 'temperature', 'density'};
if transition, eqs = [eqs, {'intermit', 'retheta'}]; end
for k = 1:numel(eqs), w('%s 1', eqs{k}); end
w('pressure 12');
w('q');
nRes = 6 + 2*transition;                  % continuity, x, y, energy, k, omega (+ intermittency, Re_theta)
w(['/solve/monitors/residual/convergence-criteria' repmat(' 1e-9', 1, nRes)]);
w('/solve/initialize/compute-defaults/pressure-far-field farfield');
w('/solve/initialize/initialize-flow');
for b = 1:o.Blocks
    w('/solve/iterate %d', o.BlockSize);
    w('/report/forces/wall-forces yes %.6f %.6f no', ca, sa);      % drag direction
    w('/report/forces/wall-forces yes %.6f %.6f no', -sa, ca);     % lift direction
end
w('/exit yes');
end
