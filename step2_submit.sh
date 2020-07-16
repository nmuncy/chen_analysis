#!/bin/bash


parDir=~/compute/ChenTest
workDir=${parDir}/derivatives
scriptDir=${parDir}/code

cd $workDir
for i in s*; do
	# for j in 1 2; do
	for j in 1; do

		sbatch \
	    ${scriptDir}/step2_job.sh $i $j

		sleep 1
	done
done

