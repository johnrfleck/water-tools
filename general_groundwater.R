# get, plot general groundwater data
# tutorial here: https://owi.usgs.gov/R/dataRetrieval.html#1

library(dataRetrieval)
library(tidyverse)

# parameters for USGS API

#get gauge number
siteNo <- readline(prompt="Enter a gauge number: ")

#get station metadata
sta_meta <- readNWISsite(siteNo)

# parameters for USGS API

# reasonable start date
startDate <- "1970-10-01"
endDate <- Sys.Date()

# statistics of interest - this is groundwater level
pCode <- "72019"
statCd <- "00002"

# retrieve data
gw <- as_tibble(readNWISdv(siteNo, pCode, startDate, endDate,
           statCd))

#create plot


p <- ggplot(gw, aes(x=Date, y=(X_72019_00002*(-1)))) +
  geom_line(alpha=0.3) +
  stat_smooth(method="loess", se="false", span=0.2) +
  ylab("depth below surface") +
  ggtitle(sta_meta$station_nm)



print(p)

