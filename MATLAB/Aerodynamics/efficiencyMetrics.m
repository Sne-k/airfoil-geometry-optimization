function m = efficiencyMetrics(pol)
%EFFICIENCYMETRICS  Aerodynamic efficiency figures of an XFOIL polar.
%   m = EFFICIENCYMETRICS(pol) returns
%     LDmax, alphaLD, CL_LD  maximum lift-to-drag ratio, and the angle of
%                            attack and lift coefficient where it occurs
%     E15max                 maximum endurance parameter CL^1.5/CD
%     CLmax, alphaStall      maximum lift coefficient and its angle
%     CDmin                  minimum drag coefficient
%     CM0                    pitching moment at alpha = 0 (interpolated when
%                            XFOIL did not converge at exactly 0)

m = struct('LDmax', NaN, 'alphaLD', NaN, 'CL_LD', NaN, 'E15max', NaN, ...
    'CLmax', NaN, 'alphaStall', NaN, 'CDmin', NaN, 'CM0', NaN);
if isempty(pol.alpha), return; end

% Peaks must be confirmed by a neighbouring angle (supportedMax), so an
% isolated spurious XFOIL point cannot set them
[m.LDmax, i] = supportedMax(pol.alpha, pol.CL ./ pol.CD);
if i > 0
    m.alphaLD = pol.alpha(i);
    m.CL_LD = pol.CL(i);
end
m.E15max = supportedMax(pol.alpha, max(pol.CL, 0).^1.5 ./ pol.CD);
[m.CLmax, j] = max(pol.CL);
m.alphaStall = pol.alpha(j);
m.CDmin = min(pol.CD);
k = find(abs(pol.alpha) < 1e-9, 1);
if ~isempty(k)
    m.CM0 = pol.CM(k);
elseif pol.alpha(1) < 0 && pol.alpha(end) > 0
    m.CM0 = interp1(pol.alpha, pol.CM, 0);
end
end
