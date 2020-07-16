#!/bin/bash




###??? update these
workDir=~/compute/ChenTest
scriptDir=${workDir}/code
slurmDir=${workDir}/derivatives/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/TS3_${time}

mkdir -p $outDir

cd ${workDir}/derivatives
for i in sub*; do
	# for j in ses-S{1,2}; do
	for j in ses-S1; do
		if [ ! -f ${i}/${j}/study_stats_REML+tlrc.HEAD ]; then

		    sbatch \
		    -o ${outDir}/output_TS3_${i}.txt \
		    -e ${outDir}/error_TS3_${i}.txt \
		    ${scriptDir}/step3_sbatch_regress.sh $i $j

		    sleep 1
		fi
done
