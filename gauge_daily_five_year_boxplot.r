# box plot of daily flows at selected gauges, in five year bins
# Uses USGS dataRetrieval package
# tutorial here: https://owi.usgs.gov/R/dataRetrieval.html#1
# Albuquerque gauge to use as example: 08330000
# uses log scale - easier to visualize given variability, particularly
# at low end

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
startdate <- paste("Distribution of daily flows, USGS gauge", 
                   gauge_meta$site_no, 
                   "\nData series start date: ", 
                   gauge_daily$Date[1])

gauge_daily$fiveyr <- floor((gauge_daily$year/5))*5



ggplot(data=gauge_daily, aes(x=yday)) + 
  geom_boxplot(mapping = aes(x=factor(fiveyr), y=flow)) +
      scale_y_log10() +
      labs(title=gauge_meta$station_nm,
       x = "day of the year",
       y = "flow, cubic feet per second, log scale",
       caption = "Data: USGS\ngraph: University of New Mexico Water Resources Program",
       subtitle=startdate) +
  theme(strip.text = element_text(face = "bold", size = 8))
  #scale_y_log10()
