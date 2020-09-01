
library("lmerTest")
library("dplyr")


dataDir <- getwd()
outDir <- dataDir


data_raw <- read.delim(paste0(dataDir,"/TrialBetas.txt"), sep = " ")

ind_sub_stim <- which(data_raw$Type == "StimResp_Image")
num_sub <- as.numeric(length(ind_sub_stim))
num_trials <- as.numeric(dim(data_raw)[2]-2)


# split StimResp from Image string
data_split <- as.data.frame(matrix(NA,nrow = dim(data_raw)[1]+0.5*dim(data_raw)[1], ncol = dim(data_raw)[2]))
colnames(data_split) <- colnames(data_raw)

c <- 1
for(i in ind_sub_stim){
  
  h_start <- c; h_int <- c+1; h_end <- c+2
  
  data_split[h_start:h_end,1] <- rep(data_raw[i,1],3)
  data_split[h_start,2] <- "Image"
  data_split[h_int,2] <- "StimResp"
  data_split[h_end,2] <- "Est"
  
  for(j in 3:dim(data_raw)[2]){
    
    h_stim <- data_raw[i,j]
    stim <- gsub(".*_","",h_stim)
    resp <- gsub("_.*","",h_stim)
    est <- data_raw[i+1,j]
    
    data_split[h_start,j] <- stim
    data_split[h_int,j] <- resp
    data_split[h_end,j] <- as.numeric(est)
  }
  c <- h_end+1
}


# move to long form
data_long <- as.data.frame(matrix(NA, nrow=num_sub*num_trials, ncol=5))
colnames(data_long) <- c("Subj","Group","Image","StimResp","Est")

h_ind_sub <- which(data_split$Type == "Image")
h_start <- 1
for( i in h_ind_sub){
 h_end <- h_start+num_trials-1
 data_long[h_start:h_end,1] <- data_split[i,1]
 data_long[h_start:h_end,2] <- "hold"
 data_long[h_start:h_end,3] <- as.character(data_split[i,3:dim(data_split)[2]])
 data_long[h_start:h_end,4] <- as.character(data_split[i+1,3:dim(data_split)[2]])
 data_long[h_start:h_end,5] <- as.numeric(data_split[i+2,3:dim(data_split)[2]])
 h_start <- h_end+1
}


# test - what should be the formula?
data_neg <- filter(data_long, StimResp == "11" | StimResp == "12" | StimResp == "13")
data_neg$Est <- round(data_neg$Est, 4)

hist(data_neg$Est[data_neg$Est<2 & data_neg$Est>-2])
#stat_neg <- lmer(Est ~ StimResp + (StimResp | Image), data_neg)
stat_neg <- lmer(Est ~ StimResp + (1 | Image) + (1|Subj), data_neg[data_neg$Est<2 & data_neg$Est>-2,])
fixef(stat_neg)
summary(stat_neg)
ranef(stat_neg)

hist(ranef(stat_neg)$Image[,1])
hist(ranef(stat_neg)$Subj[,1])


# # example
# data("sleepstudy", package="lme4")
# m <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
# class(m)







