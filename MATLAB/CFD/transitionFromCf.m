function [xtr, xsep] = transitionFromCf(x, cf)
%TRANSITIONFROMCF  Transition and separation locations from skin friction.
%   [xtr, xsep] = TRANSITIONFROMCF(x, cf) takes the skin friction
%   coefficient cf along one surface of an airfoil (x from the leading
%   edge to the trailing edge, chord 1).
%     xtr   where the skin friction rises fastest between x = 0.03 and
%           0.99: in a laminar boundary layer the skin friction falls
%           along the surface, and it rises steeply where the layer
%           becomes turbulent. If it never rises by more than 0.02 per
%           chord, the layer stays in one state over that range and xtr is
%           NaN.
%     xsep  the first point behind x = 0.03 with reversed flow (cf < 0),
%           NaN if there is none
%   The estimate is a few mesh cells wide (the rise is not a jump).

[x, i] = sort(x(:));
cf = cf(i);
xm = (x(1:end-1) + x(2:end)) / 2;
slope = diff(cf) ./ diff(x);
in = xm >= 0.03 & xm <= 0.99;
xtr = NaN;
if any(in)
    [s, k] = max(slope(in));
    xin = xm(in);
    if s > 0.02, xtr = xin(k); end
end
k = find(cf < 0 & x >= 0.03, 1);
if isempty(k), xsep = NaN; else, xsep = x(k); end
end
