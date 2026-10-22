function [p, info] = consensusPolar(xu, yu, xl, yl, Re, exe, flow)
%CONSENSUSPOLAR  XFOIL polar of a design with the rule against false solutions of collect_population_results.
%   [p, info] = CONSENSUSPOLAR(xu, yu, xl, yl, Re, exe, flow) computes the
%   polar (160 panel nodes, alpha from -2 to 18 deg in 0.5 deg steps, the
%   friction floor of xfoilPolar; flow as in xfoilPolar, for example
%   struct('Xtr', [0.05 0.05])) at the exact coordinates and at the
%   coordinates rounded to 6 decimals. If the two peaks of CL/CD agree
%   within 1 %, the exact polar is used. If they disagree, both are also
%   computed with 200 panel nodes, and the 160-node polar whose peak is
%   closer to the median of the four is used.
%   info.sensitivityPercent: difference of the two 160-node peaks (Inf if
%   only one gives a value); info.used: 1 exact, 2 rounded; info.unstable:
%   no polar that is independent of the machine load.

if nargin < 7, flow = struct(); end
[pE, cE] = stablePolar(xu, yu, xl, yl, Re, exe, flow);
[pR, cR] = stablePolar(round(xu, 6), round(yu, 6), round(xl, 6), round(yl, 6), Re, exe, flow);
vE = peakLD(pE);  vR = peakLD(pR);
s = 100 * (max(vE, vR) / min(vE, vR) - 1);
if xor(isnan(vE), isnan(vR)), s = Inf; end           % only one of the two gives a value
pick = 1;                                            % they agree within 1 %, or only the exact one gives a value
if isnan(vE) && ~isnan(vR)
    pick = 2;
elseif s > 1 && isfinite(s)                          % they disagree: the 200-node polars decide
    v = [vE, vR, peakLD(stablePolar(xu, yu, xl, yl, Re, exe, flow, 200)), ...
        peakLD(stablePolar(round(xu, 6), round(yu, 6), round(xl, 6), round(yl, 6), Re, exe, flow, 200))];
    v = sort(v(~isnan(v)));
    m = v(ceil(numel(v) / 2));                       % median; the lower middle value for an even number
    if abs(vR - m) < abs(vE - m), pick = 2; end
end
if pick == 1, p = pE;  u = cE; else, p = pR;  u = cR; end
info = struct('sensitivityPercent', s, 'used', pick, 'unstable', u);
end

function [p, unstable] = stablePolar(xu, yu, xl, yl, Re, exe, flow, panels)
% XFOIL polar that does not depend on the load of the machine (as in collect_population_results)
unstable = false;
flow.TimeFactor = 3;
if nargin < 8, panels = []; end
[p, info] = xfoilPolar(xu, yu, xl, yl, Re, [-2 18 0.5], exe, panels, true, flow);
if ~info.timedOut, return; end
for attempt = 2:4
    [q, info] = xfoilPolar(xu, yu, xl, yl, Re, [-2 18 0.5], exe, panels, true, flow);
    same = isequal(q.alpha, p.alpha);
    p = q;
    if ~info.timedOut || same, return; end
end
unstable = true;
p = struct('alpha', [], 'CL', [], 'CD', [], 'CM', [], 'xtrTop', [], 'xtrBot', []);
end

function v = peakLD(p)
% peak CL/CD; NaN if the polar is not usable (the rule of collect_population_results)
v = NaN;
if numel(p.alpha) < 12 || p.alpha(1) > 0 || p.alpha(end) < 0, return; end
m = efficiencyMetrics(p);
v = m.LDmax;
end
