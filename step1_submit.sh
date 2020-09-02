#!/bin/bash



###--- Notes:
#
# This should be submitted from a clean environment 
#	e.g. don't have emuR01_env active



parDir=/scratch/madlab/chen_update  ###??? update this
scriptDir=~/compute/chen_analysis
workDir=${parDir}/derivatives

slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/TS1_${time}

mkdir -p $outDir



cd $workDir

for i in sub*; do
	for j in ses-S1; do
		if [ ! -f ${i}/${j}/run-1_study_scale+tlrc.HEAD ]; then

		    sbatch \
		    -o ${outDir}/output_TS1_${i}_${j}.txt \
		    -e ${outDir}/error_TS1_${i}_${j}.txt \
		    ${scriptDir}/step1_sbatch_preproc.sh $i $j

		    sleep 1
		fi
	done
done
