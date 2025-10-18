# USGS Stream Gage Annual Peak Flow
# Visualizes annual peak flows over time for a specified gage
# Uses USGS peak flow data which represents the highest instantaneous flow each year
#
# John Fleck, Utton Center, University of New Mexico School of Law
#
# Usage: source("gage_annual_peak.r")

library(dataRetrieval)
library(tidyverse)
library(lubridate)

# Load utility functions
source("./usgs_gage_utils.r")

# User Input -----------------------------------------------------------------

# Prompt for gage number
site_number <- readline(prompt = "Enter a gage number: ")

# Data Retrieval -------------------------------------------------------------

# Fetch peak flow data using utilities library
peak_data <- fetch_gage_peak(site_number)
site_name <- peak_data$site_name
peaks <- peak_data$data

# Reality check - display station name
cat("\nStation:", site_name, "\n\n")

# Calculate period of record
start_year <- min(peaks$Year, na.rm = TRUE)
end_year <- max(peaks$Year, na.rm = TRUE)
start_date <- min(peaks$peak_dt, na.rm = TRUE)

# Create subtitle
subtitle_text <- paste("Annual peak flows\nData series start:",
                      format(start_date, "%B %d, %Y"))

# Create Plot ----------------------------------------------------------------

# Create title
plot_title <- paste("Peak Flows at the", site_name, "USGS Gage")

p <- ggplot(peaks, aes(x = peak_dt, y = peak_va)) +
  geom_point(alpha = 0.7, size = 2) +
  labs(
    title = plot_title,
    subtitle = subtitle_text,
    y = "Peak flow, cubic feet per second",
    x = standard_gage_attribution()
  ) +
  theme_bw() +
  theme(
    axis.title.x = element_text(size = 8, hjust = 0)
  )

print(p)
