# Graph this year's flow at an MRGCD gage compared to historic record
# Uses MRGCD-USBR archive data from the USBR ET Toolbox:
# https://www.usbr.gov/uc/albuq/water/ETtoolboxV2/schematics/schematic_rio_grande.html
# Four letter codes found there
# Displays current year flow in context of historical percentiles and median
#
# Example gage identifiers:
# Angostura: ANGDV
# Tingley Beach Drain: ALBDR
# Belen High Line: BELCN
# Total Belen East Side: BESDV

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(lubridate)
})

# Percentile and visualization helpers matching gage_this_year.R

# Data source attribution for MRGCD-USBR plots
mrgcd_gage_attribution <- function() {
  paste(
    "Source: MRGCD-USBR Middle Rio Grande data archive",
    "John Fleck, Utton Center, University of New Mexico School of Law",
    "https://github.com/johnrfleck/water-tools",
    sep = "\n"
  )
}

calculate_daily_percentiles <- function(data) {
  data %>%
    group_by(DayOfYear) %>%
    summarize(
      Max = max(flow, na.rm = TRUE),
      Min = min(flow, na.rm = TRUE),
      Median = median(flow, na.rm = TRUE),
      P90 = quantile(flow, probs = 0.90, na.rm = TRUE),
      P70 = quantile(flow, probs = 0.70, na.rm = TRUE),
      P30 = quantile(flow, probs = 0.30, na.rm = TRUE),
      P10 = quantile(flow, probs = 0.10, na.rm = TRUE),
      .groups = "drop"
    )
}

get_current_year_data <- function(data) {
  data %>%
    filter(Year == year(Sys.Date()))
}

gage_percentile_colors <- function() {
  c(
    "10th to 90th percentile" = "blue",
    "30th to 70th percentile" = "green"
  )
}

gage_line_colors <- function(current_year = NULL) {
  if (is.null(current_year)) {
    current_year <- year(Sys.Date())
  }

  setNames(
    c("black", "blue"),
    c("Period of record median", paste("Flow", current_year))
  )
}

month_axis_scale <- function() {
  scale_x_continuous(
    breaks = c(1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335),
    labels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  )
}

apply_gage_theme <- function(legend_position = "right") {
  theme_bw() +
    theme(
      axis.title.x = element_text(size = 8, hjust = 0),
      legend.position = legend_position,
      legend.box.background = element_rect(color = "black", linewidth = 0.5),
      legend.box.margin = margin(6, 6, 6, 6)
    )
}

# Fetch MRGCD gage data directly from USBR. This always downloads the file.
fetch_mrgcd_gage <- function(gage_identifier) {
  download_url <- sprintf(
    "https://www.usbr.gov/uc/albuq/water/ETtoolboxV2/gages/current/mrgcd_%s.txt",
    gage_identifier
  )

  temp_path <- tempfile(fileext = ".txt")
  message("Downloading ", download_url)
  download.file(download_url, temp_path, quiet = TRUE)

  raw_data <- readr::read_tsv(
    temp_path,
    skip = 1,
    na = "M",
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  )

  raw_data %>%
    mutate(
      time_text = formatC(as.integer(Time), width = 4, flag = "0"),
      timestamp = ymd_hm(paste(
        paste(Year, Month, Day, sep = "-"),
        paste(substr(time_text, 1, 2), substr(time_text, 3, 4), sep = ":")
      )),
      discharge_cfs = as.numeric(`Discharge (cfs)`)
    ) %>%
    filter(!is.na(timestamp)) %>%
    select(timestamp, discharge_cfs)
}

# Prompt for the gage identifier and cutoff value
gage_identifier <- toupper(trimws(readline(prompt = "Please enter the MRGCD gage identifier: ")))

cutoff_input <- trimws(readline(prompt = "Please enter the high-flow cutoff in cfs: "))
cutoff_value <- suppressWarnings(as.numeric(cutoff_input))
if (is.na(cutoff_value)) {
  stop("Please enter a numeric cutoff value.")
}

# Fetch and prepare gage data
gage_readings <- fetch_mrgcd_gage(gage_identifier)

masked_count <- sum(
  !is.na(gage_readings$discharge_cfs) &
    gage_readings$discharge_cfs > cutoff_value
)

gage_readings <- gage_readings %>%
  mutate(
    discharge_cfs = if_else(discharge_cfs > cutoff_value, NA_real_, discharge_cfs),
    Date = as.Date(timestamp)
  )

message(sprintf("Masked %d readings above %g cfs.", masked_count, cutoff_value))

# Aggregate 30-minute readings to daily means. Require at least half of the
# expected daily readings so sparse days do not distort the historical record.
dailyStreamflow <- gage_readings %>%
  group_by(Date) %>%
  summarize(
    valid_count = sum(!is.na(discharge_cfs)),
    flow = mean(discharge_cfs, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    flow = if_else(valid_count >= 24, flow, NA_real_),
    Year = year(Date),
    DayOfYear = yday(Date)
  ) %>%
  filter(!is.na(flow))

if (nrow(dailyStreamflow) == 0) {
  stop("No daily flow data remained after applying the cutoff.")
}

# Calculate statistics
stats_df <- calculate_daily_percentiles(dailyStreamflow)
current_year_data <- get_current_year_data(dailyStreamflow)
current_year <- year(Sys.Date())

# Plot statistics
p <- ggplot(stats_df, aes(x = DayOfYear)) +
  # Percentile bands (ribbons)
  geom_ribbon(aes(ymin = P10, ymax = P90, fill = "10th to 90th percentile"), alpha = 0.3) +
  geom_ribbon(aes(ymin = P30, ymax = P70, fill = "30th to 70th percentile"), alpha = 0.3) +

  # Historical median lines
  geom_line(aes(y = Median, color = "Period of record median"), linetype = "solid", linewidth = 0.5, na.rm = TRUE) +

  # Current year overlay
  geom_line(data = current_year_data, aes(x = DayOfYear, y = flow, color = paste("Flow", current_year)), linewidth = 0.5, na.rm = TRUE) +

  # Colors and fills (from utilities)
  scale_color_manual(values = gage_line_colors(current_year), name = NULL) +
  scale_fill_manual(values = gage_percentile_colors(), name = NULL) +

  # X-axis with month labels (from utilities)
  month_axis_scale() +

  # Labels and theme
  labs(
    title = paste(
      "Daily Flows at the",
      gage_identifier,
      "MRGCD Gage\nPeriod of record:",
      min(dailyStreamflow$Year),
      "to present"
    ),
    subtitle = sprintf("Readings above %g cfs masked", cutoff_value),
    x = mrgcd_gage_attribution(),
    y = "Streamflow, cfs"
  ) +
  apply_gage_theme()

print(p)
