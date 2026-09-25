function e = efficiencyValue(pol, objective, designCL)
%EFFICIENCYVALUE  Efficiency figure of an XFOIL polar used as objective.
%   'LDmax'      maximum CL/CD
%   'endurance'  maximum CL^1.5/CD
%   'LDatCL'     CL/CD at the lift coefficient designCL
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
        % first crossing of designCL, in angle order, below the maximum lift
        [~, iMax] = max(pol.CL);
        for k = 1:iMax - 1
            c = pol.CL(k:k+1);
            if c(1) <= designCL && designCL <= c(2) && c(2) > c(1)
                ld = c ./ pol.CD(k:k+1);
                e = ld(1) + (designCL - c(1)) / (c(2) - c(1)) * (ld(2) - ld(1));
                break;
            end
        end
    otherwise
        error('efficiencyValue:objective', 'Unknown objective "%s".', objective);
end
if isempty(e) || isnan(e), e = 0; end
end
