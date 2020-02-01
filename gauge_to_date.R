# total flow to date at specified gauge compared to historial record
# tutorial here: https://owi.usgs.gov/R/dataRetrieval.html#1


library(dataRetrieval)
library(tidyverse)
library(lubridate)

#get gauge number
siteNo <- readline(prompt="Enter a gauge number: ")

#siteNo <- "08330000"

# get station metadata
gauge_meta <- readNWISsite(siteNo)


# reasonable start date
startDate <- "1895-02-01"
endDate <- Sys.Date()

todays_yday <- yday(Sys.Date())

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
  mutate(year=year(Date)) %>%
  mutate(yd=yday(Date)) %>%
  filter(yd < todays_yday)

# text for graphic
startdate <- paste("flow to date\nUSGS gauge",
                   gauge_meta$site_no,
                   "\nData series start date: ",
                   gauge_daily$Date[1])

# create annual average flows
# the *1.98347 part converts cfs to af per day, times today's_yday-1
gauge_annual <- summarize(group_by(gauge_daily, year), annual_flow=mean(flow)*1.98347*todays_yday)

# plot average annual flows
p <- ggplot(gauge_annual, aes(year, annual_flow)) +
  #geom_line(data=gauge_annual, aes(x=year, y=mean(gauge_annual$annual_flow)), colour="brown", size=0.5) +
  #geom_line(data=gauge_annual, aes(x=year, y=median(gauge_annual$annual_flow)), colour="red", size=0.5) +
  geom_bar(stat="identity", width=0.2, alpha=0.5) +
  geom_point(size=2) +
  ylab("acre feet") +
  xlab("Data: USGS; graph by John Fleck, University of New Mexico Water Resources Program") +
  ggtitle(gauge_meta$station_nm, subtitle="annual flow") +
  #annotate("text", x=2020, y=mean(gauge_annual$annual_flow), label="mean", size=3) +
  #annotate("text", x=2020, y=median(gauge_annual$annual_flow), label="median", size=3) +
  labs(title=gauge_meta$station_nm,
       subtitle=startdate,
       x = "year",
       y = "acre feet",
       caption = "Data: USGS\ngraph: University of New Mexico Water Resources Program
       code: https://github.com/johnrfleck/water-tools") +
  theme(strip.text = element_text(face = "bold", size = 8))
print(p)

