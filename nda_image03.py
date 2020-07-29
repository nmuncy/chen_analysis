#!/bin/env python


### get modules
import os
import csv
import tarfile
import pydicom




### Set variables
dataDir = "/home/nate/Projects/emu-project/mri_pipeline/dset"
dicomDir = dataDir

outDir = "/home/nate/Projects/emu-project/mri_pipeline/ndaOutdir"
ndaTemplate = os.path.join(outDir,"image03_template.csv")
outFile = os.path.join(outDir,"test.csv")




### set functions

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
def append_dict_as_row(file_name, dict_of_elem, field_names):
	with open(file_name, 'a+') as write_obj:
		dict_writer = csv.writer(write_obj)
		dict_writer = csv.DictWriter(write_obj, fieldnames = field_names)
		dict_writer.writerow(dict_of_elem)


# Calc age in months, round month
#	Account for scanning earlier in year than bday,
#	and add a month if participant > age+15 days at 
#	time of acq (round to nearest chron month per reqs).
# 		datetime is for punks.
def calcAge(acqString, bdayString):

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

	# Account for days, I rival you to find a better solution
	monthAdd = 0
	if acqDay >= bdayDay:
		if (acqDay - bdayDay) > 15:
			monthAdd = 1
	else:
		if (30 + acqDay - bdayDay) > 15:
			monthAdd = 1

	output = 12 * numYears + numMonths + monthAdd
	return output




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

		# temporarily unpack small reference dir from tar ball
		sesNum = j[4:]
		tarString = "McMakin_EMU-000-R01_" + subNum + sesNum + "-" + sesNum + ".tar.gz"
		# tarBall = tarfile.open(os.path.join(dicomDir,tarString),'r')
		# for member in tarBall.getmembers():
		# 	if "1-localizer_32ch" in member.name:
		# 		tarBall.extract(member, outDir)

		# determine, pull dicom header
		#	files from same scan session will share much information
		dicomPath = os.path.join(outDir, "scratch/akimb009/McMakin_EMU", tarString[:-7], "scans/1-localizer_32ch/resources/DICOM/files")
		dicomList = os.listdir(dicomPath)
		dicomHold = os.path.join(dicomPath, dicomList[0])
		dicomHead = pydicom.read_file(dicomHold)


		### extract, format some values that are consistent across session
		# acq date
		acqHold = dicomHead.AcquisitionDate
		acqDate = acqHold[4:6] + "/" + acqHold[6:] + "/" + acqHold[:4]

		# age
		bdayHold = dicomHead[0x10,0x30].value
		numMonths = calcAge(acqHold, bdayHold)

		# scan types per session
		scanList = MkScanList(i, j)
		for k in scanList:



			### TO DO: clean up image/scan_type



			# scans per scan type
			jsonList = MkJsonList(i, j, k)
			for m in jsonList:				
				
				### fill dictionary with required info
				# use column names as keys, order not important

				row_dict = {
				'src_subject_id': i, 
				'interview_date': acqDate, 
				'interview_age': numMonths,
				'sex': dicomHead[0x10,0x40].value,
				'image_description': k.upper(),
				'scan_type': k.upper(),
				'scan_object': "Live",
				'image_file_format': "DICOM",
				'image_modality': "MRI",
				'transformation_performed': "No"
				}

				append_dict_as_row(outFile, row_dict, ndaColumns)
				# print(row_dict)


		# clean unpacked tar ball
		# shutil.rmtree(os.path.join(outDir, "scratch"))



