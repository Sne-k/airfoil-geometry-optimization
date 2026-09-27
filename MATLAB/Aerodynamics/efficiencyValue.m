function e = efficiencyValue(pol, objective, designCL, weights)
%EFFICIENCYVALUE  Efficiency figure of an XFOIL polar used as objective.
%   'LDmax'      maximum CL/CD
%   'endurance'  maximum CL^1.5/CD
%   'LDatCL'     CL/CD at the lift coefficient designCL. With several lift
%                coefficients (e.g. cruise and loiter), their weighted mean
%                with the given weights (default: equal). A design point
%                that the polar does not reach counts as 0.
%   Returns 0 when the value cannot be determined.

% The maxima must be confirmed by a neighbouring angle (supportedMax), so an
% isolated spurious XFOIL point cannot set them
e = 0;
switch objective
    case 'LDmax'
        e = supportedMax(pol.alpha, pol.CL ./ pol.CD);
    case 'endurance'
        e = supportedMax(pol.alpha, max(pol.CL, 0).^1.5 ./ pol.CD);
    case 'LDatCL'
        if nargin < 4 || isempty(weights), weights = ones(size(designCL)); end
        for j = 1:numel(designCL)
            e = e + weights(j) * ldAtCL(pol, designCL(j));
        end
        e = e / sum(weights);
    otherwise
        error('efficiencyValue:objective', 'Unknown objective "%s".', objective);
end
if isempty(e) || isnan(e), e = 0; end
end

function ld = ldAtCL(pol, cl)
% CL/CD at the first crossing of cl, in angle order, below the maximum lift
ld = 0;
[~, iMax] = max(pol.CL);
for k = 1:iMax - 1
    c = pol.CL(k:k+1);
    if c(1) <= cl && cl <= c(2) && c(2) > c(1)
        r = c ./ pol.CD(k:k+1);
        ld = r(1) + (cl - c(1)) / (c(2) - c(1)) * (r(2) - r(1));
        return;
    end
end
end
