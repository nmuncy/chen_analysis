#!/bin/env python


# --- Notes
#
# Written for python3.7
#
# This script will write values to a NDA image03 template.
#
# Assumes MRI data is in BIDS format, and mines DICOM
# 	headers and JSON files for information. Specifically,
# 	a localizer DICOM is mined for subj info.
#
# Variables:
# 	tar_str and dicom_path are EMU-specific.#
# 	data_dir should be a path to the location of subject directories.
# 	dicom_dir should be a path to g-zipped tar files of DICOMs.
# 	nda_template is downloaded nda image03 template, used to get column headers.
# 	out_file is location/name of output csv.
#
# TODO:
# 	Update experiment_id fMRI section.


# %%
# Get modules
import os
import csv
import tarfile
import pydicom
import json
import shutil
import pandas as pd


# %%
# Set variables
data_dir = "/home/nate/Projects/emu-project/mri_pipeline/dset"
dicom_dir = data_dir

out_dir = "/home/nate/Projects/emu-project/mri_pipeline/ndaOutdir"
nda_template = os.path.join(out_dir, "image03_example.csv")
out_file = os.path.join(out_dir, "test.csv")


# %%
# Set Functions
# List scans in session
def func_scan_list(subj, sess):
    h_sessList = []
    h_sessDir = os.path.join(data_dir, subj, sess)
    for content in os.listdir(h_sessDir):
        h_content = h_sessDir + "/" + content
        if os.path.isdir(h_content):
            h_sessList.append(content)
    return h_sessList


# List json files in scan dir
def func_json_list(subj, sess, scan):
    h_jsonList = []
    h_scanDir = os.path.join(data_dir, subj, sess, scan)
    for files in os.listdir(h_scanDir):
        if files.endswith(".json"):
            h_jsonList.append(files)
    return h_jsonList


# Append csv, will only append columns with input cols
# 	i.e. allows for missing cells, so only desired info
# 	can be written for reach row
def func_append_csv(file_name, dict_of_elem, field_names):
    with open(file_name, "a+") as write_obj:
        dict_writer = csv.writer(write_obj)
        dict_writer = csv.DictWriter(write_obj, fieldnames=field_names)
        dict_writer.writerow(dict_of_elem)


# Prepend csv, to add "image,03" to first row of output csv
def func_prepend_csv(file_name, line):
    dummy_file = file_name + ".bak"
    with open(file_name, "r") as read_obj, open(dummy_file, "w") as write_obj:
        write_obj.write(line + "\n")
        for line in read_obj:
            write_obj.write(line)
    os.remove(file_name)
    os.rename(dummy_file, file_name)


# Calc age in months, round month
# 	Account for scanning earlier in year than bday,
# 	and add a month if participant > age+15 days at
# 	time of acq (round to nearest chron month per reqs).
# 		datetime is for punks.
def func_calc_age(acq_str, bday_str):

    # split, convert input
    acq_yr = int(acq_str[:4])
    acq_mo = int(acq_str[4:6])
    acq_da = int(acq_str[6:])

    bday_yr = int(bday_str[:4])
    bday_mo = int(bday_str[4:6])
    bday_da = int(bday_str[6:])

    # determine num years and months
    if acq_mo > bday_mo:
        num_yr = acq_yr - bday_yr
        num_mo = acq_mo - bday_mo
    else:
        num_yr = acq_yr - bday_yr - 1
        num_mo = 12 + acq_mo - bday_mo

    # Determine if it has been more than 15 days between
    #   birth day and scan, add 1 month or 0 accordingly.
    # 	Ugly, but I rival you to find a better solution
    add_mo = 0
    if acq_da >= bday_da:
        if (acq_da - bday_da) > 15:
            add_mo = 1
    else:
        if (30 + acq_da - bday_da) > 15:
            add_mo = 1

    output = 12 * num_yr + num_mo + add_mo
    return output


# %%
# Set Dictionaries
# 	A highly repetitive dict of SeriesDescriptions from
# 	json file. All scans acquired in ses-1/2
image_dict = {
    "dMRI": ["DWI"],
    "T1w_MPR_vNav": ["MP-RAGE"],
    "pd_tse_Cor_T2_PDHR_FCS": ["PD"],
    "fMRI_Emotion_REST": ["fMRI", "resting_state", "rs"],
    "fMRI_Emotion_PS_Study_1": ["fMRI", "emotion_encode", "run-1"],
    "fMRI_Emotion_PS_Study_2": ["fMRI", "emotion_encode", "run-2"],
    "fMRI_Emotion_PS_Test_1": ["fMRI", "emotion_test", "run-1"],
    "fMRI_Emotion_PS_Test_2": ["fMRI", "emotion_test", "run-2"],
    "fMRI_Emotion_PS_Test_3": ["fMRI", "emotion_test", "run-3"],
    "fMRI_DistortionMap_AP_Rest": ["fMRI", "resting_state_field_map_AP", "fmap"],
    "fMRI_DistortionMap_PA_Rest": ["fMRI", "resting_state_field_map_PQ", "fmap"],
    "fMRI_DistortionMap_AP_PS_STUDY": ["fMRI", "emotion_encoding_field_map_AP", "fmap"],
    "fMRI_DistortionMap_PA_PS_STUDY": ["fMRI", "emotion_encoding_field_map_PS", "fmap"],
    "fMRI_DistortionMap_AP_Test": ["fMRI", "emotion_test_field_map_AP", "fmap"],
    "fMRI_DistortionMap_PA_Test": ["fMRI", "emotion_test_field_map_PA", "fmap"],
    "dMRI_DistortionMap_AP_dMRI": ["DWI", "field_map_AP"],
    "dMRI_DistortionMap_PA_dMRI": ["DWI", "field_map_PA"],
}

# put value of image_dict into req format for scan_type
scan_dict = {"DWI": "multi-shell DTI", "MP-RAGE": "MPRAGE", "fMRI": "fMRI", "PD": "PD"}


# %%
# Set up NDA csv
# get column names
with open(nda_template) as fd:
    reader = csv.reader(fd)
    hold_cols = [row for idx, row in enumerate(reader) if idx == 1]

nda_cols = hold_cols[0]


# %%
# start new csv
with open(out_file, "w") as file:
    writer = csv.writer(file)
    writer.writerow(nda_cols)

# Start Main
# get list of subjects
subj_list = [i for i in os.listdir(data_dir) if "sub-" in i]
for i in subj_list:

    # get list of sessions
    sub_num = i[4:]
    sess_list = os.listdir(os.path.join(data_dir, i))
    for j in sess_list:

        # temporarily unpack small reference dir from tar ball
        ses_num = j[4:]
        tar_str = "McMakin_EMU-000-R01_" + sub_num + ses_num + "-" + ses_num + ".tar.gz"
        tar_ball = tarfile.open(os.path.join(dicom_dir, tar_str), "r")

        # join member, outdir
        for member in tar_ball.getmembers():
            if "1-localizer_32ch" in member.name:
                tar_ball.extract(member, out_dir)

        # determine, pull dicom header
        # 	files from same scan session will share much information
        dicom_path = os.path.join(
            out_dir,
            "scratch/akimb009/McMakin_EMU",
            tar_str[:-7],
            "scans/1-localizer_32ch/resources/DICOM/files",
        )
        dicom_list = os.listdir(dicom_path)
        dicom_hold = os.path.join(dicom_path, dicom_list[0])
        dicom_head = pydicom.read_file(dicom_hold)

        # extract, format some values that are consistent across session
        # interview_date
        acq_hold = dicom_head.AcquisitionDate
        acq_date = acq_hold[4:6] + "/" + acq_hold[6:] + "/" + acq_hold[:4]

        # interview_age
        bday_hold = dicom_head[0x10, 0x30].value
        num_mo = func_calc_age(acq_hold, bday_hold)

        # scan types per session
        scan_list = func_scan_list(i, j)
        for k in scan_list:

            # scans per scan type
            json_list = func_json_list(i, j, k)
            for m in json_list:

                # fill row_dict with image03 required info
                #   pull json info
                json_file = os.path.join(data_dir, i, j, k, m)
                with open(json_file) as f:
                    json_dict = json.load(f)

                # image_description
                image_list = image_dict[json_dict["SeriesDescription"]]
                if len(image_list) > 1:
                    image_desc = image_list[0] + " " + image_list[1]
                else:
                    image_desc = image_list[0]

                # scan_type
                scan_type = scan_dict[image_list[0]]

                # image_num_dimensions
                if scan_type == "fMRI":
                    img_dim = 4
                else:
                    img_dim = 3

                # key = nda column name
                row_dict = {
                    "src_subject_id": i,
                    "interview_date": acq_date,
                    "interview_age": num_mo,
                    "sex": dicom_head[0x10, 0x40].value,
                    "image_description": image_desc,
                    "scan_type": scan_type,
                    "scan_object": "Live",
                    "image_file_format": "NIFTI",
                    "image_modality": "MRI",
                    "transformation_performed": "No",
                    "scanner_manufacturer_pd": json_dict["Manufacturer"],
                    "scanner_type_pd": json_dict["ManufacturersModelName"],
                    "scanner_software_versions_pd": dicom_head.SoftwareVersions,
                    "magnetic_field_strength": json_dict["MagneticFieldStrength"],
                    "mri_repetition_time_pd": json_dict["RepetitionTime"],
                    "mri_echo_time_pd": json_dict["EchoTime"],
                    "flip_angle": json_dict["FlipAngle"],
                    "acquisition_matrix": "TODO",
                    "mri_field_of_view_pd": "TODO",
                    "patient_position": dicom_head.PatientPosition,
                    "photomet_interpret": dicom_head[0x28, 0x04].value,
                    "image_num_dimensions": img_dim,
                    "image_extent1": "TODO",
                }

                if scan_type == "fMRI":
                    row_dict["experiment_id"] = image_list[2]

                if image_desc == "DWI":
                    row_dict["bvek_bval_files"] = "Yes"

                # write appropriate columns to csv
                func_append_csv(out_file, row_dict, nda_cols)

                # clean unpacked tar file
                if os.path.exists(os.path.join(out_dir, "home")):
                    shutil.rmtree(os.path.join(out_dir, "home"))

# Add back first column
# func_prepend_csv(out_file, "image,03")
hold = pd.read_csv(out_file)
print(hold)


# %%
