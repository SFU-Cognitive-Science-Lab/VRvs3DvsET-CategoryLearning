# Title: Category VR Analyses
#
# Description: Performs some basic descriptive tests and lmers for the Category
# VR experiment
#                 Part 1: Load scripting libraries and load data files
#                 Part 2: Filter Non-Learners and Implement Exclusion Criteria
#                 Part 3: Descriptive Statistics
#                 Part 4: Model Fitting
#                 Part 5: Assumption Checking
#                 Part 6: Graphing
#
# Author: Justin
# Project: Category-VR
# Date Created:
# reviewed: Robin C. A. Barrett
# verified: Cal Woodruff 
# verification notes: 
#  - install doesn't appear to install dependencies 
#  - all vif(...) lines failed with 
#        > vif(fit.accuracy.poly)
#        Error in vif.default(fit.accuracy.poly) : 
#          model contains fewer than 2 terms
#        Calls: vif -> vif.default
#        In addition: Warning message:
#        In vif.default(fit.accuracy.poly) : No intercept: vifs may not be sensible.
#        Execution halted
#
# Last Edit: 
#             2021-02-24
#               - updated analyses to use total accuracy
#             2021-03-14
#               - added comments describing experiment and cleaned up for public release
#             2021-05-30
#               - verification comments
#
# Input: Uses data from accompanying github repo. Running code will bring up UI for you to select where you have saved the data to.
#
# Output: Graphs at the very bottom of the script give a somewhat clean visual
# summary of results. Statistical analyses outputted to console.
#
# Additional Comments:





##### PART 1: Load scripting libraries and load data files ######


# Uncomment the install packages line if you don't have either of these installed
# on ubuntu install the equivalent r-cran-* apt packages to get dependencies
# requires at least R 3.5 - was verified using R 4
#install.packages("lme4")
library(lme4)
#install.packages("dplyr")
library(dplyr)
#install.packages("ggplot2")
library(ggplot2)
#install.packages("car")
library(car)

# Set the directory to wherever you have the Data saved
chosen_dir <- rstudioapi::selectDirectory()
setwd(chosen_dir)

# This is the most current master table file on vault
dat <- read.csv("VR3D_TrialLevelData.csv", na.strings = "NaN")
View(dat)

# This is the eye tracking data from McColemanAncellBair
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

# Verify validity of non-learner classification: mean accuracy of nonlearners should be relatively close to 25%
# (random chance) if they all mostly made selections at random

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
#  This is due to a bug in the experiment data collection (user id's used twice by mistake)


# remove these two participants
learned <- subset(learned, subset = learned$subject != 20122)
learned <- subset(learned, subset = learned$subject != 30122)
# also remove participant 20104 (learned quickly, then gave up or got bored. Insufficient data to perform analysis)
learned <- subset(learned, subset = learned$subject != 20104)







##### Part 3: Descriptive Statistics #####
# NOTE: all assumption checking and model fitting work is down below the analyses

# Basic Descriptives for each variable by group (no binning)
learned %>%
  group_by(condition) %>%
  summarize(accuracy = mean(meanAccuracy, na.rm = T), RT = mean(meanRT, na.rm = T),
            optimization = mean(optimization, na.rm = T), cp = mean(cp, na.rm = T),
  optimization = mean(optimization, na.rm = T), cp = mean(cp, na.rm = T),
  FixDuration = mean(FixDuration, na.rm = T), fixCount = mean(fixCount, na.rm = T))


# Goodness of fit test looking for differences in proportion of learners between VR and 3D Conditions

# subset relevant variables and remove duplicates (so each participant has one row)
chi.subset <- dat[c(1,3,4)]
chi.dat <- distinct(chi.subset, .keep_all = T)

chi <- chisq.test(chi.dat$learner, chi.dat$condition)
chi
# These show the count tables used
chi$observed
chi$expected
# Test is not significant, proportion of learners is to be expected for each condition

# This is a test to determine if the criterion points are reached at significantly different times

# Converge data, so there is just 1 row per participant
short.CPs <- learned %>%
  group_by(subject) %>%
  slice(which.max(cp))

# Since normality assumption of T test was heavily violated,
# I used the non-parametric Mann-Whitney U Test (uses median instead of mean)
wilcox.test(short.CPs$cp[short.CPs$condition == "3D"],short.CPs$cp[short.CPs$condition == "VR"])
wilcox.test(short.CPs$cp[short.CPs$condition == "3D"],short.CPs$cp[short.CPs$condition == "ET"])
wilcox.test(short.CPs$cp[short.CPs$condition == "VR"],short.CPs$cp[short.CPs$condition == "ET"])
# There is no difference in criterion points between VR and 3D, but there is for
# ET (just below cutoff of .05/3=.01667)

# Warning Info:
# because there's less than 50 data per group, the function attempts to compute
# the exact p-value. It runs into trouble with repeated values (ties), so it uses a
# complicated correction. However, removing the correction did not change the outcome



# This section tests if there is a difference in total number of errors between groups
# first take the sum of all errors for each participant
learned.ErrorSums <- learned[c(1,3,6)] %>%
  group_by(subject) %>%
  mutate(sum(errorCount))

# Converge data, so there is just 1 row per participant
short.ErrorSums <- learned.ErrorSums %>%
  group_by(subject) %>%
  slice(which.max(`sum(errorCount)`))

# look at the means for each group
mean(short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "3D"])
mean(short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "VR"])
mean(short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "ET"])

# look at the medians for each group
median(short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "3D"])
median(short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "VR"])
median(short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "ET"])

# Again, use the Mann-Whitney U Test to determine group differences
wilcox.test(short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "3D"],
            short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "VR"])
wilcox.test(short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "3D"],
            short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "ET"])
wilcox.test(short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "VR"],
            short.ErrorSums$`sum(errorCount)`[short.ErrorSums$condition == "ET"])
# There is no difference in total number of errors between group



##### Part 4: Model Fitting ####################################################

# Variables to be considered from manuscript:
  # 1. accuracy
  # 2. RT (phase 2 RT = meanRT, phase 4 RT = meanFBDuration)
  # 3. total experiment time --- get descriptives for this
  # 4. optimization
  # 5. fix duration
  # 6. fix count



## 1. Accuracy

# set up base model
fit.accuracy <- lmer(meanAccuracy ~ bin + (1 | subject), data = learned)
summary(fit.accuracy)

# add quadratic effect
fit.accuracy.poly <- lmer(meanAccuracy ~ poly(bin,2) + (1 | subject), data = learned)
summary(fit.accuracy.poly)

# compare fits
anova(fit.accuracy, fit.accuracy.poly)
# poly effect is significant

# add condition
fit.accuracy.cond <- lmer(meanAccuracy ~ poly(bin,2) + condition + (1 | subject), data = learned)
summary(fit.accuracy.cond)

# compare fits
anova(fit.accuracy.poly, fit.accuracy.cond)
# condition is not significant



## 2. Reaction Time

# set up base model
fit.RT <- lmer(meanRT ~ bin + (1 | subject), data = learned)
summary(fit.RT)

# add quadratic effect
fit.RT.poly <- lmer(meanRT ~ poly(bin,2) + (1 | subject), data = learned)
summary(fit.RT.poly)

# compare fits
anova(fit.RT, fit.RT.poly)
# poly effect is significant

# add condition
fit.RT.cond <- lmer(meanRT ~ poly(bin,2) + condition + (1 | subject), data = learned)
summary(fit.RT.cond)

# compare fits
anova(fit.RT.poly, fit.RT.cond)
# condition is significant
#  ET is much lower than the other two



## 3. Feedback Duration

# set up base model
fit.FB <- lmer(meanFBDuration ~ bin + (1 | subject), data = learned)
summary(fit.FB)

# add quadratic effect
fit.FB.poly <- lmer(meanFBDuration ~ poly(bin,2) + (1 | subject), data = learned)
summary(fit.FB.poly)

# compare fits
anova(fit.FB, fit.FB.poly)
# poly effect is significant

# add condition
fit.FB.cond <- lmer(meanFBDuration ~ poly(bin,2) + condition + (1 | subject), data = learned)
summary(fit.FB.cond)

# compare fits
anova(fit.FB, fit.FB.cond)
# condition is significant
#  ET is lowest, then 3D, then VR



## 4. Optimization

# set up base model
fit.optimization <- lmer(optimization ~ bin + (1 | subject), data = learned)
summary(fit.optimization)

# add quadratic effect
fit.optimization.poly <- lmer(optimization ~ poly(bin,2) + (1 | subject), data = learned)
summary(fit.optimization.poly)

# compare fits
anova(fit.optimization, fit.optimization.poly)
# poly effect is significant

# add condition
fit.optimization.cond <- lmer(optimization ~ poly(bin,2) + condition + (1 | subject), data = learned)
summary(fit.optimization.cond)

# compare fits
anova(fit.optimization.poly, fit.optimization.cond)
# condition is not significant



## 5. Fixation Duration

# set up base model
fit.FixDuration <- lmer(FixDuration ~ bin + (1 | subject), data = learned)
summary(fit.FixDuration)

# add quadratic effect
fit.FixDuration.poly <- lmer(FixDuration ~ poly(bin,2) + (1 | subject), data = learned)
summary(fit.FixDuration.poly)

# compare fits
anova(fit.FixDuration, fit.FixDuration.poly)
# poly effect is significant

# add condition
fit.FixDuration.cond <- lmer(FixDuration ~ poly(bin,2) + condition + (1 | subject), data = learned)
summary(fit.FixDuration.cond)

# compare fits
anova(fit.FixDuration.poly, fit.FixDuration.cond)
# condition is significant
#  ET is much lower than the other 2 groups



## 6. Fixation Count

# set up base model
fit.FixCount <- lmer(fixCount ~ bin + (1 | subject), data = learned)
summary(fit.FixCount)

# add quadratic effect
fit.FixCount.poly <- lmer(fixCount ~ poly(bin,2) + (1 | subject), data = learned)
summary(fit.FixCount.poly)

# compare fits
anova(fit.FixCount, fit.FixCount.poly)
# poly effect is significant

# add condition
fit.FixCount.cond <- lmer(fixCount ~ poly(bin,2) + condition + (1 | subject), data = learned)
summary(fit.FixCount.cond)

# compare fits
anova(fit.FixCount.poly, fit.FixCount.cond)
# condition is significant
#  VR is higher than the other 2 groups




##### Part 5: Assumption Checking ################

## Chi Square 
#   Assumes: independent observations and sample size over 10 for each cell in table)
#   We have independent observations and a large sample size, so no assumptions are violated

## t test
#   Assumes: normality, equal variance

#   Criterion Point:
#   data are very skewed
hist(learned$cp[learned$condition == "3D"])
hist(learned$cp[learned$condition == "VR"])
hist(learned$cp[learned$condition == "ET"])
#   variance is similar in all groups
sd(learned$cp[learned$condition == "3D"])
sd(learned$cp[learned$condition == "VR"])
sd(learned$cp[learned$condition == "ET"])

# Since normality is violated, we can test the median of the groups rather than mean

## Mann-Whitney U Test 
# Assumes: independent groups, groups follow same distribution
# groups are independent and data are skewed in the same direction in both groups, no assumptions violated



## Modelling


# Accuracy

# plot of residuals against fitted values
plot(fit.accuracy.poly)
# heteroscedastic

# index plot of residuals
x <- c(1:length(resid(fit.accuracy.poly)))
y <- c(resid(fit.accuracy.poly))
plot(x, y, ylab = "Residuals", xlab = "Case Number")
abline (0,0)
# independent errors, no autocorrelation

# qq plot of residuals
qqnorm(resid(fit.accuracy.poly))
qqline(resid(fit.accuracy.poly))
# not normal, but lmers are robust to this

# variance inflation factor
vif(fit.accuracy.poly)
# not applicable

# shows any rows in data which residuals are greater than 2.5
res1 <- resid(fit.accuracy.poly, type = "pearson")
learned[which(abs(res1) > 2.5),]
# no extreme outliers



# Reaction Time

# plot of residuals against fitted values
plot(fit.RT.cond)
# heteroscedastic

# index plot of residuals
x <- c(1:length(resid(fit.RT.cond)))
y <- c(resid(fit.RT.cond))
plot(x, y, ylab = "Residuals", xlab = "Case Number")
abline (0,0)
# possible autocorrelation

# qq plot of residuals
qqnorm(resid(fit.RT.cond))
qqline(resid(fit.RT.cond))
# not normal, but lmers are robust to this

# variance inflation factor
vif(fit.RT.cond)
# no multicollinearity

# shows any rows in data which residuals are greater than 2.5
res1 <- resid(fit.RT.cond, type = "pearson")
learned[which(abs(res1) > 2.5),]
# many extreme outliers



# Feedback Duration

# plot of residuals against fitted values
plot(fit.FB.cond)
# heteroscedastic, some extreme outliers

# index plot of residuals
x <- c(1:length(resid(fit.FB.cond)))
y <- c(resid(fit.FB.cond))
plot(x, y, ylab = "Residuals", xlab = "Case Number")
abline (0,0)
# possible autocorrelation

# qq plot of residuals
qqnorm(resid(fit.FB.cond))
qqline(resid(fit.FB.cond))
# not normal, but lmers are robust to this

# variance inflation factor
vif(fit.FB.cond)
# no multicollinearity

# shows any rows in data which residuals are greater than 2.5
res1 <- resid(fit.FB.cond, type = "pearson")
learned[which(abs(res1) > 2.5),]
# many extreme outliers



# Optimization

# plot of residuals against fitted values
plot(fit.optimization.poly)
# possible heteroscedasticity

# index plot of residuals
x <- c(1:length(resid(fit.optimization.poly)))
y <- c(resid(fit.optimization.poly))
plot(x, y, ylab = "Residuals", xlab = "Case Number")
abline (0,0)
# possible autocorrelation

# qq plot of residuals
qqnorm(resid(fit.optimization.poly))
qqline(resid(fit.optimization.poly))
# moderate stray from normality

# variance inflation factor
vif(fit.optimization.poly)
# NA

# shows any rows in data which residuals are greater than 2.5
res1 <- resid(fit.optimization.poly, type = "pearson")
learned[which(abs(res1) > 2.5),]
# no extreme outliers



# Fixation Duration

# plot of residuals against fitted values
plot(fit.FixDuration.cond)
# slightly heteroscedastic

# index plot of residuals
x <- c(1:length(resid(fit.FixDuration.cond)))
y <- c(resid(fit.FixDuration.cond))
plot(x, y, ylab = "Residuals", xlab = "Case Number")
abline (0,0)
# independent, no autocorrelation

# qq plot of residuals
qqnorm(resid(fit.FixDuration.cond))
qqline(resid(fit.FixDuration.cond))
# not normal, but lmers are robust to this

# variance inflation factor
vif(fit.FixDuration.cond)
# no multicollinearity

# shows any rows in data which residuals are greater than 2.5
res1 <- resid(fit.FixDuration.cond, type = "pearson")
learned[which(abs(res1) > 2.5),]
# data are very scattered, lots of variance, but no other extreme outliers



# Fixation Count

# plot of residuals against fitted values
plot(fit.FixCount.cond)
# slightly heteroscedastic, possible outliers

# index plot of residuals
x <- c(1:length(resid(fit.FixCount.cond)))
y <- c(resid(fit.FixCount.cond))
plot(x, y, ylab = "Residuals", xlab = "Case Number")
abline (0,0)
# possible autocorrelation

# qq plot of residuals
qqnorm(resid(fit.FixCount.cond))
qqline(resid(fit.FixCount.cond))
# moderate stray from normality

# variance inflation factor
vif(fit.FixCount.cond)
# no multicollinearity

# shows any rows in data which residuals are greater than 2.5
res1 <- resid(fit.FixCount.cond, type = "pearson")
learned[which(abs(res1) > 2.5),]
# data are very scattered, lots of variance, but no other extreme outliers





##### Part 6: Graphing #####

# this is a boxplot of each condition across bins
# Accuracy
ggplot(learned, aes(bin, meanAccuracy)) +
  geom_boxplot(mapping = aes(as.factor(bin), meanAccuracy, color = condition))

# Reaction Time
ggplot(learned, aes(bin, meanRT)) +
  geom_boxplot(mapping = aes(as.factor(bin), meanRT, color = condition))

# Feedback Duration
ggplot(learned, aes(bin, meanFBDuration)) +
  geom_boxplot(mapping = aes(as.factor(bin), meanFBDuration, color = condition))

# Optimization
ggplot(learned, aes(bin, optimization)) +
  geom_boxplot(mapping = aes(as.factor(bin), optimization, color = condition))

# Fixation Duration
ggplot(learned, aes(bin, FixDuration)) +
  geom_boxplot(mapping = aes(as.factor(bin), FixDuration, color = condition))

# Fixation Count
ggplot(learned, aes(bin, fixCount)) +
  geom_boxplot(mapping = aes(as.factor(bin), fixCount, color = condition))



















