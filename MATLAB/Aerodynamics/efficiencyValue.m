function e = efficiencyValue(pol, objective, design, weights, aggregate)
%EFFICIENCYVALUE  Efficiency figure of an XFOIL polar used as objective.
%   e = EFFICIENCYVALUE(pol, objective, design, weights, aggregate)
%   'LDmax'      maximum CL/CD
%   'endurance'  maximum CL^1.5/CD
%   'LDatCL'     CL/CD at the lift coefficient design. With several lift
%                coefficients (e.g. cruise and loiter), their weighted mean
%                with the given weights (default: equal), or, with
%                aggregate = 'worst', the lowest of them. A design point
%                that the polar does not reach counts as 0.
%   'LDatAlpha'  CL/CD at the angle of attack design (deg), which must be
%                one of the angles of the polar. Several angles are combined
%                like several lift coefficients. An angle that did not
%                converge, or whose value no neighbouring angle confirms
%                (see supportedMax), counts as 0.
%   Returns 0 when the value cannot be determined.

% The maxima must be confirmed by a neighbouring angle (supportedMax), so an
% isolated spurious XFOIL point cannot set them
if nargin < 3, design = []; end
if nargin < 4 || isempty(weights), weights = ones(size(design)); end
if nargin < 5 || isempty(aggregate), aggregate = 'mean'; end
e = 0;
switch objective
    case 'LDmax'
        e = supportedMax(pol.alpha, pol.CL ./ pol.CD);
    case 'endurance'
        e = supportedMax(pol.alpha, max(pol.CL, 0).^1.5 ./ pol.CD);
    case {'LDatCL', 'LDatAlpha'}
        v = zeros(size(design));
        for j = 1:numel(design)
            if strcmp(objective, 'LDatCL'), v(j) = ldAtCL(pol, design(j)); else, v(j) = ldAtAlpha(pol, design(j)); end
        end
        e = combine(v, weights, aggregate);
    otherwise
        error('efficiencyValue:objective', 'Unknown objective "%s".', objective);
end
if isempty(e) || isnan(e), e = 0; end
end

function e = combine(v, weights, aggregate)
switch aggregate
    case 'mean',  e = sum(weights(:) .* v(:)) / sum(weights);
    case 'worst', e = min(v);
    otherwise, error('efficiencyValue:aggregate', 'Unknown aggregate "%s".', aggregate);
end
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

function ld = ldAtAlpha(pol, a)
% CL/CD at the angle a, if a neighbouring angle (one sweep step away) has at
% least 80 % of it. If XFOIL did not converge at a itself but at both
% neighbouring angles, and they agree within 30 %, their mean is used, so a
% single missing angle does not make the value 0.
ld = 0;
alpha = pol.alpha(:);
if numel(alpha) < 2, return; end
v = pol.CL(:) ./ pol.CD(:);
step = mode(round(diff(alpha), 6));
k = find(abs(alpha - a) < 1e-6, 1);
if isempty(k)
    lo = find(abs(alpha - (a - step)) < 1e-6, 1);
    hi = find(abs(alpha - (a + step)) < 1e-6, 1);
    if ~isempty(lo) && ~isempty(hi) && min(v(lo), v(hi)) >= 0.7 * max(v(lo), v(hi))
        ld = (v(lo) + v(hi)) / 2;
    end
    return;
end
nb = abs(alpha - a) <= 1.01*step & (1:numel(alpha))' ~= k;
if any(v(nb) >= v(k) - 0.2*abs(v(k))), ld = v(k); end
end
