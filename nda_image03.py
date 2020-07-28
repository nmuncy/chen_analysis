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
def MkScanList(subj, sess):
	h_sessList = []
	h_sessDir = os.path.join(dataDir, subj, sess)
	for content in os.listdir(h_sessDir):
		holdContent = h_sessDir + "/" + content
		if os.path.isdir(holdContent):
			h_sessList.append(content)
	return h_sessList
# print MkScanList("sub-4002", "ses-S2")

def MkJsonList(subj, sess, scan):
	h_jsonList = []
	h_scanDir = os.path.join(dataDir, subj, sess, scan)
	for files in os.listdir(h_scanDir):
		if files.endswith('.json'):
			h_jsonList.append(files)
	return h_jsonList
# print(MkJsonList("sub-4002", "ses-S1", "anat"))

# from csv import DictWriter
def append_dict_as_row(file_name, dict_of_elem, field_names):
	with open(file_name, 'a+') as write_obj:
		dict_writer = csv.writer(write_obj)
		dict_writer = csv.DictWriter(write_obj, fieldnames = field_names)
		dict_writer.writerow(dict_of_elem)




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




### Mine files
subjList = [i for i in os.listdir(dataDir) if 'sub-' in i]
for i in subjList:

	subNum = i[4:]
	sessList = os.listdir(os.path.join(dataDir, i))

	for j in sessList:

		sesNum = j[4:]
		string = "McMakin_EMU-000-R01_" + subNum + sesNum + "-" + sesNum + ".tar.gz"

		# temporarily unpack small reference dir from tar ball
		# tarBall = tarfile.open(os.path.join(dicomDir,string),'r')
		# for member in tarBall.getmembers():
		# 	if "1-localizer_32ch" in member.name:
		# 		tarBall.extract(member, outDir)

		# determine, pull dicom header
		dicomPath = os.path.join(outDir, "scratch/akimb009/McMakin_EMU", string[:-7], "scans/1-localizer_32ch/resources/DICOM/files")
		dicomList = os.listdir(dicomPath)
		dicomHold = os.path.join(dicomPath, dicomList[0])
		dicomHead = pydicom.read_file(dicomHold)


		scanList = MkScanList(i, j)
		for k in scanList:

			jsonList = MkJsonList(i, j, k)
			# print(jsonList)



			### To Do: write this for each file in jsonList



			row_dict = {
			'src_subject_id': i, 
			'interview_date': dicomHead.AcquisitionDate, 
			'sex': dicomHead[0x10,0x40].value,
			'image_file': k
			}

			append_dict_as_row(outFile, row_dict, ndaColumns)
			print(row_dict)


		# clean unpacked tar ball
		# shutil.rmtree(os.path.join(outDir, "scratch"))



