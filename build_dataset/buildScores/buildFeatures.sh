#!/bin/bash
bash nvidia-usage.sh
nvidia-smi --query-gpu=index,name,utilization.memory --format=csv
echo -n "Please select a GPU: "
read GPU_ID
export CUDA_VISIBLE_DEVICES=$GPU_ID
module load MATLAB/9.7
module load CUDA/9.0.176-GCC-6.4.0-2.28
cat buildFeatures.m | matlab -nodesktop 2>&1 | tee buildFeatures.log