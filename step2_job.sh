#!/bin/bash

#SBATCH --time=00:05:00   # walltime
#SBATCH --ntasks=1   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=2gb   # memory per CPU core
#SBATCH -J "TS2"   # job name
#SBATCH --partition IB_44C_512G
#SBATCH --account iacc_madlab

# #SBATCH --qos pq_madlab
# #SBATCH -o /scratch/madlab/crash/rtv_temp2epi_o
# #SBATCH -e /scratch/madlab/crash/rtv_temp2epi_e




###--- Notes:
#
# Needs to be run on --partition IB_44C_512G
#
# This script submits the R script



subj=$1
sess=$2

parDir=/scratch/madlab/chen_update
workDir=${parDir}/derivatives/${subj}/$sess
codeDir=${parDir}/code

mkdir ${workDir}/timing_files
Rscript ${codeDir}/step2_timing.R $subj $sess