function P = cstCurvatureBasis(x, n)
%CSTCURVATUREBASIS  Precomputed functions for cstCurvature at the stations x.
%   P = CSTCURVATUREBASIS(x, n) returns, for CST order n, the Bernstein
%   polynomials needed for S, S' and S'' (S' = n sum (A_(i+1) - A_i) B_(i,n-1),
%   S'' = n (n-1) sum (A_(i+2) - 2 A_(i+1) + A_i) B_(i,n-2)) and the class
%   function C = sqrt(x) (1 - x) with its first two derivatives.

if n < 2
    error('cstCurvatureBasis:order', 'The CST order must be at least 2.');
end
x = x(:);
P.x = x;
P.B0 = bernstein(x, n);
P.B1 = n * bernstein(x, n-1);
P.B2 = n * (n-1) * bernstein(x, n-2);
P.C  = sqrt(x) .* (1 - x);
P.C1 = 0.5 ./ sqrt(x) - 1.5 * sqrt(x);
P.C2 = -0.25 ./ x.^1.5 - 0.75 ./ sqrt(x);
end

function B = bernstein(x, n)
% Bernstein polynomials of degree n (columns i = 0..n)
B = zeros(numel(x), n + 1);
for i = 0:n
    B(:, i+1) = nchoosek(n, i) .* x.^i .* (1 - x).^(n - i);
end
end
