function [cd, cl] = fluentForces(transcript)
%FLUENTFORCES  Drag and lift coefficients from a Fluent transcript.
%   [cd, cl] = FLUENTFORCES(transcript) reads the wall-forces reports that
%   the journal from fluentJournal prints after every iteration block (drag
%   direction first, then lift direction) and returns the total force
%   coefficients of each block as column vectors.

txt = fileread(transcript);
tok = regexp(txt, 'Forces - Direction Vector[^\n]*\n(?:[^\n]*\n)*?\s*Net\s+([^\n]*)', 'tokens');
v = cellfun(@(t) lastNumber(t{1}), tok);
cd = v(1:2:end).';
cl = v(2:2:end).';
n = min(numel(cd), numel(cl));
cd = cd(1:n);  cl = cl(1:n);
end

function x = lastNumber(s)
nums = regexp(s, '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match');
x = str2double(nums{end});
end
