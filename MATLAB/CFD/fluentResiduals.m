function R = fluentResiduals(transcript)
%FLUENTRESIDUALS  Residual history from a Fluent transcript.
%   R = FLUENTRESIDUALS(transcript) returns a table with the iteration
%   number (iter) and the scaled residuals that Fluent prints for every
%   iteration (one row per iteration: Fluent repeats the last line when the
%   iterations continue); the variable names follow the header of the
%   transcript (continuity, x_velocity, y_velocity, energy, k, omega, and
%   intermit and retheta for Transition SST). Fluent scales the continuity
%   residual by
%   its largest value in the first five iterations, so its level depends on
%   the starting solution; the other residuals are scaled by the size of the
%   solution.

txt = fileread(transcript);
head = regexp(txt, '(?m)^\s*iter\s+(.*?)\s+time/iter\s*$', 'tokens', 'once');
if isempty(head)
    R = table();
    return;
end
names = matlab.lang.makeValidName(strrep(strsplit(strtrim(head{1})), '-', '_'));
n = numel(names);
num = '(\d\.\d+e[-+]\d+)';
pat = ['(?m)^\s*(\d+)' repmat(['\s+' num], 1, n) '\s+\d+:\d+:\d+\s+\d+\s*$'];
tok = regexp(txt, pat, 'tokens');
V = cellfun(@str2double, vertcat(tok{:}));
if isempty(V), V = zeros(0, n + 1); end
[~, last] = unique(V(:, 1), 'last');
V = V(last, :);
R = array2table(V, 'VariableNames', [{'iter'}, names]);
end
