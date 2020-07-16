
args <- commandArgs()
subj <- args[6]
sess <- paste0("ses-S",args[7])

rawDir <- paste0("/home/data/madlab/McMakin_EMUR01/dset/",subj,"/",sess,"/func/")
outDir <- paste0("~/compute/ChenTest/derivatives/",subj,"/",sess,"/timing_files/")

for(i in 1:2){
  
  rawString <- paste0(rawDir,subj,"_",sess,"_task-study_run-",i,"_events.tsv")
  rawData <- read.delim(rawString, header = T, sep = "\t")
  
  for(j in 1:dim(rawData)[1]){
    
    onset <- round(rawData[j,1],digits=1)
    duration <- rawData[j,2]
    output <- paste0(onset,":",duration)
    stim_file <- gsub(".jpg","",as.character(rawData[j,4]))
    
    if(grepl("n/a",rawData[j,6]) == F){
      typeResp <- paste0(rawData[j,3],rawData[j,6])
    }else{
      typeResp <- paste0(rawData[j,3],"X")
    }
    
    outString <- paste0(typeResp,"_",stim_file)
    outFile <- paste0(outDir,outString,".txt")
    
    if(i == 1){
      cat(output, "\n", file=outFile, append = F)
      cat ("*", "\n", file=outFile, append = T)
    }else{
      cat ("*", "\n", file=outFile, append = F)
      cat(output, "\n", file=outFile, append = T)
    }
  }
}

