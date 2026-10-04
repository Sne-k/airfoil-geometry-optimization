function plan = fluentJournal(file, meshFile, alpha, varargin)
%FLUENTJOURNAL  Writes a Fluent batch journal for one airfoil case.
%   FLUENTJOURNAL(file, meshFile, alpha) sets up a 2-D steady RANS case on a
%   mesh from writeFluentMesh (chord 1 m): ideal-gas air at the free-stream
%   Mach number and 288.15 K, the viscosity chosen for the Reynolds number,
%   and a pressure far field at angle of attack alpha (deg). The solution
%   starts from the far-field values, runs with first-order upwinding and
%   then with second-order upwinding. The drag and lift coefficients are
%   printed after the first-order stage and after every block of
%   second-order iterations, so that their convergence can be checked
%   (fluentForces reads them).
%
%   If alpha is a vector, the angles are run one after the other in the same
%   session: the first starts from the far-field values as described, and
%   every further angle continues from the solution of the previous one,
%   with the second-order blocks only.
%
%   plan = FLUENTJOURNAL(...) returns a table with one row per force report,
%   in the order in which Fluent prints them: alpha, iteration (cumulative)
%   and order (1 or 2).
%
%   Options (name, value), defaults in brackets:
%     'Model'       'sst' (k-omega SST, fully turbulent) or 'transition'
%                   (Transition SST, gamma-Re_theta)                ('sst')
%     'Re'          Reynolds number based on the chord              (1e6)
%     'Mach'        free-stream Mach number                        (0.15)
%     'Intensity'   free-stream turbulence intensity in percent   (0.052)
%     'ViscRatio'   free-stream turbulent viscosity ratio         (0.009)
%     'FirstOrder'  iterations with first-order upwinding           (400)
%     'Blocks'      blocks of second-order iterations                 (8)
%     'BlockSize'   iterations per block                            (200)
%     'TimeStep'    pseudo-time step in units of chord / free-stream
%                   speed; [] keeps Fluent's automatic time step      ([])
%     'Limiter'     slope limiter: 'default', 'multi-dimensional' or
%                   'differentiable'                          ('default')
%
%   The default free-stream turbulence is that of the NASA Turbulence
%   Modeling Resource NACA 0012 case. The command sequences were checked
%   against Fluent 2026 R1 (student licence): with them the SST model
%   reproduces that case (see MATLAB/CFD/README.md).

ip = inputParser;
ip.addParameter('Model', 'sst');
ip.addParameter('Re', 1e6);
ip.addParameter('Mach', 0.15);
ip.addParameter('Intensity', 0.052);
ip.addParameter('ViscRatio', 0.009);
ip.addParameter('FirstOrder', 400);
ip.addParameter('Blocks', 8);
ip.addParameter('BlockSize', 200);
ip.addParameter('TimeStep', []);
ip.addParameter('Limiter', 'default');
ip.parse(varargin{:});
o = ip.Results;
alpha = alpha(:).';

% Free stream (Fluent's air: ideal gas, molar mass 28.966 g/mol, gamma 1.4)
T0 = 288.15;  p0 = 101325;  Rgas = 8314.47 / 28.966;
rho = p0 / (Rgas * T0);
U = o.Mach * sqrt(1.4 * Rgas * T0);
mu = rho * U / o.Re;                                  % chord 1 m
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
w('/define/materials/change-create air air yes ideal-gas no no yes constant %.6e no no no', mu);
farfield(w, o, T0, alpha(1), transition);
w('/report/reference-values/compute/pressure-far-field farfield');
if ~isempty(o.TimeStep)
    w('/solve/set/pseudo-time-method/global-time-step-settings no %.6e', o.TimeStep / U);
end
if ~strcmpi(o.Limiter, 'default')
    w('/solve/set/slope-limiter-set %s yes no', o.Limiter);
end
eqs = {'mom', 'k', 'omega', 'temperature', 'density'};
if transition, eqs = [eqs, {'intermit', 'retheta'}]; end
scheme(w, eqs, 0, 10);
nRes = 6 + 2*transition;               % continuity, x, y, energy, k, omega (+ intermittency, Re_theta)
w(['/solve/monitors/residual/convergence-criteria' repmat(' 1e-9', 1, nRes)]);
w('/solve/initialize/compute-defaults/pressure-far-field farfield');
w('/solve/initialize/initialize-flow');
w('/solve/iterate %d', o.FirstOrder);
forces(w, alpha(1));
scheme(w, eqs, 1, 12);
it = o.FirstOrder;
rows = [alpha(1), it, 1];
for i = 1:numel(alpha)
    if i > 1, farfield(w, o, T0, alpha(i), transition); end
    for b = 1:o.Blocks
        w('/solve/iterate %d', o.BlockSize);
        forces(w, alpha(i));
        it = it + o.BlockSize;
        rows(end+1, :) = [alpha(i), it, 2]; %#ok<AGROW>
    end
end
w('/exit yes');
plan = array2table(rows, 'VariableNames', {'alpha', 'iteration', 'order'});
end

function farfield(w, o, T0, alpha, transition)
% Pressure far field at the angle of attack alpha (deg)
ca = cosd(alpha);  sa = sind(alpha);
if transition
    w('/define/boundary-conditions/pressure-far-field farfield no 0 no %g no %g no %.6f no %.6f no no yes no 1 %g %g', ...
        o.Mach, T0, ca, sa, o.Intensity, o.ViscRatio);
else
    w('/define/boundary-conditions/pressure-far-field farfield no 0 no %g no %g no %.6f no %.6f no no yes %g %g', ...
        o.Mach, T0, ca, sa, o.Intensity, o.ViscRatio);
end
end

function scheme(w, eqs, order, pressure)
% order 0 = first-order upwind, 1 = second-order upwind; pressure 10 =
% standard, 12 = second order
w('/solve/set/discretization-scheme');
for k = 1:numel(eqs), w('%s %d', eqs{k}, order); end
w('pressure %d', pressure);
w('q');
end

function forces(w, alpha)
ca = cosd(alpha);  sa = sind(alpha);
w('/report/forces/wall-forces yes %.6f %.6f no', ca, sa);        % drag direction
w('/report/forces/wall-forces yes %.6f %.6f no', -sa, ca);       % lift direction
end
