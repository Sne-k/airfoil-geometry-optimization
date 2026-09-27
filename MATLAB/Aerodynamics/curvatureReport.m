function r = curvatureReport(xu, yu, xl, yl)
%CURVATUREREPORT  Curvature quality of an airfoil surface.
%   r = CURVATUREREPORT(xu, yu, xl, yl) fits both surfaces with a smooth
%   12th-order CST representation (coordinates in .dat files carry only a
%   few decimals, which makes direct curvature estimates noisy) and returns
%     reversalsTop, reversalsBot  sign changes of the curvature between
%                                 x = 0.1 and 0.97 (|curvature| > 0.02)
%     teCurvTop, teCurvBot        largest |curvature| between x = 0.95 and 1
%     fitError                    largest deviation of the fit (chord)
%
%   Optimisers exploit XFOIL's sensitivity to small shape artefacts, for
%   example a tiny "spoiler" in the last few percent of chord. A trailing-edge
%   curvature far above that of the seed airfoil, or a reversal that was not
%   intended (reflex on the upper surface, rear loading on the lower one),
%   marks such designs. The checks follow the curvature constraints of
%   Xoptfoil2 (https://github.com/jxjo/Xoptfoil2).

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'Optimization'));
order = 12;
[Au, Al, dte] = cstFit(xu, yu, xl, yl, order);
iu = xu >= 0;  il = xl >= 0;
r.fitError = max(abs([cstBasis(xu(iu), order)*Au.' + xu(iu)*dte/2 - yu(iu); ...
                      cstBasis(xl(il), order)*Al.' - xl(il)*dte/2 - yl(il)]));
h = 1e-3;
x = (0.05:h:1)';
[fu, fl] = cstSurfaces(Au, Al, dte, x);
[r.reversalsTop, r.teCurvTop] = surfaceCurvature(x, fu, h);
[r.reversalsBot, r.teCurvBot] = surfaceCurvature(x, fl, h);
end

function [reversals, teCurv] = surfaceCurvature(x, y, h)
d1 = gradient(y, h);
d2 = gradient(d1, h);
k = d2 ./ (1 + d1.^2).^1.5;
mid = x > 0.1 & x < 0.97;
s = sign(k(mid) .* (abs(k(mid)) > 0.02));
s = s(s ~= 0);
reversals = sum(diff(s) ~= 0);
teCurv = max(abs(k(x >= 0.95 & x < 1)));
end
