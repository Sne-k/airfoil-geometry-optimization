function m = efficiencyMetrics(pol)
%EFFICIENCYMETRICS  Aerodynamic efficiency figures of an XFOIL polar.
%   m = EFFICIENCYMETRICS(pol) returns
%     LDmax, alphaLD, CL_LD  maximum lift-to-drag ratio, and the angle of
%                            attack and lift coefficient where it occurs
%     E15max                 maximum endurance parameter CL^1.5/CD
%     CLmax, alphaStall      maximum lift coefficient and its angle
%     CDmin                  minimum drag coefficient
%     CM0                    pitching moment at alpha = 0

m = struct('LDmax', NaN, 'alphaLD', NaN, 'CL_LD', NaN, 'E15max', NaN, ...
    'CLmax', NaN, 'alphaStall', NaN, 'CDmin', NaN, 'CM0', NaN);
if isempty(pol.alpha), return; end

% 3-point moving median: an isolated spurious XFOIL point cannot set the maximum
[m.LDmax, i] = max(movmedian(pol.CL ./ pol.CD, 3));
m.alphaLD = pol.alpha(i);
m.CL_LD = pol.CL(i);
m.E15max = max(movmedian(max(pol.CL, 0).^1.5 ./ pol.CD, 3));
[m.CLmax, j] = max(pol.CL);
m.alphaStall = pol.alpha(j);
m.CDmin = min(pol.CD);
k = find(abs(pol.alpha) < 1e-9, 1);
if ~isempty(k), m.CM0 = pol.CM(k); end
end
