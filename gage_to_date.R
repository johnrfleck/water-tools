# Year-to-date flow comparison tool
# Calculates total flow accumulated from Jan 1 to current date for all years
# Filters all historical years to same day-of-year for fair comparison
# Includes current year for real-time monitoring
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

# Get today's day-of-year for filtering
todays_yday <- yday(Sys.Date())

# Filter all years to same day-of-year (apples-to-apples comparison)
year_to_date <- daily_data %>%
  filter(DayOfYear <= todays_yday)

# Calculate year-to-date flow totals
# Conversion: mean daily cfs * 1.98347 = acre-feet per day
# Then multiply by days elapsed
ytd_totals <- year_to_date %>%
  group_by(Year) %>%
  summarize(
    ytd_flow_af = mean(flow, na.rm = TRUE) * 1.98347 * todays_yday / 1000,
    .groups = "drop"
  )

# Create subtitle with data info
current_date <- format(Sys.Date(), "%B %d")
subtitle_text <- sprintf("Flow to date (%s)\nUSGS gage %s\nData series start date: %s",
                        current_date, siteNo, format(start_date, "%Y-%m-%d"))

# Calculate year range for x-axis breaks
year_min <- min(ytd_totals$Year)
year_max <- max(ytd_totals$Year)
year_breaks <- seq(ceiling(year_min / 5) * 5, floor(year_max / 5) * 5, by = 5)

# Get current year's flow for comparison
current_year <- year(Sys.Date())
current_year_flow <- ytd_totals %>%
  filter(Year == current_year) %>%
  pull(ytd_flow_af)

# Color current year and any years with less flow red
ytd_totals <- ytd_totals %>%
  mutate(color_flag = ifelse(Year == current_year | ytd_flow_af < current_year_flow,
                             "red", "gray30"))

# Plot year-to-date flows
p <- ggplot(ytd_totals, aes(x = Year, y = ytd_flow_af, fill = color_flag)) +
  geom_bar(stat = "identity") +
  scale_fill_identity() +
  scale_x_continuous(breaks = year_breaks) +
  scale_y_continuous(labels = scales::comma_format()) +
  annotate("text", x = year_min, y = max(ytd_totals$ytd_flow_af) * 0.95,
           label = "Red: current year and years with less flow",
           hjust = 0, size = 3, color = "red") +
  labs(
    title = site_name,
    subtitle = subtitle_text,
    x = standard_gage_attribution(),
    y = "thousand acre feet (TAF)"
  ) +
  apply_gage_theme()

print(p)

