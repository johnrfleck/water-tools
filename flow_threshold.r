# Flow threshold analysis tool for drought/flood monitoring
# Counts days per year where flow is above or below a specified threshold
# Useful for tracking low-flow drought conditions or high-flow events
# Includes current year for real-time monitoring
#
# Example gage numbers:
# 08330000d - Rio Grande at Albuquerque, NM
# 08313000 - Rio Grande at Otowi Bridge, NM
# 08332010 - Rio Grande Floodway near Bernardo, NM

source("usgs_gage_utils.r")

# Get gage number from user
siteNo <- readline(prompt = "Enter a gage number: ")

# Get threshold value
threshold <- as.numeric(readline(prompt = "Enter flow threshold in cfs: "))

# Get direction (above or below)
direction <- tolower(readline(prompt = "Count days above or below threshold? Enter above/below: "))

# Validate direction input
while (!(direction %in% c("above", "below"))) {
  cat("Invalid input. Please enter 'above' or 'below'.\n")
  direction <- tolower(readline(prompt = "Count days above or below threshold? Enter above/below: "))
}

# For testing, uncomment:
# siteNo <- "08330000"
# threshold <- 100
# direction <- "below"

# Fetch streamflow data using utilities
gage_data <- fetch_gage_streamflow(siteNo, start_date = "1895-02-01")

# Extract components
daily_data <- gage_data$data
site_name <- gage_data$site_name
start_date <- min(daily_data$Date)

# Filter out spurious negative flows (data quality issue)
daily_data <- daily_data %>%
  filter(flow > -1)

# Count days per year meeting threshold criteria
if (direction == "below") {
  threshold_data <- daily_data %>%
    filter(flow <= threshold) %>%
    count(Year, name = "days_count")
  title_text <- sprintf("Days with flow %s cfs or less", threshold)
} else {
  threshold_data <- daily_data %>%
    filter(flow >= threshold) %>%
    count(Year, name = "days_count")
  title_text <- sprintf("Days with flow %s cfs or greater", threshold)
}

# Create subtitle with data series info
subtitle_text <- sprintf("%s, %s\nData series start date: %s",
                        site_name, siteNo, format(start_date, "%Y-%m-%d"))

# Calculate year range for x-axis breaks
year_min <- min(threshold_data$Year)
year_max <- max(threshold_data$Year)
year_breaks <- seq(ceiling(year_min / 5) * 5, floor(year_max / 5) * 5, by = 5)

# Plot threshold exceedances
p <- ggplot(threshold_data, aes(x = Year, y = days_count)) +
  geom_bar(stat = "identity") +
  scale_x_continuous(breaks = year_breaks) +
  labs(
    title = title_text,
    subtitle = subtitle_text,
    x = standard_gage_attribution(),
    y = "number of days"
  ) +
  apply_gage_theme()

print(p)
