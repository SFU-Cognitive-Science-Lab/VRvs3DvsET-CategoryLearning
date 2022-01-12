# Title: Category VR Analyses
#
# Description: Recreates graphs from vrAnalysis.R and formats them based on 
#   PLOSOne guidelines
#                 Part 1: Load scripting libraries and load data files
#                 Part 2: Filter Non-Learners and Implement Exclusion Criteria
#                 Part 3: Format Data
#                 Part 4: Graphing
#                 Part 5: Export Graphs
#                 
#
# Author: Justin
# Project: Category-VR
# Date Created: 2021-03-24
# reviewed:
# verified:
#
# Last Edit: 
#             
#
# Input: Uses data from accompanying github repo. Running code will bring up UI for you to select where you have saved the data to.
#
# Output: Graphs at the very bottom of the script give a somewhat clean visual
# summary of results
#
# Additional Comments: Parts 1 and 2 are taken directly from vrAnalysis.R,
#   only parts 3 and 4 are different





##### PART 1: Load scripting libraries and load data files #####


# Uncomment the install packages line if you don't have either of these installed
#install.packages("ggplot2")
library(ggplot2)
#install.packages("extrafont")
library(extrafont)
#install.packages("plyr")
library(plyr)
#install.packages("gridExtra")
library(gridExtra)




# import fonts so that we can specify font type when saving plots
### CAUTION: this can take a few minutes to run
# only needs to be run once on each computer that uses this script
font_import()
y
loadfonts(device = "postscript")

# Set the directory to wherever you have the file installed
chosen_dir <- rstudioapi::selectDirectory()
setwd(chosen_dir)
# This is the most current master table file on vault
dat <- read.csv("VR3D_TrialLevelData.csv", na.strings = "NaN")
View(dat)

# This is the eye tracking data from sshrc
ET <- read.csv("McColemanAncellBlair2011_ControlGroup_TrialLevelData.csv", na.strings = "NaN")
# exclude bins 11-15
shortenedET <- subset(ET, ET$bin < 11)
# cut out learners that hit cp after bin 10 (bin size = 24 trials)
shortened.cp.ET <- subset(shortenedET, shortenedET$cp < 241)
# cut out the irrelevant fixation column (not used in VR or 3D)
shortened.cp.ET <- shortened.cp.ET[-13]
# set the column names to be equal
names(shortened.cp.ET) <- names(dat)



##### Part 2: Filter Non-Learners and Implement Exclusion Criteria #####


# Create a new dataset with just learners
# this goes off the criterion point, but seems to do a decent job of excluding
# participants which randomly selected options for at least part of the experiment
learned.dat <- subset(dat, subset = dat$learner == 1)
learned.ET <- subset(shortened.cp.ET, subset = shortened.cp.ET$learner == 1)

# Verify validity of non-learner classification: mean accuracy of nonlearners
# should be relatively close to 25% (random chance) if they all mostly made
# selections at random

mean(dat$meanAccuracy[dat$learner==0], na.rm=T)
# finds mean accuracy of nonlearners to be 32.87%

mean(ET$meanAccuracy[ET$learner==0], na.rm=T)
# finds mean accuracy of nonleaners to be 33.06%


# combine learned.dat and learned.ET
learned <- rbind(learned.dat, learned.ET)


# Check which participants have negative FB and RT values
problem.dat.FB <- learned[learned$meanFBDuration<0,]
View(problem.dat.FB)

problem.dat.RT <- learned[learned$meanRT<0,]
View(problem.dat.RT)

# Participants 20122 and 30122 both have negative values, but are still learners
#  This is due to a bug in the experiment? I couldn't find their info in the running notes


# remove these two participants
learned <- subset(learned, subset = learned$subject != 20122)
learned <- subset(learned, subset = learned$subject != 30122)
# also remove participant 20104 (learned quickly, then gave up or got bored)
learned <- subset(learned, subset = learned$subject != 20104)

# capitalize condition so it doesn't have to get adjusted in the plots
learned$Condition <- learned$condition

# remove empty rows
learned <- subset(learned, subset = learned$fixCount != 0)





##### Part 3: Format Data #####



## create function that aggregates data to give means and standard errors
## grouped by specified variables. This was pulled from
## http://www.cookbook-r.com/Graphs/Plotting_means_and_error_bars_(ggplot2)/

# Gives count, mean, standard deviation, standard error of the mean, and
# confidence interval (default 95%).
# data: a data frame.
# measurevar: the name of a column that contains the variable to be summariezed
# groupvars: a vector containing names of columns that contain grouping variables
# na.rm: a boolean that indicates whether to ignore NA's
# conf.interval: the percent range of the confidence interval (default is 95%)
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
  library(plyr)
  
  # New version of length which can handle NA's: if na.rm==T, don't count them
  length2 <- function (x, na.rm=FALSE) {
    if (na.rm) sum(!is.na(x))
    else       length(x)
  }
  
  # This does the summary. For each group's data frame, return a vector with
  # N, mean, and sd
  datac <- ddply(data, groupvars, .drop=.drop,
                 .fun = function(xx, col) {
                   c(N    = length2(xx[[col]], na.rm=na.rm),
                     mean = mean   (xx[[col]], na.rm=na.rm),
                     sd   = sd     (xx[[col]], na.rm=na.rm)
                   )
                 },
                 measurevar
  )
  
  # Rename the "mean" column    
  datac <- rename(datac, c("mean" = measurevar))
  
  datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean
  
  # Confidence interval multiplier for standard error
  # Calculate t-statistic for confidence interval: 
  # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
  ciMult <- qt(conf.interval/2 + .5, datac$N-1)
  datac$ci <- datac$se * ciMult
  
  return(datac)
}



# run the above function for each of the variables of interest
dat.Accuracy <- summarySE(learned, measurevar = 'meanAccuracy',
  groupvars = c('bin', 'Condition'))

dat.RT <- summarySE(learned, measurevar = 'meanRT',
  groupvars = c('bin', 'Condition'))

dat.FB <- summarySE(learned, measurevar = 'meanFBDuration',
  groupvars = c('bin', 'Condition'))

dat.Optimization <- summarySE(learned, measurevar = 'optimization',
  groupvars = c('bin', 'Condition'))

dat.FixDuration <- summarySE(learned, measurevar = 'FixDuration',
  groupvars = c('bin', 'Condition'))

dat.FixCount <- summarySE(learned, measurevar = 'fixCount',
  groupvars = c('bin', 'Condition'))




##### Part 4: Graphing #####


# check names of system fonts
#windowsFonts()

# color blind safe options
colours1 <- c('#66c2a5', '#fc8d62', '#8da0cb')
colours2 <- c('#1b9e77', '#d95f02', '#7570b3')
colours3 <- c('#a6cee3', '#1f78b4', '#b2df8a')



## plot means of each variable by bin, then format according to Plos One guidelines.
## Error region is dictated by 95% CI of the mean

# Accuracy
Acc.Line <- ggplot(dat.Accuracy, aes(x=bin, y=meanAccuracy, color = Condition)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=meanAccuracy-ci, ymax=meanAccuracy+ci,
    fill = Condition), alpha = .2, linetype=0)+
  labs(x='Bin (24 Trials)', y='Accuracy')+
  theme_classic()+
  scale_colour_manual(values = colours2)+
  scale_fill_manual(values = colours2)+
  scale_x_continuous(breaks = c(1:10), limits = c(1,10))+
  ggtitle('A')+
  theme(title = element_text(size=unit(16, 'points'), family='Arial', color='black'))+
  theme(axis.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(axis.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(plot.margin = unit(c(2,2,2,2), 'points'))


# Reaction Time
RT.Line <- ggplot(dat.RT, aes(x=bin, y=meanRT, color = Condition)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=meanRT-ci, ymax=meanRT+ci,
    fill = Condition), alpha = .2, linetype=0)+
  labs(x='Bin (24 Trials)', y='Response Time (ms)')+
  theme_classic()+
  scale_colour_manual(values = colours2)+
  scale_fill_manual(values = colours2)+
  scale_x_continuous(breaks = c(1:10), limits = c(1,10))+
  ggtitle('A')+
  theme(title = element_text(size=unit(16, 'points'), family='Arial', color='black'))+
  theme(axis.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(axis.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(plot.margin = unit(c(2,2,2,2), 'points'))


# Feedback Duration
FB.Line <- ggplot(dat.FB, aes(x=bin, y=meanFBDuration, color = Condition)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=meanFBDuration-ci, ymax=meanFBDuration+ci,
    fill = Condition), alpha = .2, linetype=0)+
  labs(x='Bin (24 Trials)', y='Feedback Duration (ms)')+
  theme_classic()+
  scale_colour_manual(values = colours2)+
  scale_fill_manual(values = colours2)+
  scale_x_continuous(breaks = c(1:10), limits = c(1,10))+
  ggtitle('B')+
  theme(title = element_text(size=unit(16, 'points'), family='Arial', color='black'))+
  theme(axis.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(axis.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(plot.margin = unit(c(2,2,2,2), 'points'))


# Optimization
Opt.Line <- ggplot(dat.Optimization, aes(x=bin, y=optimization, color = Condition)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=optimization-ci, ymax=optimization+ci,
    fill = Condition), alpha = .2, linetype=0)+
  labs(x='Bin (24 Trials)', y='Optimization')+
  theme_classic()+
  scale_colour_manual(values = colours2)+
  scale_fill_manual(values = colours2)+
  scale_x_continuous(breaks = c(1:10), limits = c(1,10))+
  ggtitle('B')+
  theme(title = element_text(size=unit(16, 'points'), family='Arial', color='black'))+
  theme(axis.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(axis.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(plot.margin = unit(c(2,2,2,2), 'points'))


# Fixation Duration
FixDuration.Line <- ggplot(dat.FixDuration, aes(x=bin, y=FixDuration, color = Condition)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=FixDuration-ci, ymax=FixDuration+ci,
    fill = Condition), alpha = .2, linetype=0)+
  labs(x='Bin (24 Trials)', y='Fixation Duration (ms)')+
  theme_classic()+
  scale_colour_manual(values = colours2)+
  scale_fill_manual(values = colours2)+
  scale_x_continuous(breaks = c(1:10), limits = c(1,10))+
  ggtitle('B')+
  theme(title = element_text(size=unit(16, 'points'), family='Arial', color='black'))+
  theme(axis.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(axis.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(plot.margin = unit(c(2,2,2,2), 'points'))


# Fixation Count
FixCount.Line <- ggplot(dat.FixCount, aes(x=bin, y=fixCount, color = Condition)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=fixCount-ci, ymax=fixCount+ci,
    fill = Condition), alpha = .2, linetype=0)+
  labs(x='Bin (24 Trials)', y='Fixation Count')+
  theme_classic()+
  scale_colour_manual(values = colours2)+
  scale_fill_manual(values = colours2)+
  scale_x_continuous(breaks = c(1:10), limits = c(1,10))+
  ggtitle('A')+
  theme(title = element_text(size=unit(16, 'points'), family='Arial', color='black'))+
  theme(axis.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.title = element_text(size=unit(12, 'points'), family='Arial', color='black'))+
  theme(legend.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(axis.text = element_text(size=unit(10, 'points'), family='Arial', color='black'))+
  theme(plot.margin = unit(c(2,2,2,2), 'points'))





##### Part 5: Export Graphs #####

### Export everything to high res pngs, then use image editor to convert to eps
chosen_dir <- rstudioapi::selectDirectory()
setwd(chosen_dir)



# Fig4
png('Fig4.png', width = 7.5, height = 3.5, units = 'in', res = 600)
print(grid.arrange(Acc.Line, Opt.Line, ncol=2))
dev.off()

# Fig5
png('Fig5.png', width = 7.5, height = 3.5, units = 'in', res = 600)
grid.arrange(RT.Line, FB.Line, ncol=2)
dev.off()

# Fig6
png('Fig6.png', width = 7.5, height = 3.5, units = 'in', res = 600)
grid.arrange(FixCount.Line, FixDuration.Line, ncol=2)
dev.off()








## This was the old code to export plots. Instead use the above code
# # Accuracy
# png('vrPlotAccuracy.png', width = 5, height = 3.5, units = 'in', res = 600)
# print(Acc.Line)
# dev.off()
# 
# # Reaction Time
# png('vrPlotRT.png', width = 5, height = 3.5, units = 'in', res = 600)
# print(RT.Line)
# dev.off()
# 
# # Feedback Duration
# png('vrPlotFB.png', width = 5, height = 3.5, units = 'in', res = 600)
# print(FB.Line)
# dev.off()
# 
# # Optimization
# png('vrPlotOptimization.png', width = 5, height = 3.5, units = 'in', res = 600)
# print(Opt.Line)
# dev.off()
# 
# # Fixation Duration
# png('vrPlotFixDuration.png', width = 5, height = 3.5, units = 'in', res = 600)
# print(FixDuration.Line)
# dev.off()
# 
# # Fixation Count
# png('vrPlotFixCount.png', width = 5, height = 3.5, units = 'in', res = 600)
# print(FixCount.Line)
# dev.off()






































