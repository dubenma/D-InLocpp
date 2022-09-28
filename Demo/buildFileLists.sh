#!/bin/bash
module load MATLAB/9.7
cat buildFileLists.m | matlab -nodesktop 2>&1 | tee buildFileLists.log