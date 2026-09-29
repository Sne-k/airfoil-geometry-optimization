function k = cstCurvature(A, dte, x, side)
%CSTCURVATURE  Curvature of one CST surface, positive where it is convex.
%   k = CSTCURVATURE(A, dte, x, side) returns the curvature of the CST
%   surface with coefficients A (trailing-edge thickness dte) at the
%   stations x (0 < x <= 1). side is 'upper' or 'lower'. The derivatives are
%   exact (no finite differences), so the result is free of numerical noise.
%   The sign convention is that of Xoptfoil2: a convex (outward-bulging)
%   surface has positive curvature on both sides, a concave one negative.
%   x can also be a basis from cstCurvatureBasis(x, numel(A) - 1), which
%   makes repeated evaluations on the same stations much faster.
%
%   Surface: y = C(x) S(x) +/- x dte/2 with the class function
%   C = sqrt(x) (1 - x) and the Bernstein sum S = sum A_i B_(i,n)(x).

A = A(:);
if isstruct(x)
    P = x;
else
    P = cstCurvatureBasis(x, numel(A) - 1);
end
S  = P.B0 * A;
S1 = P.B1 * diff(A);
S2 = P.B2 * diff(A, 2);
if strcmpi(side, 'upper'), s = 1; else, s = -1; end
y1 = P.C1 .* S + P.C .* S1 + s * dte / 2;
y2 = P.C2 .* S + 2 * P.C1 .* S1 + P.C .* S2;
k = -s * y2 ./ (1 + y1.^2).^1.5;
end
