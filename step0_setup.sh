#!/bin/bash



###--- Notes:
#
# This script will set up necessary dir 
# hiearchies for subsequent scripts


dataDir=/home/data/madlab/McMakin_EMUR01/dset
workDir=/scratch/madlab/chen_update/derivatives

cd $dataDir
for i in sub-*; do
	if [ -f ${i}/ses-S1/${i}_ses-S1_scans.tsv ]; then
		mkdir -p ${workDir}/${i}/ses-S1
	fi
done
