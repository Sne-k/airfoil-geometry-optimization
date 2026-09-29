function [v, info] = curvatureViolation(Au, Al, dte, L)
%CURVATUREVIOLATION  How far a CST airfoil is outside its curvature limits.
%   [v, info] = CURVATUREVIOLATION(Au, Al, dte, L) checks the airfoil against
%   the limits L from curvatureLimits and returns the violations
%     v = [extra reversals top; extra reversals bottom;
%          trailing-edge curvature excess top; ... bottom]
%   Every entry is >= 0 and all are 0 when the airfoil meets the limits.
%   The reversal entries are the curvature peaks of the extra waves above
%   the threshold (see curvatureSegments); the trailing-edge entries are the
%   distance of the trailing-edge curvature from its allowed range.
%   info holds the reversal counts and the trailing-edge curvatures.

kt = cstCurvature(Au, dte, L.basis, 'upper');
kb = cstCurvature(Al, dte, L.basis, 'lower');
[info.reversalsTop, pt] = curvatureSegments(kt, L.threshold, L.reversalsTop);
[info.reversalsBot, pb] = curvatureSegments(kb, L.threshold, L.reversalsBot);
info.teCurvTop = kt(end);
info.teCurvBot = kb(end);
v = [pt; pb; teExcess(kt(end), L.teTop, L.teTolerance); teExcess(kb(end), L.teBot, L.teTolerance)];
% an extra reversal whose waves just reach the threshold has zero excess
% but still counts; flag it with a tiny positive value
v(1) = max(v(1), eps * (info.reversalsTop > L.reversalsTop));
v(2) = max(v(2), eps * (info.reversalsBot > L.reversalsBot));
end

function e = teExcess(k, limit, tol)
% distance of k from the range between 0 and limit, beyond the tolerance
lo = min(0, limit) - tol;
hi = max(0, limit) + tol;
e = max(0, k - hi) + max(0, lo - k);
end
