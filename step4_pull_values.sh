#!/bin/bash




###--- Notes
#
# This script will write a space-separated file
#	of the parameter estimates for each subject.
#
# They will be aligned with timing files.


parDir=/scratch/madlab/chen_update
workDir=${parDir}/derivatives
outDir=${parDir}/csvOut
refDir=${workDir}/sub-4002/ses-S1

mkdir $outDir
print=${outDir}/TrialBetas.txt


# Start $print by writing col names
numTF=`ls ${refDir}/timing_files/ | wc -l`
unset firstLine
c=1; while [ $c -le $numTF ]; do
	firstLine+="Trial$c "
	let c+=1
done
echo -e "Subject Type $firstLine" > $print


cd $workDir
for i in s*; do

	# print only parameter estimates - every 2nd column starting at pos 1 (col 2)
	unset secondLine checkArr
	secondArr=(`tail -n 1 ${i}/ses-S1/chenUpdate_study_values.txt`)
	for((j=1; j<=${#secondArr[@]}; j+=2)); do
		value=${secondArr[$j]}
		secondLine+="$value "
		checkArr+=($value)
	done


	# print timing files (in order), check
	timingArr=(`ls -1v ${i}/ses-S1/timing_files`)
	
	if [ ${#checkArr[@]} != ${#timingArr[@]} ]; then
		echo "" >&2 ; echo "Error on $i" >&2
		echo "Number of timing files != to number of parameter estimates. Breaking ..." >&2
		echo "" >&2
		echo "$i StimResp_Image NaN" >> $print
		echo "$i ParaEst NaN" >> $print
		break
	fi

	unset timingLine
	for j in ${timingArr[@]}; do
		tmp=${j#*_}
		timingLine+="${tmp%.*} "
	done


	# write
	echo "$i StimResp_Image $timingLine" >> $print
	echo "$i ParaEst $secondLine" >> $print
done
	 