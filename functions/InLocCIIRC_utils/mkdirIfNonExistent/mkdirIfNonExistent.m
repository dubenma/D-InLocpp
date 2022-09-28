function mkdirIfNonExistent(pathToDirectory)

    if exist(pathToDirectory, 'dir') ~= 7
        mkdir(pathToDirectory);
    end

end