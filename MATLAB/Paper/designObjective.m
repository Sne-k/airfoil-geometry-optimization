function e = designObjective(x, yu, yl, S, panels, useFloor, exe)
%DESIGNOBJECTIVE  The objective of the optimiser for one design and one panelling, as airfoilObjective.m computes it.
%   e = DESIGNOBJECTIVE(x, yu, yl, S, panels, useFloor, exe) runs XFOIL from
%   -2 to 12 deg (S.alphaRange, if given) without restarts for every flow condition in S.flows,
%   applies the rules of the optimiser for an unusable polar (fewer than 12
%   converged angles or none around 0 deg, |CM| at 0 deg above S.cmMax, CL
%   max below S.clMaxMin; then e = 0) and combines the conditions by
%   S.aggregate ('mean' or 'worst'). S also holds Re, objective, design and
%   weights (see optimize_airfoil.m). panels is [] for XFOIL's 160 nodes or
%   a number; useFloor switches the friction floor of xfoilPolar.
range = [-2 12 0.5];
if isfield(S, 'alphaRange'), range = S.alphaRange; end   % 'KeepCLmax' runs sweep to 18 deg, as the optimiser does
ec = zeros(1, numel(S.flows));
for c = 1:numel(S.flows)
    flow = S.flows{c};  flow.FrictionFloor = useFloor;
    pol = xfoilPolar(x, yu, x, yl, S.Re, range, exe, panels, false, flow);
    if numel(pol.alpha) < 12 || pol.alpha(1) > 0 || pol.alpha(end) < 0 || ...
            abs(interp1(pol.alpha, pol.CM, 0)) > S.cmMax || max(pol.CL) < S.clMaxMin
        e = 0;
        return;
    end
    ec(c) = efficiencyValue(pol, S.objective, S.design, S.weights, S.aggregate);
end
if strcmp(S.aggregate, 'worst'), e = min(ec); else, e = mean(ec); end
if ~isfinite(e) || e < 0, e = 0; end
end
