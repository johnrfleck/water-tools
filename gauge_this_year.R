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
  select(Date, flow, site_no) %>%
  mutate(year=year(Date))

#check to remove spurious negative number that showed up that one time
#gauge_daily <- filter(gauge_daily, flow>0)

# get today's yday

today <- yday(Sys.time())


gauge_daily$yday <- yday(gauge_daily$Date)
startdate <- paste("Daily flows\nUSGS gauge ",
                   gauge_meta$site_no,
                   "\nData series start date: ",
                   gauge_daily$Date[1])

this_year <- filter(gauge_daily, year==2022)
last_year <- filter(gauge_daily, year==2021)
last_year$newflow <- last_year$flow

by_day <- group_by(gauge_daily, yday)
gauge_summary <- summarize(by_day, 
                           mx = max(flow, na.rm = TRUE),
                           mn = min(flow, na.rm = TRUE), 
      
                           p90=quantile(flow, .9, na.rm = TRUE),
                           p70=quantile(flow, .7, na.rm = TRUE),
                           p30=quantile(flow, .3, na.rm = TRUE),
                           p10=quantile(flow, .1, na.rm = TRUE),
                           md=median(flow, na.rm = TRUE))
p <- ggplot(gauge_summary, aes(yday)) +
  theme_bw() +
  geom_ribbon(aes(ymin=mn, ymax=mx, fill="min to max"))+
  geom_ribbon(aes(ymin=p10, ymax=p90, fill="10th to 90th percentile")) +
  geom_ribbon(aes(ymin=p30, ymax=p70, fill="30th to 70th percentile")) +
  geom_path(aes(x=yday, y=md, color="median"), linetype = 2) +
  geom_path(data=this_year, aes(x=yday, y=flow+1, color="2022")) +
  geom_path(data=last_year, aes(x=yday, y=newflow+1, color="2021")) +
  scale_colour_manual(values=c("black","red","darkgrey"))+
  scale_fill_manual(values=c("lightblue","lightgreen","lightgray")) +
  guides(fill=guide_legend(title=NULL)) +
  guides(colour=guide_legend(title=NULL)) +
  scale_y_log10() +
  labs(title=gauge_meta$station_nm,
       x = "day of the year",
       y = "flow, cubic feet per second",
       caption = "Data: USGS\ngraph: Utton Center, University of New Mexico\ncode: https://github.com/johnrfleck/water-tools",
       subtitle=startdate)
  theme(strip.text = element_text(face = "bold", size = 8))
  
  print(p)
  
