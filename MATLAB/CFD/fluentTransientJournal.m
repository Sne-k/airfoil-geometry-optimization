function plan = fluentTransientJournal(file, state, alpha, varargin)
%FLUENTTRANSIENTJOURNAL  Fluent journal that continues a steady case time-accurately.
%   FLUENTTRANSIENTJOURNAL(file, state, alpha) writes a batch journal that
%   reads the case and data files <state>.cas.h5 and <state>.dat.h5 (written
%   by a journal from fluentJournal with the option 'State'), switches to the
%   bounded second-order implicit time discretisation with the coupled
%   solver, and advances the solution with a fixed time step. Every time
%   step is iterated until all residuals have fallen by the factor
%   'Tolerance' from their value at its start, at most 'Inner' times. The
%   drag and lift coefficients at the angle of attack alpha (deg) are
%   printed after every time step (fluentForces reads them).
%
%   plan = FLUENTTRANSIENTJOURNAL(...) returns a table with one row per
%   force report: step and time (in units of chord / free-stream speed,
%   counted from the start of the time-accurate run).
%
%   Options (name, value), defaults in brackets:
%     'Mach'        free-stream Mach number of the case              (0.15)
%     'TimeStep'    time step in units of chord / free-stream speed (0.001)
%     'Steps'       number of the last time step                     (8000)
%     'FirstStep'   number of the first time step; larger than 1 to
%                   continue from a file <tag>_step<FirstStep-1>         (1)
%     'Inner'       largest number of iterations per time step         (10)
%     'Tolerance'   fall of the residuals that ends a time step      (1e-3)
%     'Residuals'   number of residuals of the case: 6 for the SST model,
%                   8 for Transition SST                                (8)
%     'Tag'         first part of the names of the files below       ('ta')
%     'SurfaceEvery'  [every span]: a profile file <tag>_step<step>.prof
%                   with the pressure coefficient and the wall shear stress
%                   on the airfoil every 'every' time steps during the last
%                   'span' time steps; [] writes none                  ([])
%     'SurfaceLast' number of time steps at the end with a profile file at
%                   every step                                          (0)
%     'SaveEvery'   time steps between case and data files
%                   <tag>_step<step>, from which a run that broke off can
%                   be continued; 0 writes them only at the end      (1000)
%
%   Switching to a transient case sets the pressure-velocity coupling to
%   SIMPLE in Fluent 2026 R1; the journal sets the coupled solver again. The
%   settings in force are printed at the start (/report/summary).

ip = inputParser;
ip.PartialMatching = false;
ip.addParameter('Mach', 0.15);
ip.addParameter('TimeStep', 0.001);
ip.addParameter('Steps', 8000);
ip.addParameter('FirstStep', 1);
ip.addParameter('Inner', 10);
ip.addParameter('Tolerance', 1e-3);
ip.addParameter('Residuals', 8);
ip.addParameter('Tag', 'ta');
ip.addParameter('SurfaceEvery', []);
ip.addParameter('SurfaceLast', 0);
ip.addParameter('SaveEvery', 1000);
ip.parse(varargin{:});
o = ip.Results;

T0 = 288.15;  Rgas = 8314.47 / 28.966;                % as in fluentJournal
U = o.Mach * sqrt(1.4 * Rgas * T0);
ca = cosd(alpha);  sa = sind(alpha);

fid = fopen(file, 'w');
cleaner = onCleanup(@() fclose(fid));
w = @(varargin) fprintf(fid, [varargin{1} '\n'], varargin{2:end});
w('/file/confirm-overwrite no');
w('/file/read-case-data %s.cas.h5', state);
w('/define/models/unsteady-2nd-order-bounded? yes');
w('/solve/set/p-v-coupling 24');                                    % coupled
w('/solve/set/transient-controls/time-step-size %.6e', o.TimeStep / U);   % chord 1 m
w('/solve/monitors/residual/criterion-type 1');                     % relative to the start of the time step
w(['/solve/monitors/residual/relative-conv-criteria' repmat(sprintf(' %g', o.Tolerance), 1, o.Residuals)]);
w('/report/summary no');
steps = (o.FirstStep:o.Steps).';
for k = steps.'
    w('/solve/dual-time-iterate 1 %d', o.Inner);
    w('/report/forces/wall-forces yes %.6f %.6f no', ca, sa);        % drag direction
    w('/report/forces/wall-forces yes %.6f %.6f no', -sa, ca);       % lift direction
    left = o.Steps - k;                                              % time steps still to run
    if left < o.SurfaceLast || (~isempty(o.SurfaceEvery) && left < o.SurfaceEvery(2) && mod(left, o.SurfaceEvery(1)) == 0)
        w('/file/write-profile %s_step%d.prof airfoil () pressure-coefficient x-wall-shear y-wall-shear ()', o.Tag, k);
    end
    if k == o.Steps || (o.SaveEvery > 0 && mod(k, o.SaveEvery) == 0)
        w('/file/write-case-data %s_step%d', o.Tag, k);
    end
end
w('/exit yes');
plan = table(steps, steps * o.TimeStep, 'VariableNames', {'step', 'time'});
end
