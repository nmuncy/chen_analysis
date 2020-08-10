#!/bin/bash




###--- Notes:
#
# Make sure emuR01_env IS LOADED!



hold=`c3d -version`
if [[ -z $hold ]]; then
	echo ""; 
	echo "Please activate emuR01_env. Exiting ..."; 
	echo ""; exit 1
fi


parDir=/home/data/madlab/McMakin_EMUR01  ###??? update this
scriptDir=${parDir}/code/mri_pipeline
workDir=${parDir}/derivatives/chen_update
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/TS2_${time}

mkdir -p $outDir

cd $workDir
for i in sub-*; do
	for j in ses-S1; do

		sbatch \
	    -o ${outDir}/output_TS2_${i}_${j}.txt \
	    -e ${outDir}/error_TS2_${i}_${j}.txt \
	    ${scriptDir}/step2_job.sh $i $j

		sleep 1
	done
done

