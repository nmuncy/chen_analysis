#!/bin/env python


import os


dataDir = "/home/nate/Projects/emu-project/mri_pipeline/dset"
outDir = "/home/nate/Projects/emu-project/mri_pipeline"



def MkSessList(subj):
	return os.listdir(os.path.join(dataDir, subj))
# print MkSessList("sub-4002")

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


subjList = os.listdir(dataDir)
for i in subjList:
	print i
	sessList = MkSessList(i)
	# print sessList
	for j in sessList:
		print j
		scanList = MkScanList(i, j)
		# print scanList
		for k in scanList:
			print k
			jsonList = MkJsonList(i, j, k)
			# print jsonList



