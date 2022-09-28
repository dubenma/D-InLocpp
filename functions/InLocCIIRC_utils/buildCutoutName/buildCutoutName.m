function name = buildCutoutName(cutoutPath, extension)
    [~, basename, ~] = fileparts(cutoutPath);
    spaceName = strsplit(cutoutPath, '/');
    spaceName = spaceName{1};
    splitBasename = strsplit(basename, '_');
    name = [splitBasename{1}, '_', spaceName, '_', strjoin(splitBasename(2:end), '_'), extension];
end