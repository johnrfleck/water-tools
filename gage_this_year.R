# Graph this year's flow on a river compared to historic record
# Uses USGS dataRetrieval package and usgs_gage_utils.r
# Displays current year flow in context of historical percentiles and split medians
#
# Example gage numbers:
# 08330000 - Rio Grande at Albuquerque, NM
# 08313000 - Rio Grande at Otowi Bridge, NM
# 08332010 - Rio Grande Floodway near Bernardo, NM

# Load utility functions
source("./usgs_gage_utils.r")

# Prompt for the gage number
siteNumber <- readline(prompt = "Please enter the gage number: ")

# Fetch gage data
gage_data <- fetch_gage_streamflow(siteNumber)
site_name <- gage_data$site_name
dailyStreamflow <- gage_data$data

# Calculate statistics
stats_df <- calculate_daily_percentiles(dailyStreamflow)
current_year_data <- get_current_year_data(dailyStreamflow)
median_df <- calculate_split_medians(dailyStreamflow)
current_year <- year(Sys.Date())

# Plot statistics
p <- ggplot(stats_df, aes(x = DayOfYear)) +
  # Percentile bands (ribbons)
  geom_ribbon(aes(ymin = P10, ymax = P90, fill = "10th to 90th percentile"), alpha = 0.3) +
  geom_ribbon(aes(ymin = P30, ymax = P70, fill = "30th to 70th percentile"), alpha = 0.3) +

  # Historical median lines
  geom_line(aes(y = Median, color = "Period of record median"), linetype = "solid", linewidth = 0.5) +
  geom_line(data = median_df, aes(y = Median_1981_2000, color = "Median 1981-2000"), linewidth = 0.5) +
  geom_line(data = median_df, aes(y = Median_2001_present, color = "Median 2001-Present"), linewidth = 0.5) +

  # Current year overlay
  geom_line(data = current_year_data, aes(x = DayOfYear, y = flow, color = paste("Flow", current_year)), linewidth = 0.5) +

  # Colors and fills (from utilities)
  scale_color_manual(values = gage_line_colors(current_year), name = NULL) +
  scale_fill_manual(values = gage_percentile_colors(), name = NULL) +

  # X-axis with month labels (from utilities)
  month_axis_scale() +

  # Labels and theme
  labs(title = paste("Daily Flows at the", site_name, "USGS Gage\nPeriod of record:", min(dailyStreamflow$Year), "to present"),
       x = standard_gage_attribution(),
       y = "Streamflow, cfs") +
  apply_gage_theme()

print(p)


