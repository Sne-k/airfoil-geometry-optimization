function [reversals, penalty] = curvatureSegments(k, threshold, allowed)
%CURVATURESEGMENTS  Curvature reversals of a surface and their excess.
%   reversals = CURVATURESEGMENTS(k, threshold) counts the sign changes of
%   the curvature values k (ordered from the leading edge to the trailing
%   edge), considering only values with |k| >= threshold, so that noise
%   around zero curvature is not counted.
%
%   [reversals, penalty] = CURVATURESEGMENTS(k, threshold, allowed) also
%   returns how far the surface is from having only 'allowed' reversals:
%   the curvature is split into segments of equal sign, the allowed + 1
%   strongest segments are kept, and the peak |k| - threshold of every other
%   segment is summed. The penalty is 0 when reversals <= allowed and grows
%   continuously with the size of the extra waves. This is the reversal
%   penalty of Xoptfoil2 (penalty_reversals) without its scaling.

if nargin < 3, allowed = Inf; end
kk = k(abs(k) >= threshold);
reversals = 0;
penalty = 0;
if numel(kk) < 2, return; end
s = sign(kk);
edges = [1; find(diff(s) ~= 0) + 1; numel(kk) + 1];
nSeg = numel(edges) - 1;
reversals = nSeg - 1;
if reversals <= allowed, return; end
peak = zeros(nSeg, 1);
for i = 1:nSeg
    peak(i) = max(abs(kk(edges(i):edges(i+1)-1)));
end
peak = sort(peak, 'descend');
penalty = sum(max(peak(allowed+2:end) - threshold, 0));
end
