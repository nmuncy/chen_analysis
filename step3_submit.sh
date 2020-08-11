#!/bin/bash




###--- Notes:
#
# Submit this from a clean environment (e.g. no emuR01_env)




parDir=/scratch/madlab/chen_update  ###??? update this
scriptDir=${parDir}/code
workDir=${parDir}/derivatives

slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/TS3_${time}

mkdir -p $outDir

cd $workDir
for i in sub*; do
	for j in ses-S1; do
		if [ ! -s ${i}/${j}/chenUpdate_study_values.txt ]; then

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
