# annual peak flow on a river
# Uses USGS's excelelent dataRetrieval package
# tutorial here: https://owi.usgs.gov/R/dataRetrieval.html#1
# Albuquerque gauge to use as example: 08330000
# uses log scale - easier to visualize given variability

library(dataRetrieval)
library(tidyverse)
library(lubridate)

#get gauge number
siteNo <- readline(prompt="Enter a gauge number: ")

# get station metadata
gauge_meta <- readNWISsite(siteNo)

startdate <- paste("Peak flows\nUSGS gauge ",
                   gauge_meta$site_no,
                   "\nData series start date: ",
                   gauge_daily$Date[1])

# reasonable start date
startDate <- "1895-02-01"
endDate <- Sys.Date()

# retrieve data
peak <- as_tibble(peak <- readNWISpeak(siteNo, startDate, endDate))

ggplot(peak, aes(peak_dt)) +
  theme_bw() +
  geom_point(data=peak, aes(x=peak_dt, y=peak_va)) +
  guides(fill=guide_legend(title=NULL)) +
  guides(colour=guide_legend(title=NULL)) +
  labs(title=gauge_meta$station_nm,
       x = "Date",
       y = "peak, cubic feet per second",
       caption = "Data: USGS\ngraph: University of New Mexico Water Resources Program\n
       code: https://github.com/johnrfleck/water-tools",
       subtitle=startdate)
theme(strip.text = element_text(face = "bold", size = 8))
