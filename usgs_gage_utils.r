# USGS Stream Gage Analysis Utilities
# Common functions for analyzing USGS stream gage data
# John Fleck, Utton Center, University of New Mexico School of Law
#
# Note: Uses USGS spelling "gage" not "gauge" - a commitment to honor
# USGS stream gagers and their tradition

library(dataRetrieval)
library(tidyverse)
library(lubridate)

# Data Fetching ----------------------------------------------------------

# Site ID and metadata helpers --------------------------------------------

#' Convert a bare site number to the new API's monitoring-location ID
#'
#' The new USGS Water Data API identifies sites as "USGS-08330000" instead of
#' "08330000". IDs that already carry an agency prefix are left alone.
#'
#' @param site_number Character. USGS site number, with or without "USGS-"
#' @return Character vector of IDs with the "USGS-" prefix
usgs_site_id <- function(site_number) {
  site_number <- trimws(as.character(site_number))
  ifelse(grepl("^[A-Za-z]+-", site_number), site_number, paste0("USGS-", site_number))
}

#' Fetch a site's name
#'
#' Looks up the station name via read_waterdata_monitoring_location().
#' Falls back to the site number if the lookup fails or returns nothing.
#'
#' @param site_number Character. USGS site number
#' @return Character. Station name (or the site number)
fetch_site_name <- function(site_number) {
  meta <- try(
    read_waterdata_monitoring_location(
      monitoring_location_id = usgs_site_id(site_number),
      skip_geometry = TRUE
    ),
    silent = TRUE
  )
  if (inherits(meta, "try-error") || !nrow(meta) ||
      !"monitoring_location_name" %in% names(meta)) {
    return(as.character(site_number))
  }
  as.character(meta$monitoring_location_name[1])
}


#' Fetch USGS Gage Streamflow Data
#'
#' Retrieves daily streamflow data from USGS using dataRetrieval package
#' and returns a standardized tibble with date, year, day-of-year, and flow columns.
#'
#' @param site_number Character. USGS gage number (e.g., "08330000" for Albuquerque)
#' @param start_date Character. Start date in "YYYY-MM-DD" format (default: "1895-02-01")
#' @param end_date Date. End date (default: Sys.Date())
#' @return List containing:
#'   - data: Tibble with Date, Year, DayOfYear, and flow columns
#'   - site_name: Station name from metadata
#'   - site_number: USGS site number
#' @examples
#' # Rio Grande at Albuquerque, NM
#' abq <- fetch_gage_streamflow("08330000")
#'
#' # Rio Grande at Otowi Bridge, NM
#' otowi <- fetch_gage_streamflow("08313000", start_date = "1900-01-01")
#'
#' # Rio Grande Floodway near Bernardo, NM
#' bernardo <- fetch_gage_streamflow("08332010")
fetch_gage_streamflow <- function(site_number,
                                   start_date = "1895-02-01",
                                   end_date = Sys.Date()) {

  # Parameter code for discharge (streamflow); statistic 00003 = daily mean
  parameter_code <- "00060"

  # Retrieve the data from the new USGS Water Data API.
  # (Plain language: the old NWIS "waterservices" web service is being retired;
  # read_waterdata_daily() talks to its replacement.) The new API wants IDs
  # in the form "USGS-08330000" and a time interval rather than start/end args.
  daily_streamflow <- read_waterdata_daily(
    monitoring_location_id = usgs_site_id(site_number),
    parameter_code = parameter_code,
    statistic_id = "00003",
    time = c(as.character(start_date), as.character(end_date)),
    skip_geometry = TRUE
  )

  # Get site name from the monitoring-location metadata
  site_name <- fetch_site_name(site_number)

  # Add columns for Date, Year and Day of Year, rename flow column.
  # The new API returns the date in `time` and the discharge in `value`;
  # we keep the Date/Year/DayOfYear/flow columns the plotting scripts expect.
  daily_streamflow <- daily_streamflow %>%
    as_tibble() %>%
    mutate(
      Date = as.Date(time),
      Year = as.numeric(format(Date, "%Y")),
      DayOfYear = as.numeric(format(Date, "%j")),
      flow = as.numeric(value)
    ) %>%
    arrange(Date)

  return(list(
    data = daily_streamflow,
    site_name = site_name,
    site_number = site_number
  ))
}

#' Fetch USGS Gage Peak Flow Data
#'
#' Retrieves annual peak flow data from USGS using dataRetrieval package
#' and returns a standardized list with peak flow data and site metadata.
#'
#' @param site_number Character. USGS gage number (e.g., "08330000" for Albuquerque)
#' @param start_date Character. Start date in "YYYY-MM-DD" format (default: "1895-02-01")
#' @param end_date Date. End date (default: Sys.Date())
#' @return List containing:
#'   - data: Tibble with peak flow data (peak_dt, peak_va, etc.)
#'   - site_name: Station name from metadata
#'   - site_number: USGS site number
#' @examples
#' # Rio Grande at Albuquerque, NM
#' abq_peaks <- fetch_gage_peak("08330000")
#'
#' # Rio Grande at Otowi Bridge, NM
#' otowi_peaks <- fetch_gage_peak("08313000", start_date = "1900-01-01")
fetch_gage_peak <- function(site_number,
                            start_date = "1895-02-01",
                            end_date = Sys.Date()) {

  # NOTE: peak flows have no replacement in the released dataRetrieval yet
  # (only in the development version), so this still uses the legacy
  # readNWISpeak(). It will stop working when USGS retires the old service.
  # Retrieve peak flow data
  peak_data <- readNWISpeak(
    siteNumbers = site_number,
    startDate = start_date,
    endDate = end_date
  )

  # Get site name from the monitoring-location metadata
  site_name <- fetch_site_name(site_number)

  # Convert to tibble and add year column for convenience
  peak_data <- as_tibble(peak_data) %>%
    mutate(Year = as.numeric(format(peak_dt, "%Y")))

  return(list(
    data = peak_data,
    site_name = site_name,
    site_number = site_number
  ))
}

# Groundwater Data Functions ---------------------------------------------

# Helper: Null coalescing operator
`%||%` <- function(x, y) {
  if(is.null(x) || length(x) == 0 || (is.character(x) && x == "")) y else x
}

# Helper: Suppress warnings and errors for data retrieval attempts
trySuppress <- function(expr) {
  suppressWarnings(suppressMessages(try(expr, silent = TRUE)))
}

# Groundwater parameter codes (in priority order)
# 72019 = Depth to water level, feet below land surface
# 62610 = Groundwater level above NGVD 1929, feet
# 62611 = Groundwater level above NAVD 1988, feet
# 62614 = Groundwater level above mean sea level, feet
.gw_preferred_pcodes <- c("72019", "62610", "62611", "62614")

# Statistic code priority for daily values
# 00002 = minimum, 00003 = mean
.stat_priority <- c("00002", "00003")

# Normalizer: Manual groundwater level measurements
# Input is the output of read_waterdata_field_measurements(): `time` is the
# measurement date-time and `value` the reading.
.normalize_gwl <- function(df) {
  as_tibble(df) %>%
    transmute(
      site_no = sub("^[A-Za-z]+-", "", as.character(monitoring_location_id)),
      date_time = suppressWarnings(as.POSIXct(time, tz = "UTC")),
      date = as.Date(time),
      depth_bls_ft = suppressWarnings(as.numeric(value)),
      source = "gwl",
      tz = "UTC"
    ) %>%
    filter(!is.na(depth_bls_ft))
}

# Normalizer: Daily value groundwater data
# Input is the output of read_waterdata_daily(): `time` is the date, `value`
# the reading. (The pcode argument is kept for backward compatibility.)
.normalize_dv <- function(df, pcode = NULL) {
  as_tibble(df) %>%
    transmute(
      site_no = sub("^[A-Za-z]+-", "", as.character(monitoring_location_id)),
      date_time = as.POSIXct(as.Date(time)),
      date = as.Date(time),
      depth_bls_ft = suppressWarnings(as.numeric(value)),
      source = "dv",
      tz = "UTC"
    ) %>%
    filter(!is.na(depth_bls_ft))
}

# Normalizer: Unit/instantaneous value groundwater data
# (Not currently called by fetch_gw_series(); kept for future use.)
.normalize_uv <- function(df, pcode = NULL) {
  tz_val <- attr(df$time, "tzone") %||% "UTC"
  as_tibble(df) %>%
    transmute(
      site_no = sub("^[A-Za-z]+-", "", as.character(monitoring_location_id)),
      date_time = as.POSIXct(time, tz = tz_val),
      date = as.Date(time, tz = tz_val),
      depth_bls_ft = suppressWarnings(as.numeric(value)),
      source = "uv",
      tz = tz_val
    ) %>%
    filter(!is.na(depth_bls_ft))
}

#' Suggest Groundwater Data Options
#'
#' Queries the USGS Water Data API to discover what types of groundwater data
#' are available at a site and returns summary information about availability.
#' Daily and continuous availability come from the time-series metadata
#' (read_waterdata_ts_meta); manual measurements come from the
#' field-measurements service (read_waterdata_field_measurements), because the
#' old whatNWISdata() "gw" listing no longer exists.
#'
#' @param site_no Character. USGS site number
#' @return List containing:
#'   - availability: Tibble of all available groundwater data types
#'     (data_type_cd: "gw" manual, "dv" daily, "uv" continuous)
#'   - summaries: Tibble with date ranges and parameter codes by data type
#'   - has_gwl: Logical, TRUE if manual groundwater levels available
#'   - has_dv: Logical, TRUE if daily values available
#'   - has_uv: Logical, TRUE if unit values available
#' @examples
#' # Check what data is available at a site
#' info <- suggest_gw_options("350534106354703")
#' print(info$summaries)
suggest_gw_options <- function(site_no) {
  site_id <- usgs_site_id(site_no)

  # Daily / continuous series: time-series metadata for groundwater pcodes
  ts_meta <- trySuppress(read_waterdata_ts_meta(
    monitoring_location_id = site_id,
    parameter_code = .gw_preferred_pcodes,
    skip_geometry = TRUE
  ))
  ts_rows <- tibble()
  if (!inherits(ts_meta, "try-error") && nrow(ts_meta)) {
    ts_rows <- as_tibble(ts_meta) %>%
      transmute(
        data_type_cd = case_when(
          computation_period_identifier == "Daily" ~ "dv",
          computation_period_identifier == "Points" ~ "uv",
          TRUE ~ NA_character_
        ),
        parm_cd = as.character(parameter_code),
        stat_cd = as.character(statistic_id),
        begin_date = as.Date(begin),
        end_date = as.Date(end)
      ) %>%
      filter(!is.na(data_type_cd))
  }

  # Manual measurements: field-measurements service
  fm <- trySuppress(read_waterdata_field_measurements(
    monitoring_location_id = site_id,
    parameter_code = .gw_preferred_pcodes,
    skip_geometry = TRUE
  ))
  fm_rows <- tibble()
  if (!inherits(fm, "try-error") && nrow(fm)) {
    fm_rows <- as_tibble(fm) %>%
      group_by(parm_cd = as.character(parameter_code)) %>%
      summarize(
        begin_date = min(as.Date(time), na.rm = TRUE),
        end_date = max(as.Date(time), na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(data_type_cd = "gw", stat_cd = NA_character_)
  }

  gw_rows <- bind_rows(ts_rows, fm_rows)

  if(!nrow(gw_rows)) {
    return(list(
      availability = tibble(),
      summaries = tibble(),
      has_gwl = FALSE,
      has_dv = FALSE,
      has_uv = FALSE
    ))
  }

  gw_rows <- gw_rows %>%
    mutate(has_pcode = if_else(is.na(parm_cd), FALSE, parm_cd %in% .gw_preferred_pcodes))

  summaries <- gw_rows %>%
    group_by(data_type_cd) %>%
    summarize(
      earliest = suppressWarnings(min(begin_date, na.rm = TRUE)),
      latest   = suppressWarnings(max(end_date, na.rm = TRUE)),
      pcodes   = paste(unique(na.omit(parm_cd)), collapse = ", "),
      .groups = "drop"
    )

  list(
    availability = gw_rows,
    summaries = summaries,
    has_gwl = any(gw_rows$data_type_cd == "gw"),
    has_dv  = any(gw_rows$data_type_cd == "dv" & gw_rows$has_pcode),
    has_uv  = any(gw_rows$data_type_cd == "uv" & gw_rows$has_pcode)
  )
}

#' Fetch Groundwater Time Series
#'
#' Retrieves groundwater level data from the USGS Water Data API. Supports two modes:
#' - daily_only: Daily values (read_waterdata_daily)
#' - manual_only: Manual field measurements (read_waterdata_field_measurements)
#'
#' @param site_no Character. USGS site number
#' @param mode Character. One of "daily_only" or "manual_only" (default: "daily_only")
#' @param start_date Character. Start date "YYYY-MM-DD" or NULL for earliest available
#' @param end_date Character or Date. End date (default: Sys.Date())
#' @param pcode_priority Character vector. Parameter codes in priority order
#' @param stat_priority Character vector. Statistic codes in priority order
#' @return Tibble with columns: site_no, date_time, date, depth_bls_ft, source, tz
#' @examples
#' # Fetch daily groundwater data
#' gw_data <- fetch_gw_series("350534106354703", mode = "daily_only")
#'
#' # Fetch manual measurements only
#' gw_manual <- fetch_gw_series("350534106354703", mode = "manual_only")
fetch_gw_series <- function(site_no,
                            mode = c("daily_only", "manual_only"),
                            start_date = NULL,
                            end_date = Sys.Date(),
                            pcode_priority = .gw_preferred_pcodes,
                            stat_priority = .stat_priority) {
  mode <- match.arg(mode)
  info <- suggest_gw_options(site_no)
  site_id <- usgs_site_id(site_no)

  if(!nrow(info$availability)) return(tibble())

  # Determine date range
  all_dates <- info$availability %>%
    summarize(
      earliest = suppressWarnings(min(begin_date, na.rm = TRUE)),
      latest   = suppressWarnings(max(end_date, na.rm = TRUE))
    )

  if(is.null(start_date) || start_date == "") {
    start_date <- as.character(all_dates$earliest %||% as.Date("1900-01-01"))
  }
  if(is.null(end_date) || end_date == "") {
    end_date <- as.character(all_dates$latest %||% Sys.Date())
  }
  time_range <- c(as.character(start_date), as.character(end_date))

  out_list <- list()

  # Manual groundwater levels (field measurements)
  if(mode == "manual_only") {
    gw_avail <- info$availability %>%
      filter(data_type_cd == "gw", parm_cd %in% pcode_priority)

    if(nrow(gw_avail)) {
      pcode <- intersect(pcode_priority, unique(gw_avail$parm_cd))[1]
      gwl <- trySuppress(read_waterdata_field_measurements(
        monitoring_location_id = site_id,
        parameter_code = pcode,
        time = time_range,
        skip_geometry = TRUE
      ))
      if(!inherits(gwl, "try-error") && nrow(gwl)) {
        out_list$gwl <- .normalize_gwl(gwl)
      }
    }
  }

  # Daily values
  if(mode == "daily_only") {
    dv_avail <- info$availability %>%
      filter(data_type_cd == "dv", parm_cd %in% pcode_priority)

    if(nrow(dv_avail)) {
      pcode <- intersect(pcode_priority, unique(dv_avail$parm_cd))[1]
      st <- intersect(stat_priority, unique(na.omit(dv_avail$stat_cd)))
      stat_use <- st[1] %||% stat_priority[1]

      dv <- trySuppress(read_waterdata_daily(
        monitoring_location_id = site_id,
        parameter_code = pcode,
        statistic_id = stat_use,
        time = time_range,
        skip_geometry = TRUE
      ))

      if(!inherits(dv, "try-error") && nrow(dv)) {
        out_list$dv <- .normalize_dv(dv, pcode)
      }
    }
  }

  ts <- bind_rows(out_list)
  ts %>% arrange(date_time)
}

# Percentile Analysis ----------------------------------------------------

#' Calculate Daily Percentiles
#'
#' Calculates percentile statistics (min, max, 10th, 30th, 70th, 90th, median)
#' for each day of year across entire historical record.
#'
#' @param data Tibble. Must contain 'DayOfYear' and 'flow' columns
#' @return Tibble with daily percentiles grouped by DayOfYear
calculate_daily_percentiles <- function(data) {

  # Function to calculate percentiles
  calculate_percentile <- function(x, percentile) {
    quantile(x, probs = percentile / 100, na.rm = TRUE)
  }

  stats_df <- data %>%
    group_by(DayOfYear) %>%
    summarize(
      Max = max(flow, na.rm = TRUE),
      Min = min(flow, na.rm = TRUE),
      Median = median(flow, na.rm = TRUE),
      P90 = calculate_percentile(flow, 90),
      P70 = calculate_percentile(flow, 70),
      P30 = calculate_percentile(flow, 30),
      P10 = calculate_percentile(flow, 10),
      .groups = "drop"
    )

  return(stats_df)
}

#' Get Current Year Data
#'
#' Auto-detects current year and filters data for that year.
#'
#' @param data Tibble. Must contain 'Year' column
#' @return Tibble filtered to current year only
get_current_year_data <- function(data) {
  current_year <- year(Sys.Date())

  current_year_data <- data %>%
    filter(Year == current_year)

  return(current_year_data)
}

#' Calculate Split Medians
#'
#' Calculates median flows for two time periods to provide climate context:
#' 1981-2000 (wetter period) and 2001-present (drier period).
#'
#' @param data Tibble. Must contain 'Year', 'DayOfYear', and 'flow' columns
#' @return Tibble with DayOfYear, Median_1981_2000, and Median_2001_present columns
calculate_split_medians <- function(data) {

  # Calculate median for 1981-2000
  median_1981_2000 <- data %>%
    filter(Year >= 1981 & Year <= 2000) %>%
    group_by(DayOfYear) %>%
    summarize(Median_1981_2000 = median(flow, na.rm = TRUE), .groups = "drop")

  # Calculate median for 2001-present
  median_2001_present <- data %>%
    filter(Year >= 2001) %>%
    group_by(DayOfYear) %>%
    summarize(Median_2001_present = median(flow, na.rm = TRUE), .groups = "drop")

  # Merge the two median data frames
  median_df <- merge(median_1981_2000, median_2001_present, by = "DayOfYear", all = TRUE)

  return(median_df)
}

# Visualization Standards ------------------------------------------------

#' Standard Attribution Text
#'
#' Returns consistent attribution text for all USGS gage plots.
#'
#' @return Character string with data source and attribution
standard_gage_attribution <- function() {
  "Source: USGS NWIS\nJohn Fleck, Utton Center, University of New Mexico School of Law\nhttps://github.com/johnrfleck/water-tools"
}

#' Gage Percentile Band Colors
#'
#' Returns consistent color scheme for percentile band visualizations.
#' Matches the Python gagethisyear.py color scheme.
#'
#' @return Named vector of colors for fill aesthetic
gage_percentile_colors <- function() {
  c(
    "10th to 90th percentile" = "blue",
    "30th to 70th percentile" = "green"
  )
}

#' Gage Line Colors
#'
#' Returns color scheme for median lines and current year overlay.
#'
#' @param current_year Numeric. Current year for labeling (default: auto-detect)
#' @return Named vector of colors for line aesthetics
gage_line_colors <- function(current_year = NULL) {
  if (is.null(current_year)) {
    current_year <- year(Sys.Date())
  }

  setNames(
    c("black", "red", "purple", "blue"),
    c("Period of record median", "Median 1981-2000", "Median 2001-Present", paste("Flow", current_year))
  )
}

#' Month Axis Scale
#'
#' Returns a scale_x_continuous() with month labels positioned at month starts.
#'
#' @return ggplot2 scale object
month_axis_scale <- function() {
  scale_x_continuous(
    breaks = c(1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335),
    labels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  )
}

#' Apply Gage Plot Theme
#'
#' Applies consistent ggplot2 theme settings for gage visualizations.
#' Uses theme_bw() with standardized attribution text formatting and inset legend.
#'
#' @param legend_position Numeric vector of length 2. Position of legend (default: c(0.98, 0.98) for upper right)
#' @return ggplot2 theme object
apply_gage_theme <- function(legend_position = c(0.98, 0.98)) {
  theme_bw() +
    theme(
      axis.title.x = element_text(size = 8, hjust = 0),
      legend.position = legend_position,
      legend.justification = c("right", "top"),
      legend.box.background = element_rect(color = "black", linewidth = 0.5),
      legend.box.margin = margin(6, 6, 6, 6)
    )
}

# Plot Saving ------------------------------------------------------------

#' Save Plot with Date-based Filename
#'
#' Saves a ggplot object as a PNG file with standardized parameters and
#' date-based filename. Files are saved to ./graphics/ directory.
#'
#' @param plot ggplot object to save
#' @param filename_prefix Character. Prefix for filename (e.g., "albuquerque-gage")
#' @param width Numeric. Plot width in inches (default: 10)
#' @param height Numeric. Plot height in inches (default: 6)
#' @param dpi Numeric. Resolution in dots per inch (default: 300)
#' @return Invisible path to saved file
#' @examples
#' p <- ggplot(...) + ...
#' save_dated_gage_plot(p, "abq-flow")
save_dated_gage_plot <- function(plot, filename_prefix, width = 10, height = 6, dpi = 300) {
  # Generate date-based filename
  date_str <- format(Sys.Date(), "%Y-%m-%d")
  filename <- sprintf("%s-%s.png", date_str, filename_prefix)
  filepath <- file.path("./graphics", filename)

  # Create graphics directory if it doesn't exist
  if (!dir.exists("./graphics")) {
    dir.create("./graphics")
  }

  # Save plot
  ggsave(
    filename = filepath,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    units = "in"
  )

  cat(sprintf("Plot saved: %s\n", filepath))
  return(invisible(filepath))
}
