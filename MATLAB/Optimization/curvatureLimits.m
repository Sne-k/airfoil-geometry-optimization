function L = curvatureLimits(Au, Al, dte, threshold)
%CURVATURELIMITS  Curvature limits for designs derived from a CST seed airfoil.
%   L = CURVATURELIMITS(Au, Al, dte) measures the curvature of the seed
%   airfoil (CST coefficients Au, Al, trailing-edge thickness dte) and
%   returns the limits that curvatureViolation checks designs against. This
%   follows the automatic curvature constraints of Xoptfoil2
%   (https://github.com/jxjo/Xoptfoil2, "auto_curvature"):
%     - a design may have no more curvature reversals on each surface than
%       the seed, counted between x = 0.1 and 1 where |curvature| >= the
%       threshold (default 0.01, the Xoptfoil2 default for smooth shapes);
%     - its trailing-edge curvature (at x = 1) must lie between 0 and the
%       seed's trailing-edge curvature rounded to 0.1, with a tolerance of
%       0.05. Unlike Xoptfoil2, the value is not capped at 2 and its sign is
%       taken from the seed, so that the seed always meets its own limits.
%   L = CURVATURELIMITS(..., threshold) uses another reversal threshold.
%
%   Optimisers exploit XFOIL's sensitivity to small shape artefacts, such as
%   a wavy surface or a tiny "spoiler" at the trailing edge. These limits
%   keep the design at least as smooth as the seed.

if nargin < 4, threshold = 0.01; end
L.threshold = threshold;
L.teTolerance = 0.05;
L.x = linspace(0.1, 1, 451)';                 % 0.002 c spacing
L.basis = cstCurvatureBasis(L.x, numel(Au) - 1);
kt = cstCurvature(Au, dte, L.basis, 'upper');
kb = cstCurvature(Al, dte, L.basis, 'lower');
L.reversalsTop = curvatureSegments(kt, threshold);
L.reversalsBot = curvatureSegments(kb, threshold);
L.teTop = sign(kt(end)) * round(abs(kt(end)), 1);
L.teBot = sign(kb(end)) * round(abs(kb(end)), 1);
end
