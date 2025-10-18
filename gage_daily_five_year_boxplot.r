# USGS Stream Gage Daily Flow Boxplot (Five-Year Bins)
# Creates boxplot visualization of daily flows grouped into five-year periods
# Useful for visualizing flow variability and changes over time
#
# John Fleck, Utton Center, University of New Mexico School of Law
#
# Usage: source("gage_daily_five_year_boxplot.r")
#
# Example gage numbers:
# 08330000 - Rio Grande at Albuquerque, NM
# 08313000 - Rio Grande at Otowi Bridge, NM
# 08332010 - Rio Grande Floodway near Bernardo, NM

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

# Create five-year bins
daily_data <- daily_data %>%
  mutate(five_year_bin = floor(Year / 5) * 5)

# Calculate period of record for subtitle
start_year <- min(daily_data$Year, na.rm = TRUE)
end_year <- max(daily_data$Year, na.rm = TRUE)
start_date <- min(daily_data$Date, na.rm = TRUE)

# Create subtitle
subtitle_text <- paste("Distribution of daily flows, five-year bins\nData series start:",
                      format(start_date, "%B %d, %Y"))

# Create Boxplot -------------------------------------------------------------

# Create title
plot_title <- paste("Daily Flows at the", site_name, "USGS Gage")

p <- ggplot(daily_data, aes(x = factor(five_year_bin), y = flow)) +
  geom_boxplot() +
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
