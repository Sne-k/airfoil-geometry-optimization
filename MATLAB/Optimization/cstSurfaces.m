function [yu, yl] = cstSurfaces(Au, Al, dte, x)
%CSTSURFACES  Upper and lower surface of a CST airfoil at the stations x.
x = x(:);
yu = cstBasis(x, numel(Au) - 1) * Au(:) + x*dte/2;
yl = cstBasis(x, numel(Al) - 1) * Al(:) - x*dte/2;
end
