
library("lmerTest")
library("dplyr")
library("ggoutlier")
library("ggplot2")
library("sjPlot")


### Set up
# read in data
dataDir <- getwd()
outDir <- dataDir

data_raw <- read.delim(paste0(dataDir, "/TrialBetas.txt"), sep = "")
data_pars <- read.delim(paste0(dataDir, "/EMU_pars.csv"), sep = ",")

# get oriented
ind_sub_stim <- which(data_raw$Type == "StimResp_Image")
num_sub <- as.numeric(length(ind_sub_stim))
num_trials <- as.numeric(dim(data_raw)[2] - 2)

# Set function
GetNames <- function(string) {
  h_stim <- substr(string, 1, 1)
  h_resp <- substr(string, 2, 2)
  h_out_mat <- matrix(NA, nrow = 1, ncol = 2)
  h_c <- 1
  for (x in c(h_stim, h_resp)) {
    if (x == 1) {
      h_out_mat[1, h_c] <- "Neg"
    } else if (x == 2) {
      h_out_mat[1, h_c] <- "Neu"
    } else if (x == 3) {
      h_out_mat[1, h_c] <- "Pos"
    } else {
      h_out_mat[1, h_c] <- "NR"
    }
    h_c <- h_c + 1
  }
  return(h_out_mat)
}


### Make data frames
# split Stim, Resp, and Image string
data_split <- as.data.frame(matrix(NA, nrow = 2 * dim(data_raw)[1], ncol = dim(data_raw)[2]))
colnames(data_split) <- colnames(data_raw)

c <- 1
for (i in ind_sub_stim) {
  h_start <- c
  h_int1 <- c + 1
  h_int2 <- c + 2
  h_end <- c + 3

  data_split[h_start:h_end, 1] <- rep(data_raw[i, 1], 4)
  data_split[h_start, 2] <- "Image"
  data_split[h_int1, 2] <- "Stim"
  data_split[h_int2, 2] <- "Resp"
  data_split[h_end, 2] <- "Est"

  for (j in 3:dim(data_raw)[2]) {
    h_stim <- data_raw[i, j]
    img <- gsub(".*_", "", h_stim)
    h_sr <- gsub("_.*", "", h_stim)
    sr <- GetNames(h_sr)
    est <- data_raw[i + 1, j]

    data_split[h_start, j] <- img
    data_split[h_int1, j] <- sr[1]
    data_split[h_int2, j] <- sr[2]
    data_split[h_end, j] <- as.numeric(est)
  }
  c <- h_end + 1
}

# add Pars info
data_split$Pars <- NA
for (i in 1:dim(data_split)[1]) {
  subj <- gsub(".*-", "", data_split[i, 1])
  ind_subj <- grepl(subj, data_pars$Participant.ID)
  data_split$Pars[i] <- data_pars[ind_subj, 3]
}

# move to long form
data_long <- as.data.frame(matrix(NA, nrow = num_sub * num_trials, ncol = 7))
colnames(data_long) <- c("Subj", "Pars", "Image", "Stim", "Resp", "Beh", "Est")

h_ind_sub <- which(data_split$Type == "Image")
h_start <- 1
for (i in h_ind_sub) {
  h_end <- h_start + num_trials - 1
  data_long[h_start:h_end, 1] <- data_split[i, 1]
  data_long[h_start:h_end, 2] <- data_split$Pars[i]
  data_long[h_start:h_end, 3] <- as.character(data_split[i, 3:(dim(data_split)[2] - 1)])
  data_long[h_start:h_end, 4] <- as.character(data_split[i + 1, 3:(dim(data_split)[2] - 1)])
  data_long[h_start:h_end, 5] <- as.character(data_split[i + 2, 3:(dim(data_split)[2] - 1)])
  data_long[h_start:h_end, 7] <- as.numeric(data_split[i + 3, 3:(dim(data_split)[2] - 1)])
  h_start <- h_end + 1
}

# Add behavior (Hit, Miss)
for (i in 1:dim(data_long)[1]) {
  if (data_long$Stim[i] == data_long$Resp[i]) {
    data_long$Beh[i] <- "Hit"
  } else {
    data_long$Beh[i] <- "Miss"
  }
}

# remove non-responses
ind_nr <- grep("NR", data_long$Resp)
data_long <- data_long[-ind_nr, ]

# add Stim-Beh col
data_long$StimBeh <- NA
data_long$StimBeh <- paste0(data_long$Stim, "-", data_long$Beh)
write.csv(data_long,file=paste0(outDir,"/data_long.csv"),sep = ",")


### Stats
# all data
ggoutlier_hist(data_long, "Est", -2, 2)
stat_lme <- lmer(Est ~ StimBeh + Pars + (1 | Image) + (Pars | Subj), data_long[data_long$Est < 2 & data_long$Est > -2, ])
summary(stat_lme)
sjPlot::plot_model(stat_lme, type="re", terms = c("Neg-Hit", "Neg-Miss"))




