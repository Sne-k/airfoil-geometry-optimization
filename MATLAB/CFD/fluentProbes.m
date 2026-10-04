function P = fluentProbes(transcript)
%FLUENTPROBES  Point values printed by a journal from fluentJournal.
%   P = FLUENTPROBES(transcript) reads the "Average of Surface Vertex
%   Values" reports of a Fluent transcript and returns a table with one row
%   per surface and report, in the order of the transcript: surface, field
%   (as Fluent prints it, e.g. 'Turbulent Intensity') and value. The table
%   is empty if the transcript has no such report.

txt = fileread(transcript);
blocks = regexp(txt, 'Average of Surface Vertex Values\s*\n([^\n]*)\n[-\s]*\n((?:[^\n]*\S[^\n]*\n)*)', 'tokens');
rows = cell(0, 3);
for k = 1:numel(blocks)
    field = strtrim(regexprep(blocks{k}{1}, '\[[^\]]*\]', ''));
    vals = regexp(blocks{k}{2}, '(?m)^\s*(\S+)\s+([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s*$', 'tokens');
    for m = 1:numel(vals)
        if strcmpi(vals{m}{1}, 'Net'), continue; end
        rows(end+1, :) = {vals{m}{1}, field, str2double(vals{m}{2})}; %#ok<AGROW>
    end
end
P = cell2table(rows, 'VariableNames', {'surface', 'field', 'value'});
end
