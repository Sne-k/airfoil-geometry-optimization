function [yu, yl] = parsecSurfaces(p, x)
%PARSECSURFACES  Upper and lower surface of a PARSEC airfoil at the stations x.
%   [yu, yl] = PARSECSURFACES(p, x) evaluates z(x) = sum a_n x^(n-1/2) for
%   both surfaces, with the coefficients from parsec(p).

e = (1:6) - 0.5;
a = parsec(p);
x = x(:);
yu = (x.^e) * a(1:6);
yl = (x.^e) * a(7:12);
end
