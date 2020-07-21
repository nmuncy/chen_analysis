#!/bin/bash


workDir=~/compute/ChenTest
scriptDir=${workDir}/code
slurmDir=${workDir}/derivatives/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/TS2_${time}

mkdir -p $outDir

cd ${workDir}/derivatives
for i in sub-*; do
	# for j in 1 2; do
	for j in 1; do

		sbatch \
	    -o ${outDir}/output_TS2_${i}_${j}.txt \
	    -e ${outDir}/error_TS2_${i}_${j}.txt \
	    ${scriptDir}/step2_job.sh $i $j

		sleep 1
	done
done

