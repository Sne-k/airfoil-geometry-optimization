function [cd, cl, iter, parts] = fluentForces(transcript)
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
%
%   [cd, cl, iter, parts] = FLUENTFORCES(transcript) also returns the
%   pressure and the viscous part of both coefficients, as a table with the
%   columns CD_pressure, CD_viscous, CL_pressure and CL_viscous.

txt = fileread(transcript);
[tok, pos] = regexp(txt, 'Forces - Direction Vector[^\n]*\n(?:[^\n]*\n)*?\s*Net\s+([^\n]*)', 'tokens', 'start');
v = nan(numel(tok), 3);                  % coefficients: pressure, viscous, total
for k = 1:numel(tok)
    nums = str2double(regexp(tok{k}{1}, '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match'));
    m = min(3, numel(nums));
    v(k, end-m+1:end) = nums(end-m+1:end);
end
n = floor(size(v, 1) / 2);
d = v(1:2:2*n, :);
l = v(2:2:2*n, :);
cd = d(:, 3);
cl = l(:, 3);
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
if nargout > 3
    parts = table(d(:, 1), d(:, 2), l(:, 1), l(:, 2), 'VariableNames', ...
        {'CD_pressure', 'CD_viscous', 'CL_pressure', 'CL_viscous'});
end
end
