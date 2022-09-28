#!/bin/bash
echo "You must NOT execute this on boruvka.felk.cvut.cz"
echo "TODO: run this via qsub, so that this doesn't get killed?"
module load MATLAB/9.7
cat buildScores.m | matlab -nodesktop 2>&1 | tee buildScores.log