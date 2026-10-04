function [cd, cl, iter] = fluentForces(transcript)
%FLUENTFORCES  Drag and lift coefficients from a Fluent transcript.
%   [cd, cl] = FLUENTFORCES(transcript) reads the wall-forces reports that
%   the journal from fluentJournal prints after every iteration block (drag
%   direction first, then lift direction) and returns the total force
%   coefficients of each block as column vectors.
%
%   [cd, cl, iter] = FLUENTFORCES(transcript) also returns the number of
%   the last iteration before each report (0 if there is none). It can be
%   smaller than planned: Fluent ends a block early when all residuals are
%   below the convergence criteria.

txt = fileread(transcript);
[tok, pos] = regexp(txt, 'Forces - Direction Vector[^\n]*\n(?:[^\n]*\n)*?\s*Net\s+([^\n]*)', 'tokens', 'start');
v = cellfun(@(t) lastNumber(t{1}), tok);
cd = v(1:2:end).';
cl = v(2:2:end).';
n = min(numel(cd), numel(cl));
cd = cd(1:n);  cl = cl(1:n);
if nargout > 2
    [itTok, itPos] = regexp(txt, '(?m)^\s*(\d+)\s+\d\.\d+e[-+]\d+\s', 'tokens', 'start');
    itNum = cellfun(@(t) str2double(t{1}), itTok);
    iter = zeros(n, 1);
    p = pos(1:2:end);
    for k = 1:n
        j = find(itPos < p(k), 1, 'last');
        if ~isempty(j), iter(k) = itNum(j); end
    end
end
end

function x = lastNumber(s)
nums = regexp(s, '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match');
x = str2double(nums{end});
end
