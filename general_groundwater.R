# USGS Groundwater Level Analysis Tool
# Interactive script for retrieving and plotting groundwater levels from USGS NWIS
# John Fleck, Utton Center, University of New Mexico School of Law
#
# Usage: source("general_groundwater.R")
# The script will prompt for site number and options interactively

library(dataRetrieval)
library(tidyverse)
library(lubridate)

# Load utility functions
source("usgs_gage_utils.r")

# Plotting -------------------------------------------------------------------

#' Plot Groundwater Depth Time Series
#'
#' Creates a standardized plot of groundwater depth below land surface
#' with loess smoothing and proper attribution.
#'
#' @param ts Tibble. Groundwater time series data with date and depth_bls_ft columns
#' @param site_no Character. USGS site number
#' @param smooth_span Numeric. Loess span parameter (default: 0.2)
#' @return ggplot object
plot_gw_depth <- function(ts, site_no, smooth_span = 0.2) {
  if(!nrow(ts)) stop("No groundwater data found for this site.")

  # Get site name
  st <- trySuppress(readNWISsite(site_no))
  site_name <- if(!inherits(st, "try-error") && nrow(st)) st$station_nm else site_no

  # Calculate period of record
  start_year <- year(min(ts$date, na.rm = TRUE))
  end_year <- year(max(ts$date, na.rm = TRUE))

  # Create title matching streamgage style
  title <- paste("Groundwater Levels at the", site_name, "USGS Gage\nPeriod of record:",
                 start_year, "to", end_year)

  # Create plot following style guide standards
  p <- ggplot(ts, aes(x = date, y = depth_bls_ft)) +
    geom_point(alpha = 0.7, size = 0.8) +
    geom_smooth(se = FALSE, method = "loess", span = smooth_span, linewidth = 1.2) +
    scale_y_reverse(name = "Depth below land surface/elevation (ft)") +
    labs(title = title) +
    xlab(standard_gage_attribution()) +
    theme_bw() +
    theme(
      axis.title.x = element_text(size = 8, hjust = 0)
    )

  p
}

# Interactive CLI ------------------------------------------------------------

#' Read User Input with Default
#'
#' Helper function for readline with default value support
read_with_default <- function(prompt, default = "") {
  ans <- readline(prompt)
  if(ans == "") default else ans
}

#' Choose Default Mode Based on Available Data
#'
#' Automatically selects the best mode based on what data is available
choose_default_mode <- function(info) {
  if(info$has_dv) return("daily_only")
  if(info$has_gwl) return("manual_only")
  return("daily_only")
}

#' Main Interactive Function
#'
#' Runs the interactive groundwater data retrieval and plotting workflow
run_groundwater_analysis <- function() {
  cat("
USGS Groundwater Retriever
---------------------------
")

  # Get site number
  site_no <- readline("Enter a USGS site (gage) number: ")
  site_no <- str_trim(site_no)
  if(site_no == "") stop("No site number provided.")

  # Check data availability
  cat("
Checking availability...
")
  info <- suggest_gw_options(site_no)
  if(!nrow(info$availability)) {
    cat("No groundwater-related data services found for site:", site_no, "
")
    return(invisible(NULL))
  }

  cat("
Available services at this site:
")
  print(info$summaries)

  # Select mode
  def_mode <- choose_default_mode(info)
  mode <- read_with_default(
    paste0("Choose mode [daily_only/manual_only] (default ", def_mode, "): "),
    def_mode
  )

  if(!mode %in% c("daily_only", "manual_only")) {
    cat("Unknown mode, using default ", def_mode, "
", sep = "")
    mode <- def_mode
  }

  # Get date range
  start_date <- readline("Start date (YYYY-MM-DD) or blank for earliest available: ")
  end_date   <- readline("End date   (YYYY-MM-DD) or blank for latest available:   ")

  # Fetch data
  cat("
Fetching data...
")
  ts <- fetch_gw_series(site_no, mode = mode, start_date = start_date, end_date = end_date)

  if(!nrow(ts)) {
    cat("No data returned for your selections.
")
    return(invisible(NULL))
  }

  # Plot
  cat("
Plotting...
")
  p <- plot_gw_depth(ts, site_no = site_no)
  print(p)

  # Save outputs
  stamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
  base <- paste0("usgs_gw_", site_no, "_", mode, "_", stamp)
  png_file <- file.path("./graphics", paste0(base, ".png"))
  csv_file <- file.path("./data", paste0(base, ".csv"))

  # Create directories if needed
  if(!dir.exists("./graphics")) {
    dir.create("./graphics")
  }
  if(!dir.exists("./data")) {
    dir.create("./data")
  }

  ggsave(png_file, plot = p, width = 9, height = 4.8, dpi = 160)
  write.csv(ts, csv_file, row.names = FALSE)

  cat("
Saved: ", png_file, " and ", csv_file, "
", sep = "")

  invisible(ts)
}

# Auto-run when sourced in interactive session
if(interactive()) {
  try(run_groundwater_analysis(), silent = FALSE)
}
