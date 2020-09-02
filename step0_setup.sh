#!/bin/bash



###--- Notes:
#
# This script will set up necessary dir 
# hierarchies for subsequent scripts


dataDir=/home/data/madlab/McMakin_EMUR01/dset
workDir=/scratch/madlab/chen_update/derivatives

cd $dataDir
for i in sub-*; do
	for j in ses-S1; do
		if [ -f ${i}/${j}/${i}_ses-S1_scans.tsv ]; then
			mkdir -p ${workDir}/${i}/$j
		fi
	done
done
