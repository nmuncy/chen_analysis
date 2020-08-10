#!/bin/bash


# stderr and stdout are written to ${outDir}/error_* and ${outDir}/output_* for troubleshooting.
# job submission output are time stamped for troubleshooting




# # check for emuR01_env
# hold=`c3d -version`
# if [[ -z $hold ]]; then
# 	echo ""; 
# 	echo "please conda activate emuR01_env. exitting ..."; 
# 	echo ""; exit 1
# fi



parDir=/scratch/madlab/chen_test  ###??? update this

scriptDir=${parDir}/code/mri_pipeline
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
		    ${scriptDir}/step1_sbatch_preproc.sh $i $j $scriptDir

		    sleep 1
		fi
	done
done
