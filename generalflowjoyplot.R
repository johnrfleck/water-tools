# John Fleck
# University of New Mexico Water Resources Program
# based on code by Lauren Steely, @MadreDeZanjas
#   https://github.com/codeswitching/Reservoir-inflow-analysis/tree/master

# Create joyplot of daily discharge for an arbitrary USGS stream gauge
# uses USGS dataRetrieval package
# tutorial for data retrieval package here: https://owi.usgs.gov/R/dataRetrieval.html#1

library(dataRetrieval) # USGS data retrieval package
library(tidyverse) # data tidying toolkit
library(lubridate) # for date handling
library(cowplot) # for prettying the pictures
library(ggjoy) # create joyplots 
               # https://cran.r-project.org/web/packages/ggjoy/vignettes/introduction.html

# prompt user for gauge number
siteNo <- readline(prompt="Enter a gauge number: ")

# get station name for later display purposes
sta_meta <- readNWISsite(siteNo)

# reality check
print(sta_meta$station_nm)

# reasonable start date - this is the date of the first gauge record, at Embudo, NM
startDate <- "1895-02-01"
endDate <- Sys.Date()

# statistics of interest - this is mean daily discharge
pCode <- "00060"
statCd <- "00003"

# retrieve data
gauge <- readNWISdv(siteNo, pCode, startDate, endDate,
           statCd)


# convert it to a tibble
gaugetb <- as_tibble(gauge)

# create variable for the year and day of the year
gaugetb$year <- year(gaugetb$Date)
gaugetb$yday <- yday(gaugetb$Date)

# remove 2017, not sure why this was screwing things up
gaugetb <- filter(gaugetb, year<2017)

#create joyplot
p <- ggplot(gaugetb, aes(yday, -year, height = X_00060_00003, group=as.factor(year), fill=as.factor(year))) +
  geom_joy(stat="identity", scale=3, size=0.1) +
  theme(legend.position="none") +
  ggtitle(sta_meta$station_nm) +
  ylab("flow") +
  xlab("day of the year")


print(p)

