# For drought analysis, determines the number of days in each year
# of the historic record in which flow at a USGS river gauge
# fell below an arbitrary threshold.
# Uses USGS's excelelent dataRetrieval package
# tutorial here: https://owi.usgs.gov/R/dataRetrieval.html#1
# Albuquerque gauge to use as example: 08330000

# graph this year's flow on a river compared to historic record
# Uses USGS's excelelent dataRetrieval package
# tutorial here: https://owi.usgs.gov/R/dataRetrieval.html#1
# Albuquerque gauge to use as example: 08330000

library(dataRetrieval)
library(tidyverse)
library(lubridate)

#get gauge number
siteNo <- readline(prompt="Enter a gauge number: ")

#get threshold
threshold <- as.numeric(readline(prompt="Enter desired threshold: "))

# get station metadata
gauge_meta <- readNWISsite(siteNo)

# reasonable start date
startDate <- "1895-02-01"
endDate <- Sys.Date()

# statistics of interest - this is mean daily discharge
pCode <- "00060"
statCd <- "00003"

# retrieve data
gauge <- as_tibble(gauge <- readNWISdv(siteNo, pCode, startDate, endDate,
                                       statCd))
# use pipes to rename flow variable, select ones we need, and
# add the year
gauge_daily <- gauge %>%
  rename(flow = X_00060_00003) %>%
  select(Date, flow) %>%
  mutate(year=year(Date))

#check to remove spurious negative number that showed up that one time
gauge_daily <- filter(gauge_daily, flow>-1)


tograph <- count(gauge_daily, year, flow<=threshold)
tograph <- filter(tograph, tograph$`flow <= threshold` == TRUE)

# plot
ggplot(data=tograph, aes(x=year, y=n)) + 
  xlim(min(gauge_daily$year),max(gauge_daily$year)) +
  geom_bar(stat="identity") + 
  labs(title=paste("Days with flow", threshold, "cfs or less"),
       subtitle=gauge_meta$station_nm, 
       x="year", 
       y="number of days", 
       caption="Data: USGS\ngraph: John Fleck, University of New Mexico Water Resources Program")
