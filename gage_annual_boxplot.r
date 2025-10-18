# USGS Stream Gage Annual Flow Boxplot
# Creates boxplot visualization of daily flows for each year
# Useful for visualizing year-to-year flow variability and trends over time
#
# John Fleck, Utton Center, University of New Mexico School of Law
#
# Usage: source("gage_annual_boxplot.r")

library(dataRetrieval)
library(tidyverse)
library(lubridate)

# Load utility functions
source("./usgs_gage_utils.r")

# User Input -----------------------------------------------------------------

# Prompt for gage number
site_number <- readline(prompt = "Enter a gage number: ")

# Data Retrieval -------------------------------------------------------------

# Fetch gage data using utilities library
gage_data <- fetch_gage_streamflow(site_number)
site_name <- gage_data$site_name
daily_data <- gage_data$data

# Reality check - display station name
cat("\nStation:", site_name, "\n\n")

# Data Preparation -----------------------------------------------------------

# Filter out any spurious negative flows
daily_data <- daily_data %>%
  filter(flow > 0)

# Calculate period of record
start_year <- min(daily_data$Year, na.rm = TRUE)
end_year <- max(daily_data$Year, na.rm = TRUE)
start_date <- min(daily_data$Date, na.rm = TRUE)

# Create breaks for x-axis - show every 5th year
year_breaks <- seq(
  floor(start_year / 5) * 5,
  ceiling(end_year / 5) * 5,
  by = 5
)
year_breaks <- year_breaks[year_breaks >= start_year & year_breaks <= end_year]

# Create subtitle
subtitle_text <- paste("Annual distribution of daily flows\nData series start:",
                      format(start_date, "%B %d, %Y"))

# Create Boxplot -------------------------------------------------------------

# Create title
plot_title <- paste("Daily Flows at the", site_name, "USGS Gage")

p <- ggplot(daily_data, aes(x = factor(Year), y = flow)) +
  geom_boxplot(outlier.size = 0.5) +
  scale_x_discrete(breaks = as.character(year_breaks)) +
  labs(
    title = plot_title,
    subtitle = subtitle_text,
    y = "Flow, cubic feet per second",
    x = standard_gage_attribution()
  ) +
  theme_bw() +
  theme(
    axis.title.x = element_text(size = 8, hjust = 0),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p)
