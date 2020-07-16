#!/bin/bash

#SBATCH --time=00:05:00   # walltime
#SBATCH --ntasks=1   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=2gb   # memory per CPU core
#SBATCH -J "TS2"   # job name


module load R/3.4.3

subj=$1
sess=$2

parDir=~/compute/ChenTest
workDir=${parDir}/derivatives/${subj}/ses-S${sess}
scriptDir=${parDir}/code

mkdir ${workDir}/timing_files
Rscript ${scriptDir}/step2_timing.R $subj $sess