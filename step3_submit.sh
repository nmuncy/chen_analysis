#!/bin/bash



parDir=/scratch/madlab/chen_test  ###??? update this
scriptDir=${parDir}/code/mri_pipeline
workDir=${parDir}/derivatives

slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/TS3_${time}

mkdir -p $outDir

cd $workDir
for i in sub*; do
	for j in ses-S1; do
		if [ ! -f ${i}/${j}/study_stats_REML+tlrc.HEAD ]; then

			# determine cleaning arg (don't clean for sub-4002)
			[ $i != sub-4002 ]
			status=$?

		    sbatch \
		    -o ${outDir}/output_TS3_${i}.txt \
		    -e ${outDir}/error_TS3_${i}.txt \
		    ${scriptDir}/step3_sbatch_regress.sh $i $j $status

		    sleep 1
		fi
	done
done
