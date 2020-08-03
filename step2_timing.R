

# # Receive passed arguments
# args <- commandArgs()
# subj <- args[6]
# sess <- paste0("ses-S",args[7])
# 
# # Orienting vars
# rawDir <- paste0("/home/data/madlab/McMakin_EMUR01/dset/",subj,"/",sess,"/func/")
# outDir <- paste0("~/compute/ChenTest/derivatives/",subj,"/",sess,"/timing_files/")

# For local testing
subj <- "sub-4002"
sess <- "ses-S1"
rawDir <- "/home/nate/Projects/ChenTest/dset/sub-4002/ses-S1/func/"
outDir <- "/home/nate/Projects/ChenTest/derivatives/sub-4002/ses-S1/timing_files/"


# # for testing
# rawDir <- "/home/nate/Projects/emu-project/mri_pipeline/timing_files/"
# outDir <- "/home/nate/Projects/emu-project/mri_pipeline/timing_files/"
# subj <- "sub-4002"
# sess <- "ses-S1"

# Set vars for trial count, time adjustment
trialNum <- 1
adjustTime <- 1.76 * 305    ### hard coded for now

# Loop through runs
for(i in 1:2){

  # Read in data  
  rawString <- paste0(rawDir,subj,"_",sess,"_task-study_run-",i,"_events.tsv")
  rawData <- read.delim(rawString, header = T, sep = "\t")

  # Loop through trials (rows of rawData)
  for(j in 1:dim(rawData)[1]){
    
    # Determine onset, duration, output string, stimulus name
    # onset <- adjustTime + round(rawData[j,1],digits=1)
    if(i == 1){
      onset <- round(rawData[j,1],digits=1)
    }else{
      onset <- adjustTime + round(rawData[j,1],digits=1)
    }
    duration <- rawData[j,2]
    output <- paste0(onset,":",duration)
    stim_file <- gsub(".jpg","",as.character(rawData[j,4]))
    

    
    # Determine response, write Type+Resp
    if(grepl("n/a",rawData[j,6]) == F){
      typeResp <- paste0(rawData[j,3],rawData[j,6])
    }else{
      typeResp <- paste0(rawData[j,3],"X")
    }
    
    # Set out file
    outString <- paste0("T",trialNum,"_",typeResp,"_",stim_file)
    outFile <- paste0(outDir,outString,".txt")
    
    ## write out file
    # if(i == 1){
    #   cat(output, "\n", file=outFile, append = F)
    #   cat ("*", "\n", file=outFile, append = T)
    # }else{
    #   cat ("*", "\n", file=outFile, append = F)
    #   cat(output, "\n", file=outFile, append = T)
    # }
    cat(output, "\n", file=outFile, append = F)
    
    # Increase trial
    trialNum <- trialNum + 1
  }
  
  # Increase adjust time (by onset+duration of last trial of run)
  # adjustTime <- adjustTime + round(rawData[j,1],1) + rawData[j,2]
}

