function [xtr, xsep] = transitionFromCf(x, cf)
%TRANSITIONFROMCF  Transition and separation locations from skin friction.
%   [xtr, xsep] = TRANSITIONFROMCF(x, cf) takes the skin friction
%   coefficient cf along one surface of an airfoil (x from the leading
%   edge to the trailing edge, chord 1).
%     xtr   where the boundary layer becomes turbulent: in a laminar layer
%           the skin friction falls along the surface, often to zero or
%           below in a separation bubble, and it rises to a much higher
%           level where the layer becomes turbulent. The function looks for
%           the largest rise of the skin friction above the lowest value
%           upstream of it, and xtr is the middle of that rise: the last
%           point where the skin friction is still below the mean of the
%           two levels. The search uses x = 0.03 to 0.99 (ahead of that
%           the rise behind the stagnation point would be taken for it)
%           and a moving average over seven points, so that short waves in
%           a separated region set neither the levels nor the location.
%           NaN if the rise is smaller than 0.001 (the layer stays in one
%           state).
%     xsep  the first point behind x = 0.03 with reversed flow (cf < 0),
%           NaN if there is none
%   The estimate of xtr is a few mesh cells wide (the rise is not a jump).

[x, i] = sort(x(:));
cf = cf(i);
xtr = NaN;
in = x >= 0.03 & x <= 0.99;
xs = x(in);
c = movmean(cf(in), 7);
if numel(c) > 7
    low = cummin(c);                                   % lowest value up to each point
    [rise, j] = max(c - low);
    if rise > 0.001
        k = find(c(1:j) == low(j), 1, 'last');
        level = (c(k) + c(j)) / 2;
        b = find(c(k:j) < level, 1, 'last') + k - 1;   % last point below the half level before the top
        xtr = xs(b) + (level - c(b)) / (c(b+1) - c(b)) * (xs(b+1) - xs(b));
    end
end
k = find(cf < 0 & x >= 0.03, 1);
if isempty(k), xsep = NaN; else, xsep = x(k); end
end
