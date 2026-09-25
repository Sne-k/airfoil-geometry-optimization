function [vmax, i] = supportedMax(alpha, v)
%SUPPORTEDMAX  Maximum of a polar quantity that a neighbouring angle confirms.
%   [vmax, i] = SUPPORTEDMAX(alpha, v) returns the largest v(i) for which a
%   converged neighbouring angle (one sweep step away) has a value of at
%   least 80 % of v(i). An isolated spurious XFOIL point cannot set the
%   maximum, including at the ends of the polar. Angles that did not
%   converge are treated as gaps, so a real narrow peak next to a gap is
%   kept as long as its other neighbour confirms it. Returns NaN and 0 if
%   no point qualifies.

alpha = alpha(:);
v = v(:);
vmax = NaN;
i = 0;
if numel(alpha) < 2, return; end
step = mode(round(diff(alpha), 6));          % sweep step (gaps are multiples)
ok = false(size(v));
for k = 1:numel(v)
    nb = abs(alpha - alpha(k)) <= 1.01*step & (1:numel(v))' ~= k;
    ok(k) = any(v(nb) >= v(k) - 0.2*abs(v(k)));
end
if ~any(ok), return; end
w = v;
w(~ok) = -Inf;
[vmax, i] = max(w);
end
