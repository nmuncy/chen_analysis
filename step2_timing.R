




# Written by Nathan Muncy on 8/10/2020


### --- Notes:
#
# This script will mine func events.tsv files to 
# construct a timing file for each trial.
#
# Currently has card coded sections, written for emotional
# valence judgments



# Receive passed arguments (subject, session)
args <- commandArgs()
subj <- args[6]
sess <- args[7]


### Orienting vars, update this
rawDir <- paste0("/home/data/madlab/McMakin_EMUR01/dset/",subj,"/",sess,"/func/")
outDir <- paste0("/scratch/madlab/chen_analysis/derivatives/",subj,"/",sess,"/timing_files/")


### Start job
# Set vars for trial count, time adjustment
trialNum <- 1
adjustTime <- 1.76 * 305    ### hard coded for now

# Loop through runs, currently hardcoded for 2 runs
for(i in 1:2){

  # Read in data  
  rawString <- paste0(rawDir,subj,"_",sess,"_task-study_run-",i,"_events.tsv")
  rawData <- read.delim(rawString, header = T, sep = "\t")

  # Loop through trials (rows of rawData)
  for(j in 1:dim(rawData)[1]){
    
    # Determine onset, duration, output string, stimulus name
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
    
    # Set, write out file
    outString <- paste0("T",trialNum,"_",typeResp,"_",stim_file)
    outFile <- paste0(outDir,outString,".txt")
    cat(output, "\n", file=outFile, append = F)
    
    # Increase trial
    trialNum <- trialNum + 1
  }
}

