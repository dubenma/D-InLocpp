function [Rs,Cs,errors] = reconstructPose(u, x, K, reconstructPosePyPath)

    inputPath = strcat(tempname, '.mat');
    outputPath = strcat(tempname, '.mat');
    save(inputPath, 'u', 'x', 'K');
    
    % call reconstructPose.py
    command = sprintf('PATH=/usr/local/bin:$PATH python3 "%s" %s %s', reconstructPosePyPath, inputPath, outputPath);
    disp(command);
    [status, cmdout] = system(command);
    disp(cmdout);
    
    % load results
    load(outputPath, 'Rs', 'Cs', 'errors');
    
    % delete temporary files
    delete(inputPath);
    delete(outputPath);
    
 end