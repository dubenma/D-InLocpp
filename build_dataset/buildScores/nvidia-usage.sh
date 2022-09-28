#!/bin/bash

# Simple script printing job details for processes running on GPUs (nvidia-smi)
# M. Sulc, CMP CTU 2016, updated 2017

echo [`hostname`]
GPU=0
F=$(mktemp)

trap "rm -f $F" 0 2 3 15

nvidia-smi > $F
cat $F | grep " / " | while read line; do
	echo "├─ GPU $GPU:" `echo $line | cut -d "|" -f 3`
	cat $F | grep "|    $GPU     " | while read process; do
		PID=`echo $process | cut -d " " -f 3`
		CMD=`echo $process | cut -d " " -f 5`
		MEM=`echo $process | cut -d " " -f 6`
		USER=`ps -o user $PID | awk 'NR>1'`
		printf "│  ├─%8s" $MEM
		printf "%10s" $USER
		printf "%10s  " $PID
		echo "$CMD"
	done
	((GPU+=1))
done
