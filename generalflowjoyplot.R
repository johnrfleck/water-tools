# general flow
# tutorial here: https://owi.usgs.gov/R/dataRetrieval.html#1

library(dataRetrieval)
library(tidyverse)
library(lubridate)
library(cowplot)
library(ggjoy)

#get gauge number

siteNo <- readline(prompt="Enter a gauge number: ")

# parameters for USGS API

sta_meta <- readNWISsite(siteNo)

print(sta_meta$station_nm)

# reasonable start date
startDate <- "1895-02-01"
endDate <- Sys.Date()

# statistics of interest - this is mean daily discharge
pCode <- "00060"
statCd <- "00003"

# retrieve data
gauge <- readNWISdv(siteNo, pCode, startDate, endDate,
           statCd)



gaugetb <- as_tibble(gauge)



gaugetb$year <- year(gaugetb$Date)
gaugetb$yday <- yday(gaugetb$Date)

# remove 2017, not sure why this was screwing things up
#gaugetb <- filter(gaugetb, year<2017)

#create joyplot
p <- ggplot(gaugetb, aes(yday, -year, height = X_00060_00003, group=as.factor(year), fill=as.factor(year))) +
  geom_joy(stat="identity", scale=3, size=0.1) +
  theme(legend.position="none") +
  ggtitle(sta_meta$station_nm) +
  ylab("flow") +
  xlab("day of the year")


print(p)

