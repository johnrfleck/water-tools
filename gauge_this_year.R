# Load libraries
library(dataRetrieval)
library(ggplot2)
library(dplyr)
library(lubridate)

# Prompt for the gage number
siteNumber <- readline(prompt = "Please enter the gage number: ")

# Define parameter and dates
parameterCode <- "00060"  # Discharge
startDate <- "1895-02-01"
endDate <- Sys.Date()

# Retrieve the data
dailyStreamflow <- readNWISdv(siteNumbers = siteNumber, parameterCd = parameterCode, startDate = startDate, endDate = endDate)

# Extract the station name
siteMetadata <- readNWISsite(siteNumber)
site_name <- siteMetadata$station_nm

# Add columns for Year and Day of Year
dailyStreamflow <- dailyStreamflow %>%
  mutate(Year = as.numeric(format(Date, "%Y")),
         DayOfYear = as.numeric(format(Date, "%j")))

# Function to calculate percentiles
calculate_percentile <- function(x, percentile) {
  quantile(x, probs = percentile / 100, na.rm = TRUE)
}

# Group data by DayOfYear
grouped <- dailyStreamflow %>%
  group_by(DayOfYear)

# Calculate required statistics
stats_df <- grouped %>%
  summarize(Max = max(X_00060_00003, na.rm = TRUE),
            Min = min(X_00060_00003, na.rm = TRUE),
            Median = median(X_00060_00003, na.rm = TRUE),
            P90 = calculate_percentile(X_00060_00003, 90),
            P70 = calculate_percentile(X_00060_00003, 70),
            P30 = calculate_percentile(X_00060_00003, 30),
            P10 = calculate_percentile(X_00060_00003, 10))

# Auto-detect current year and filter current year data
current_year <- year(Sys.Date())
current_year_data <- dailyStreamflow %>%
  filter(Year == current_year)

# Filter for periods
median_1981_2000 <- dailyStreamflow %>%
  filter(Year >= 1981 & Year <= 2000) %>%
  group_by(DayOfYear) %>%
  summarize(Median_1981_2000 = median(X_00060_00003, na.rm = TRUE))

median_2001_present <- dailyStreamflow %>%
  filter(Year >= 2001) %>%
  group_by(DayOfYear) %>%
  summarize(Median_2001_present = median(X_00060_00003, na.rm = TRUE))

# Merge the two median data frames
median_df <- merge(median_1981_2000, median_2001_present, by = "DayOfYear", all = TRUE)

# Plot statistics
p <- ggplot(stats_df, aes(x = DayOfYear)) +
  # Percentile bands (ribbons)
  geom_ribbon(aes(ymin = P10, ymax = P90, fill = "10th to 90th percentile"), alpha = 0.3) +
  geom_ribbon(aes(ymin = P30, ymax = P70, fill = "30th to 70th percentile"), alpha = 0.3) +

  # Historical median lines
  geom_line(aes(y = Median, color = "Period of record median"), linetype = "solid", linewidth = 0.5) +
  geom_line(data = median_df, aes(y = Median_1981_2000, color = "Median 1981-2000"), linewidth = 0.5) +
  geom_line(data = median_df, aes(y = Median_2001_present, color = "Median 2001-Present"), linewidth = 0.5) +

  # Current year overlay (thick blue line)
  geom_line(data = current_year_data, aes(x = DayOfYear, y = X_00060_00003, color = paste("Flow", current_year)), linewidth = 0.5) +

  # Colors and fills
  scale_color_manual(values = setNames(
    c("black", "red", "purple", "blue"),
    c("Period of record median", "Median 1981-2000", "Median 2001-Present", paste("Flow", current_year))
  ), name = NULL) +
  scale_fill_manual(values = c(
    "10th to 90th percentile" = "blue",
    "30th to 70th percentile" = "green"
  ), name = NULL) +

  # X-axis with month labels
  scale_x_continuous(
    breaks = c(1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335),
    labels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  ) +

  # Labels and theme
  labs(title = paste("Daily Flows at the", site_name, "USGS Gage\nPeriod of record:", min(dailyStreamflow$Year), "to present"),
       x = "Data Source: USGS\nJohn Fleck, Utton Center, University of New Mexico School of Law",
       y = "Streamflow, cfs") +
  theme_bw() +
  theme(
    axis.title.x = element_text(size = 8, hjust = 0),
    legend.position = c(0.98, 0.98),
    legend.justification = c("right", "top"),
    legend.box.background = element_rect(color = "black", linewidth = 0.5),
    legend.box.margin = margin(6, 6, 6, 6)
  )

print(p)


