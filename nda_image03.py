#!/bin/env python


### --- Notes
#
# Written for python3.7
#
# This script will write values to a NDA image03 template.
#
# Assumes MRI data is in BIDS format, and mines DICOM
#	headers and JSON files for information. Specifically, 
#	a localizer DICOM is mined for subj info.
#
# Variables:
# 	tarString and dicomPath are EMU-specific.#
# 	dataDir should be a path to the location of subject directories.
# 	dicomDir should be a path to g-zipped tar files of DICOMs.
# 	ndaTemplate is downloaded nda image03 template, used to get column headers.
# 	outFile is location/name of output csv.
#
# TODO:
#	Update experiment_id fMRI section.




### Get modules
import os
import csv
import tarfile
import pydicom
import json
import shutil




### Set variables
dataDir = "/home/nate/Projects/emu-project/mri_pipeline/dset"
dicomDir = dataDir

outDir = "/home/nate/Projects/emu-project/mri_pipeline/ndaOutdir"
ndaTemplate = os.path.join(outDir,"image03_template.csv")
outFile = os.path.join(outDir,"test.csv")




### Set Functions
# List scans in session
def MkScanList(subj, sess):
	h_sessList = []
	h_sessDir = os.path.join(dataDir, subj, sess)
	for content in os.listdir(h_sessDir):
		holdContent = h_sessDir + "/" + content
		if os.path.isdir(holdContent):
			h_sessList.append(content)
	return h_sessList

# List json files in scan dir
def MkJsonList(subj, sess, scan):
	h_jsonList = []
	h_scanDir = os.path.join(dataDir, subj, sess, scan)
	for files in os.listdir(h_scanDir):
		if files.endswith('.json'):
			h_jsonList.append(files)
	return h_jsonList

# Append csv, will only append columns with input cols
#	i.e. allows for missing cells, so only desired info
#	can be written for reach row
def AppendCsv(file_name, dict_of_elem, field_names):
	with open(file_name, 'a+') as write_obj:
		dict_writer = csv.writer(write_obj)
		dict_writer = csv.DictWriter(write_obj, fieldnames = field_names)
		dict_writer.writerow(dict_of_elem)

# Prepend csv, to add "image,03" to first row of output csv
def PrependLine(file_name, line):
    dummy_file = file_name + '.bak'
    with open(file_name, 'r') as read_obj, open(dummy_file, 'w') as write_obj:
        write_obj.write(line + '\n')
        for line in read_obj:
            write_obj.write(line)
    os.remove(file_name)
    os.rename(dummy_file, file_name)

# Calc age in months, round month
#	Account for scanning earlier in year than bday,
#	and add a month if participant > age+15 days at 
#	time of acq (round to nearest chron month per reqs).
# 		datetime is for punks.
def CalcAge(acqString, bdayString):

	# split, convert input
	acqYear = int(acqString[:4])
	acqMonth = int(acqString[4:6])
	acqDay = int(acqString[6:])

	bdayYear = int(bdayString[:4])
	bdayMonth = int(bdayString[4:6])
	bdayDay = int(bdayString[6:])

	# determine num years and months
	if acqMonth > bdayMonth:
		numYears = acqYear - bdayYear
		numMonths = acqMonth - bdayMonth
	else:
		numYears = acqYear - bdayYear - 1
		numMonths = 12 + acqMonth - bdayMonth

	# Determine if it has been more than 15 days between
	# birth day and scan, add 1 month or 0 accordingly.
	#	Ugly, but I rival you to find a better solution
	monthAdd = 0
	if acqDay >= bdayDay:
		if (acqDay - bdayDay) > 15:
			monthAdd = 1
	else:
		if (30 + acqDay - bdayDay) > 15:
			monthAdd = 1

	output = 12 * numYears + numMonths + monthAdd
	return output




### Set Dictionaries
# A highly repetitive dict of SeriesDescriptions from
#	json file. All scans acquired in ses-1/2
imageDict = {
	"dMRI" : "DWI",
	"T1w_MPR_vNav" : "MP-RAGE",
	"pd_tse_Cor_T2_PDHR_FCS" : "PD",
	"fMRI_Emotion_REST" : "fMRI",
	"fMRI_Emotion_PS_Study_1" : "fMRI",
	"fMRI_Emotion_PS_Study_2" : "fMRI",
	"fMRI_Emotion_PS_Test_1" : "fMRI",
	"fMRI_Emotion_PS_Test_2" : "fMRI",
	"fMRI_Emotion_PS_Test_3" : "fMRI",
	"fMRI_DistortionMap_AP_Rest" : "fMRI",
	"fMRI_DistortionMap_PA_Rest" : "fMRI",
	"fMRI_DistortionMap_AP_PS_STUDY" : "fMRI",
	"fMRI_DistortionMap_PA_PS_STUDY" : "fMRI",
	"fMRI_DistortionMap_AP_Test" : "fMRI",
	"fMRI_DistortionMap_PA_Test" : "fMRI",
	"dMRI_DistortionMap_AP_dMRI" : "DWI",
	"dMRI_DistortionMap_PA_dMRI" : "DWI"
}

# put value of imageDict into req format for scan_type
scanDict = {
	"DWI" : "multi-shell DTI",
	"MP-RAGE" : "MPRAGE",
	"fMRI" : "fMRI",
	"PD" : "PD"
}

	

### Set up NDA csv
# get column names
with open(ndaTemplate) as fd:
	reader = csv.reader(fd)
	holdCols = [row for idx, row in enumerate(reader) if idx == 1]

ndaColumns = holdCols[0]

# start new csv
with open(outFile, 'w') as file:
	writer = csv.writer(file)
	writer.writerow(ndaColumns)




### Start Main
# get list of subjects
subjList = [i for i in os.listdir(dataDir) if 'sub-' in i]
for i in subjList:

	# get list of sessions
	subNum = i[4:]
	sessList = os.listdir(os.path.join(dataDir, i))
	for j in sessList:

		## temporarily unpack small reference dir from tar ball
		sesNum = j[4:]
		tarString = "McMakin_EMU-000-R01_" + subNum + sesNum + "-" + sesNum + ".tar.gz"
		tarBall = tarfile.open(os.path.join(dicomDir,tarString),'r')
		for member in tarBall.getmembers():
			if "1-localizer_32ch" in member.name:
				tarBall.extract(member, outDir)

		# determine, pull dicom header
		#	files from same scan session will share much information
		dicomPath = os.path.join(outDir, "scratch/akimb009/McMakin_EMU", tarString[:-7], "scans/1-localizer_32ch/resources/DICOM/files")
		dicomList = os.listdir(dicomPath)
		dicomHold = os.path.join(dicomPath, dicomList[0])
		dicomHead = pydicom.read_file(dicomHold)


		## extract, format some values that are consistent across session
		# interview_date
		acqHold = dicomHead.AcquisitionDate
		acqDate = acqHold[4:6] + "/" + acqHold[6:] + "/" + acqHold[:4]

		# interview_age
		bdayHold = dicomHead[0x10,0x30].value
		numMonths = CalcAge(acqHold, bdayHold)

		# scan types per session
		scanList = MkScanList(i, j)
		for k in scanList:

			# scans per scan type
			jsonList = MkJsonList(i, j, k)
			for m in jsonList:


				## fill rowDict with image03 required info
				# pull json info
				jsonFile = os.path.join(dataDir,i,j,k,m)
				with open(jsonFile) as f:
					jsonDict = json.load(f)

				# image_description
				imageDesc = imageDict[jsonDict["SeriesDescription"]]

				# scan_type
				scanType = scanDict[imageDesc]

				# key = nda column name
				rowDict = {
				'src_subject_id': i, 
				'interview_date': acqDate, 
				'interview_age': numMonths,
				'sex': dicomHead[0x10,0x40].value,
				'image_description': imageDesc,
				'scan_type': scanType,
				'scan_object': "Live",
				'image_file_format': "DICOM",
				'image_modality': "MRI",
				'transformation_performed': "No"
				}


				## append dict with conditional info
				# experiment_id - will likely need separate values
				#	for task, rs, fmap
				if scanType == "fMRI":
					rowDict["experiment_id"] = "TODO"

				if imageDesc == "DWI":
					rowDict["bvek_bval_files"] = "Yes"


				## write appropriate columns to csv
				AppendCsv(outFile, rowDict, ndaColumns)

		# clean unpacked tar file
		shutil.rmtree(os.path.join(outDir, "scratch"))

# Add back first column
PrependLine(outFile, "image,03")