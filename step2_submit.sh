#!/bin/bash




###--- Notes:
#
# Make sure emuR01_env is loaded!



hold=`c3d -version`
if [[ -z $hold ]]; then
	echo ""; 
	echo "Please activate emuR01_env. Exiting ..."; 
	echo ""; exit 1
fi


parDir=/scratch/madlab/chen_analysis  ###??? update this
scriptDir=${parDir}/code
workDir=${parDir}/derivatives
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/TS2_${time}

mkdir -p $outDir

cd $workDir
for i in sub-*; do
	for j in ses-S1; do

		# only submit if there are not enough timing files
		#	e.g. when a previous submission failed
		timeDir=${workDir}/${i}/${j}/timing_files
		numTime=`ls $timeDir | wc -l`
		
		if [ ! -d $timeDir ] || [ $numTime < 100 ]; then

			sbatch \
		    -o ${outDir}/output_TS2_${i}_${j}.txt \
		    -e ${outDir}/error_TS2_${i}_${j}.txt \
		    ${scriptDir}/step2_job.sh $i $j

			sleep 1
		fi
	done
done

