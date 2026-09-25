function B = cstBasis(x, n)
%CSTBASIS  CST (class-shape transformation) basis of order n at the stations x.
%   Column i+1 is sqrt(x) (1-x) * nchoosek(n,i) x^i (1-x)^(n-i): the class
%   function of a round-nosed airfoil times a Bernstein polynomial.
%   Reference: B. M. Kulfan, "Universal parametric geometry representation
%   method", Journal of Aircraft 45(1), 2008.

x = min(max(x(:), 0), 1);
B = zeros(numel(x), n + 1);
for i = 0:n
    B(:, i+1) = sqrt(x) .* (1 - x) .* nchoosek(n, i) .* x.^i .* (1 - x).^(n - i);
end
end
