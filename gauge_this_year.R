# graph this year's flow on a river compared to historic record
# Uses USGS's excelelent dataRetrieval package
# tutorial here: https://owi.usgs.gov/R/dataRetrieval.html#1
# Albuquerque gauge to use as example: 08330000

library(dataRetrieval)
library(tidyverse)
library(lubridate)

#get gauge number
siteNo <- readline(prompt="Enter a gauge number: ")

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
gauge_daily <- filter(gauge_daily, flow>0)

# get today's yday

today <- yday(Sys.time())


gauge_daily$yday <- yday(gauge_daily$Date)

#filter up to one day after today's date

gauge_daily <- filter(gauge_daily, yday < (today+1))

this_year <- filter(gauge_daily, year==2018)

ggplot(data=gauge_daily, aes(x=yday, y=flow+1, group=year)) + 
  geom_path(alpha=0.1) +
  geom_path(data=this_year, aes(x=yday, y=flow+1, colour="blue"), show.legend=F, size=1) +
  labs(title=gauge_meta$station_nm,
       x = "day of the year",
       y = "flow, cubic feet per second",
       caption = "Data: USGS\ngraph: University of New Mexico Water Resources Program") +
  theme(strip.text = element_text(face = "bold", size = 8))
  
