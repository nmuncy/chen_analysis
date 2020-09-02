#!/bin/bash

#SBATCH --time=01:00:00   # walltime
#SBATCH --ntasks=6   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=4gb   # memory per CPU core
#SBATCH -J "TS3"   # job name
#SBATCH --partition centos7_IB_44C_512G
#SBATCH --account iacc_madlab


# Written by Nathan Muncy on 10/24/18
#	Updated by Nathan Muncy on 8/10/2020


### --- Notes
#
# 1) Will do REML deconvolution (GLS), post files, and print out info
#
# 2) Can do a variable number of deconvolutions for each phase of the experiment
#		generates the scripts, and then runs them - turn off $runDecons for simple script generation
#
# 3) Assumes timing files exist in derivatives/sub-123/timing_files
#		so a wildcard can catch only timing 1D files
#
# 4) deconNum = number of planned decons per PHASE of experimet.
#		Number of positions corresponds to step1 $phaseArr
#		Enter number of desired decons for each pahse of experiment
#			e.g. deconNum=(1 2 1) means one decon from first phase, two from second, etc.
#		Note - A value must be entered for each phase, even if no decon is desired
#			e.g. deconNum=(0 1 0) for one only decon from second phase, and no others
#
# Updates:
#	1) adjusted decon, reml commands for EMU study
#	2) decon for each trial (not condition)
#	3) removed post-hoc checks
#	4) desired output is chenUpdate_foo_values.txt
#		this contains parameter estimates for each trial




module load afni-20.2.06
module load c3d/1.0.0



subj=$1
sess=$2


### --- Experimenter input --- ###
#
# Change parameters for your study in this section.

parDir=/scratch/madlab/chen_update				  			# parent dir, where derivatives is located
workDir=${parDir}/derivatives/${subj}/$sess
priorDir=~/bin/Templates/vold2_mni/priors_JLF

deconNum=(1)													# See Note 4 above
deconPref=(study)												# array of prefix for each planned decon (length must equal sum of $deconNum)

runDecons=1														# toggle for running reml scripts and post hoc (1=on) or just writing scripts (0)
runClean=$3														# toggle to clean (1=on) intermediates

# Update for ROI
priorNum=(0018)
priorNam=(LAmyg)







### --- Set up --- ###
#
# Determine number of phases, and number of blocks per phase
# then set these as arrays. Set up decon arrays.
# Function for writing decon script.


# patch - set up txt and nam arrays
cd ${workDir}/timing_files
unset txtstudy namstudy
txtArr=(`ls -1v *txt`)
c=0; for i in ${txtArr[@]}; do
	txtstudy[$c]=$i
	namstudy[$c]=${i%.*}
	let c+=1
done



cd $workDir
> tmp.txt
for i in run*scale+tlrc.HEAD; do
	tmp=${i%_*}
	run=${i%%_*}
	phase=${tmp#*_}
	echo -e "$run \t $phase" >> tmp.txt
done

awk -F '\t' '{print $2}' tmp.txt | sort | uniq -c > phase_list.txt
rm tmp.txt

blockArr=(`cat phase_list.txt | awk '{print $1}'`)
phaseArr=(`cat phase_list.txt | awk '{print $2}'`)
phaseLen=${#phaseArr[@]}

unset numDecon
for i in ${deconNum[@]}; do
	numDecon=$(( $numDecon + $i ))
done


# Function - write deconvolution script
GenDecon (){

	# assign vars for "readability"
	local h_tr=$1
	local h_phase=$2
	local h_block=$3
	local h_input=$4
	local h_out=$5
	local h_len=$6

    # extract nested arrays
    shift 6
    local h_arr=( "$@" )
    local nam=(${h_arr[@]:0:$h_len})
    local txt=(${h_arr[@]:$h_len})

    # keep track of number of regressors (num_stimts) via counting var x
    x=1

	# build motion list
	unset stimBase
    for ((r=1; r<=${h_block}; r++)); do
        for ((b=0; b<=5; b++)); do
            stimBase+="-stim_file $x mot_demean_${h_phase}.r0${r}.1D'[$b]' -stim_base $x -stim_label $x mot_$x "
            let x=$[$x+1]
        done
    done

	# build behavior list
	unset stimBeh
	cc=0; while [ $cc -lt ${#txt[@]} ]; do
		stimBeh+="-stim_times_AM1 $x timing_files/${txt[$cc]} \"dmBLOCK(1)\" -stim_label $x ${nam[$cc]} "
		let x=$[$x+1]
		let cc=$[$cc+1]
	done

	# num_stimts
    h_nstim=$(($x-1))

	# write script
    echo "3dDeconvolve \
    -x1D_stop \
    -input1D $h_input \
    -TR_1D $h_tr \
    -censor censor_${h_phase}_combined.1D \
    -polort A -float \
    -num_stimts $h_nstim \
    $stimBase \
    $stimBeh \
    -jobs 6 \
    -x1D X.${h_out}.xmat.1D \
    -xjpeg X.${h_out}.jpg \
    -x1D_uncensored X.${h_out}.nocensor.xmat.1D \
    -bucket ${h_out}_stats -errts ${h_out}_errts" > ${h_out}_deconv.sh
}




### --- Motion --- ###
#
# motion and censor files are constructed. Multiple motion files
# include mean and derivative of motion.

c=0; while [ $c -lt $phaseLen ]; do

	phase=${phaseArr[$c]}
	nruns=${blockArr[$c]}
	cat dfile.run-*${phase}.1D > dfile_rall_${phase}.1D

	if [ ! -s censor_${phase}_combined.1D ]; then

		# files: de-meaned, motion params (per phase) - updated for EMU (0.3 -> 1)
		1d_tool.py -infile dfile_rall_${phase}.1D -set_nruns $nruns -demean -write motion_demean_${phase}.1D
		1d_tool.py -infile dfile_rall_${phase}.1D -set_nruns $nruns -derivative -demean -write motion_deriv_${phase}.1D
		1d_tool.py -infile motion_demean_${phase}.1D -set_nruns $nruns -split_into_pad_runs mot_demean_${phase}
		1d_tool.py -infile dfile_rall_${phase}.1D -set_nruns $nruns -show_censor_count -censor_prev_TR -censor_motion 1 motion_${phase}

		# determine censor
		cat out.cen.run-*${phase}.1D > outcount_censor_${phase}.1D
		1deval -a motion_${phase}_censor.1D -b outcount_censor_${phase}.1D -expr "a*b" > censor_${phase}_combined.1D
	fi
	let c=$[$c+1]
done




### --- Deconvolve --- ###
#
# A deconvolution script (foo_deconv.sh) is generated and ran for
# each planned deconvolution.
#
# Update: for each ROI's mean time series

# loop through experiment phases
c=0; count=0; while [ $c -lt $phaseLen ]; do
	phase=${phaseArr[$c]}

	# loop through ROIs
	cc=0; while [ $cc -lt ${#priorNam[@]} ]; do
		
		# get, resample ROI mask
		prior=${priorDir}/label_${priorNum[$cc]}.nii.gz
		label=label_${priorNam[$cc]}
		
		if [ ! -f ${label}+tlrc.HEAD ]; then
			c3d $prior -thresh 0.3 1 1 0 -o ./tmp_${label}.nii.gz
			3dresample -master run-1_${deconPref[0]}_scale+tlrc -rmode NN -input tmp_${label}.nii.gz -prefix tmp_${label}+tlrc
			3dcalc -a tmp_${label}+tlrc -expr 'step(a-0.999)' -prefix ${label}+tlrc
		fi

		# extract mean time series of each ROI*run
		> input.1D
		for j in run-*${phase}_scale+tlrc.HEAD; do
			if [ ! -s ${j%_*}_${label}_AVG.1D ]; then
				3dmaskave -quiet -mask ${label}+tlrc ${j%.*} > ${j%_*}_${label}_AVG.1D
			fi
			cat ${j%_*}_${label}_AVG.1D >> input.1D
		done

		# determine TR duration (for 1D file), use last iteration of j loop above
		holdTR=`3dinfo -tr ${j%.*}`
		input=input.1D 			### just to keep things consistent

		# loop through planned decons
		numD=${deconNum[$c]}
		for(( i=1; i<=$numD; i++)); do

			# determine timing files for decon
			out=${deconPref[$count]}
			holdName=($(eval echo \${nam${out}[@]}))
			holdTxt=$(eval echo \${txt${out}[@]})

			# write script
			GenDecon $holdTR $phase ${blockArr[$c]} "$input" $out ${#holdName[@]} ${holdName[@]} $holdTxt

			# run script, to generate reml_cmd script and matrices
			if [ -f ${out}_stats.REML_cmd ]; then
				rm ${out}_stats.REML_cmd
			fi
			source ${out}_deconv.sh

			count=$(($count+1))
		done
		let cc+=1
	done
	let c=$[$c+1]
done




#### --- REML and Post Calcs --- ###
#
# REML deconvolution (GLS) is run, excluding WM signal.
# Global SNR and corr are calculated.

# loop through experiment phases
c=0; count=0; while [ $c -lt $phaseLen ]; do

	# loop through number of planned decons, set arr
	phase=${phaseArr[$c]}
	numD=${deconNum[$c]}
	x=0; for((i=1; i<=$numD; i++)); do
		regArr[$x]=${deconPref[$count]}
		let x=$[$x+1]
		let count=$[$count+1]
	done


	# loop thorugh planned decons
	for j in ${regArr[@]}; do
		if [ $runDecons == 1 ]; then

			# write, run a 1D REML script
			echo "3dREMLfit -input input.1D\\' -matrix X.${j}.xmat.1D \
			-Rbuck ${j}_stats_REML -Rvar ${j}_stats_REMLvar -Rerrts ${j}_errts_REML \
			-GOFORIT -verb" > chenUpdate_${j}_cmd

			if [ ! -s ${j}_stats_REML.1D ]; then
				tcsh -x chenUpdate_${j}_cmd
			fi


			# make output txt (will be space-separated)
			if [ -s ${j}_stats_REML.1D ]; then

				printOut=chenUpdate_${j}_values.txt
				> $printOut

				colHold=`sed -n 8p ${j}_stats_REML.1D`
				colTmp=${colHold#*\"}; colClean=${colTmp%?}
				colOut=`echo $colClean | sed -e "s/;/\t/g"`

				# valHold=`sed -n 10p ${j}_stats_REML.1D`
				valOut=`sed -n 10p ${j}_stats_REML.1D | sed -s "s/ \+ /\t/g"`
				echo $colOut >> $printOut
				echo $valOut >> $printOut
			else
				echo "" >&2
				echo "Problem with REML cmd script. No output detected. Exit 5." >&2
				echo "" >&2
				exit 5
			fi
		fi

		# detect pairwise cor
		1d_tool.py -show_cormat_warnings -infile X.${j}.xmat.1D | tee out.${j}.cormat_warn.txt
	done
	let c=$[$c+1]
done


if [ $runClean == 1 ]; then
	if [ -s chenUpdate_${deconPref[0]}_values.txt ]; then
		rm tmp*
		rm 3d*
		rm anat*
		rm -r awpy
		rm dfile*
		rm epi*
		rm final*
		rm full_mask*
		rm label*
		rm mask*
		rm mat*
		rm mot*
		rm out*
		rm phase*
		rm run*epiExt*
		rm run*volreg*
		rm struct_al*
		rm struct_ns+orig*
		rm study_{errts,stats}*
		rm study_WM*
		rm Template*
	fi
fi
