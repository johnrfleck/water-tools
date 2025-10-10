# Download and visualize annual flow at any USGS stream gage
# Displays annual flow in thousand acre-feet with mean line overlay
#
# Example gage numbers:
# 08330000 - Rio Grande at Albuquerque, NM
# 08313000 - Rio Grande at Otowi Bridge, NM
# 08332010 - Rio Grande Floodway near Bernardo, NM

source("usgs_gage_utils.r")

# Get gage number from user
siteNo <- readline(prompt = "Enter a gage number: ")

# For testing, uncomment:
# siteNo <- "08330000"

# Fetch streamflow data using utilities
gage_data <- fetch_gage_streamflow(siteNo, start_date = "1895-02-01")

# Extract components
daily_data <- gage_data$data
site_name <- gage_data$site_name
start_date <- min(daily_data$Date)

# Get current year
current_year <- year(Sys.Date())

# Create annual average flows
# The *724 conversion factor converts cfs to acre-feet per year
# Exclude current year since it's incomplete
annual_flow <- daily_data %>%
  filter(Year < current_year) %>%
  group_by(Year) %>%
  summarize(annual_af = mean(flow, na.rm = TRUE) * 724, .groups = "drop")

# Calculate mean for reference line
mean_annual <- mean(annual_flow$annual_af / 1000)

# Create subtitle with data series info
subtitle_text <- sprintf("Annual flow\nUSGS gage %s\nData series start date: %s",
                        siteNo, format(start_date, "%Y-%m-%d"))

# Calculate year range for x-axis breaks
year_min <- min(annual_flow$Year)
year_max <- max(annual_flow$Year)
year_breaks <- seq(ceiling(year_min / 5) * 5, floor(year_max / 5) * 5, by = 5)

# Plot annual flows
p <- ggplot(annual_flow, aes(x = Year, y = annual_af / 1000)) +
  geom_bar(stat = "identity") +
  geom_line(aes(y = mean_annual), colour = "brown", linewidth = 0.5) +
  annotate("text", x = current_year, y = mean_annual,
           label = "mean", size = 3, hjust = 0, nudge_x = 1) +
  scale_x_continuous(breaks = year_breaks) +
  labs(
    title = site_name,
    subtitle = subtitle_text,
    x = standard_gage_attribution(),
    y = "thousand acre feet"
  ) +
  apply_gage_theme()

print(p)

