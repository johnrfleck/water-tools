# USGS Stream Gage Ridge Plot (formerly "joyplot")
# Creates ridge plot visualization of daily discharge patterns over time
# Useful for identifying changes in streamflow seasonality due to climate variability,
# climate change, and human interventions (dam operations, diversions, etc.)
#
# John Fleck, Utton Center, University of New Mexico School of Law
# Based on original code by Lauren Steely, @MadreDeZanjas
# https://github.com/codeswitching/Reservoir-inflow-analysis/tree/master
#
# Usage: source("gage_ridgeplot.r")

library(dataRetrieval)
library(tidyverse)
library(lubridate)
library(ggridges)

# Load utility functions
source("./usgs_gage_utils.r")

# User Input -----------------------------------------------------------------

# Prompt for gage number
site_number <- readline(prompt = "Enter a gage number: ")

# Prompt for scale factor (controls vertical spacing/overlap of ridges)
# Larger numbers = more overlap, useful for highlighting variability
# 3 is a good starting point
scale_factor <- readline(prompt = "Enter scale factor (try 3 to start): ")
scale_factor <- as.numeric(scale_factor)

# Data Retrieval -------------------------------------------------------------

# Fetch gage data using utilities library
gage_data <- fetch_gage_streamflow(site_number)
site_name <- gage_data$site_name
daily_data <- gage_data$data

# Reality check - display station name
cat("\nStation:", site_name, "\n\n")

# Create Ridge Plot ----------------------------------------------------------

# Calculate period of record for title
start_year <- min(daily_data$Year, na.rm = TRUE)
end_year <- max(daily_data$Year, na.rm = TRUE)

# Create title
plot_title <- paste("Daily Flow Patterns at the", site_name, "USGS Gage\nPeriod of record:",
                    start_year, "to", end_year)

# Create ridge plot
# Note: Using factor(Year) for y ensures proper spacing and reversal
# Create breaks for y-axis - show every 5th year
year_breaks <- seq(
  floor(start_year / 5) * 5,
  ceiling(end_year / 5) * 5,
  by = 5
)
year_breaks <- year_breaks[year_breaks >= start_year & year_breaks <= end_year]

p <- ggplot(daily_data, aes(x = DayOfYear, y = factor(Year), height = flow,
                            group = Year, fill = factor(Year))) +
  geom_density_ridges(stat = "identity", scale = scale_factor, linewidth = 0.1) +
  scale_y_discrete(limits = rev, breaks = as.character(year_breaks)) +
  labs(
    title = plot_title,
    y = "Year",
    x = standard_gage_attribution()
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    axis.title.x = element_text(size = 8, hjust = 0)
  )

print(p)
