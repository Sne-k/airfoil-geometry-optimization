function e = efficiencyValue(pol, objective, designCL)
%EFFICIENCYVALUE  Efficiency figure of an XFOIL polar used as objective.
%   'LDmax'      maximum CL/CD
%   'endurance'  maximum CL^1.5/CD
%   'LDatCL'     CL/CD at the lift coefficient designCL (0 if not reached)

% LDmax and endurance use a 3-point moving median, so an isolated spurious
% XFOIL point cannot set the maximum
switch objective
    case 'LDmax'
        e = max(movmedian(pol.CL ./ pol.CD, 3));
    case 'endurance'
        e = max(movmedian(max(pol.CL, 0).^1.5 ./ pol.CD, 3));
    case 'LDatCL'
        [~, iMax] = max(pol.CL);
        cl = pol.CL(1:iMax);                   % attached-flow branch
        ld = cl ./ pol.CD(1:iMax);
        [cl, iu] = unique(cl);
        if numel(cl) < 2 || designCL < cl(1) || designCL > cl(end)
            e = 0;
        else
            e = interp1(cl, ld(iu), designCL);
        end
    otherwise
        error('efficiencyValue:objective', 'Unknown objective "%s".', objective);
end
end
