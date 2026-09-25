function [Au, Al, dte] = cstFit(xu, yu, xl, yl, n)
%CSTFIT  Least-squares CST fit of an airfoil.
%   [Au, Al, dte] = CSTFIT(xu, yu, xl, yl, n) fits
%       y = cstBasis(x, n) * A + x * dz,   dz = +dte/2 (upper), -dte/2 (lower)
%   to both surfaces (ordered from the leading edge), where dte is the
%   trailing-edge thickness of the input.

dte = max(yu(end) - yl(end), 0);
Au = (cstBasis(xu, n) \ (yu(:) - xu(:)*dte/2)).';
Al = (cstBasis(xl, n) \ (yl(:) + xl(:)*dte/2)).';
end
