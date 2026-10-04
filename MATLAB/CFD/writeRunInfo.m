function writeRunInfo(file, codeDir, started, options, transcript)
%WRITERUNINFO  Records when, with what and from which code a CFD batch ran.
%   WRITERUNINFO(file, codeDir, started, options, transcript) writes a JSON
%   file with the start and end time (UTC), the git commit of the code in
%   codeDir (marked if files were changed), the MATLAB release, the Fluent
%   release and build read from a transcript of the batch, and the solver
%   options. It contains no folder or user names.

info.started = [char(started, 'yyyy-MM-dd HH:mm:ss') ' UTC'];
info.finished = [char(datetime('now', 'TimeZone', 'UTC'), 'yyyy-MM-dd HH:mm:ss') ' UTC'];
info.gitCommit = gitDescribe(codeDir);
info.matlab = version;
info.fluent = 'unknown';
if nargin > 4 && isfile(transcript)
    txt = fileread(transcript);
    rel = regexp(txt, 'Welcome to ANSYS Fluent ([^\r\n]*)', 'tokens', 'once');
    build = regexp(txt, 'Build Id:\s*(\d+)', 'tokens', 'once');
    if ~isempty(rel), info.fluent = strtrim(rel{1}); end
    if ~isempty(build), info.fluent = [info.fluent ', build ' build{1}]; end
    if contains(txt, 'student version', 'IgnoreCase', true), info.fluent = [info.fluent ' (student licence)']; end
end
info.options = cell2struct(options(2:2:end), options(1:2:end), 2);
fid = fopen(file, 'w');
fprintf(fid, '%s\n', jsonencode(info, 'PrettyPrint', true));
fclose(fid);
end

function s = gitDescribe(folder)
% Commit of the code, marked if files of the folder were changed
[st, out] = system(sprintf('git -C "%s" rev-parse --short HEAD', folder));
if st ~= 0
    s = 'unknown';
    return;
end
s = strtrim(out);
[~, changes] = system(sprintf('git -C "%s" status --porcelain -- .', folder));
if ~isempty(strtrim(changes)), s = [s ' + uncommitted changes']; end
end
