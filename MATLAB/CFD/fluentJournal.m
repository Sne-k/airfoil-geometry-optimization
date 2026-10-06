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
%     'StartTimeStep'  pseudo-time step of the first-order stage, in the
%                   same units; [] uses TimeStep. A larger step lets the
%                   free-stream turbulence of a large domain settle
%                   before the second-order stage                     ([])
%     'Limiter'     slope limiter: 'default', 'multi-dimensional' or
%                   'differentiable'                          ('default')
%     'TransitionOrder'  1 keeps first-order upwinding for the two
%                   equations of the transition model in the second stage (2)
%     'TransitionRelax'  pseudo-time relaxation factor of the two equations
%                   of the transition model; [] keeps Fluent's 0.75    ([])
%     'Probes'      distances upstream of the leading edge, in chords
%                   along the free-stream direction, at which the
%                   turbulence intensity, the turbulent viscosity ratio
%                   and the speed are printed after every force report
%                   (fluentProbes reads them)                         ([])
%     'Surface'     name (without extension) of a profile file with the
%                   pressure coefficient and the wall shear stress on the
%                   airfoil, written after the last block; with several
%                   angles the files are <name>_1.prof, <name>_2.prof, ...
%                   (fluentSurface reads them)                         ('')
%     'SurfaceEvery'  [every span]: further profile files
%                   <name>_it<iteration>.prof every 'every' iterations
%                   during the last 'span' iterations of an angle, for
%                   averages over a solution that does not settle       ([])
%
%   The default free-stream turbulence is that of the NASA Turbulence
%   Modeling Resource NACA 0012 case. The command sequences were checked
%   against Fluent 2026 R1 (student licence): with them the SST model
%   reproduces that case (see MATLAB/CFD/README.md).

ip = inputParser;
ip.PartialMatching = false;
ip.addParameter('Model', 'sst');
ip.addParameter('Re', 1e6);
ip.addParameter('Mach', 0.15);
ip.addParameter('Intensity', 0.052);
ip.addParameter('ViscRatio', 0.009);
ip.addParameter('FirstOrder', 400);
ip.addParameter('Blocks', 8);
ip.addParameter('BlockSize', 200);
ip.addParameter('TimeStep', []);
ip.addParameter('StartTimeStep', []);
ip.addParameter('Limiter', 'default');
ip.addParameter('TransitionOrder', 2);
ip.addParameter('TransitionRelax', []);
ip.addParameter('Probes', []);
ip.addParameter('Surface', '');
ip.addParameter('SurfaceEvery', []);
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
w('/file/confirm-overwrite no');
w('/file/read-case %s', meshFile);
w('/define/models/energy yes'); w(''); w(''); w(''); w('');
w('/define/models/viscous/kw-sst yes');
if transition
    w('/define/models/viscous/transition-sst yes');
end
w('/define/materials/change-create air air yes ideal-gas no no yes constant %.6e no no no', mu);
farfield(w, o, T0, alpha(1), transition);
w('/report/reference-values/compute/pressure-far-field farfield');
for i = 1:numel(alpha)                              % point surfaces p<angle>d<distance>
    for j = 1:numel(o.Probes)
        w('/surface/point-surface p%dd%d %.6f %.6f', i, j, -o.Probes(j) * cosd(alpha(i)), -o.Probes(j) * sind(alpha(i)));
    end
end
if isempty(o.StartTimeStep), o.StartTimeStep = o.TimeStep; end
timeStep(w, o.StartTimeStep, U);
if ~strcmpi(o.Limiter, 'default')
    w('/solve/set/slope-limiter-set %s yes no', o.Limiter);
end
if transition && ~isempty(o.TransitionRelax)
    w('/solve/set/pseudo-time-method/relaxation-factors/intermit %g', o.TransitionRelax);
    w('/solve/set/pseudo-time-method/relaxation-factors/retheta %g', o.TransitionRelax);
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
probes(w, o, 1);
scheme(w, eqs, 1, 12);
if transition && o.TransitionOrder == 1
    scheme(w, {'intermit', 'retheta'}, 0, 12);
end
if ~isequal(o.StartTimeStep, o.TimeStep)
    if isempty(o.TimeStep)
        w('/solve/set/pseudo-time-method/global-time-step-settings yes 1 1');     % back to automatic
    else
        timeStep(w, o.TimeStep, U);
    end
end
it = o.FirstOrder;
rows = [alpha(1), it, 1];
for i = 1:numel(alpha)
    if i > 1, farfield(w, o, T0, alpha(i), transition); end
    if isscalar(alpha), name = o.Surface; else, name = sprintf('%s_%d', o.Surface, i); end
    for b = 1:o.Blocks
        w('/solve/iterate %d', o.BlockSize);
        forces(w, alpha(i));
        probes(w, o, i);
        it = it + o.BlockSize;
        rows(end+1, :) = [alpha(i), it, 2]; %#ok<AGROW>
        left = (o.Blocks - b) * o.BlockSize;            % iterations still to run at this angle
        if ~isempty(o.Surface) && ~isempty(o.SurfaceEvery) && left > 0 && left < o.SurfaceEvery(2) ...
                && mod(left, o.SurfaceEvery(1)) == 0
            surface(w, sprintf('%s_it%d', name, it));
        end
    end
    if ~isempty(o.Surface), surface(w, name); end
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

function timeStep(w, tau, U)
% Fixed pseudo-time step of tau chord passages (chord 1 m); nothing for tau = []
if ~isempty(tau)
    w('/solve/set/pseudo-time-method/global-time-step-settings no %.6e', tau / U);
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

function probes(w, o, i)
% Turbulence intensity, viscosity ratio and speed at the probe points of angle i
if isempty(o.Probes), return; end
names = sprintf('p%dd%%d ', i);
names = sprintf(names, 1:numel(o.Probes));
for field = {'turb-intensity', 'viscosity-ratio', 'velocity-magnitude'}
    w('/report/surface-integrals/vertex-avg %s() %s no', names, field{1});
end
end

function surface(w, name)
% Pressure coefficient and wall shear stress on the airfoil
w('/file/write-profile %s.prof airfoil () pressure-coefficient x-wall-shear y-wall-shear ()', name);
end

function forces(w, alpha)
ca = cosd(alpha);  sa = sind(alpha);
w('/report/forces/wall-forces yes %.6f %.6f no', ca, sa);        % drag direction
w('/report/forces/wall-forces yes %.6f %.6f no', -sa, ca);       % lift direction
end
