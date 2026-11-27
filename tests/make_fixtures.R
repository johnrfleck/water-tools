# Regenerates the saved sample data (fixtures) used by the offline tests.
# Run from the repo root:  Rscript tests/make_fixtures.R
# Requires network access. Only needed if USGS changes its response format
# and you want the fixtures to reflect the new shape.
suppressMessages({library(dataRetrieval); library(dplyr)})
dir <- "tests/testthat/fixtures"
dir.create(dir, recursive = TRUE, showWarnings = FALSE)
strip <- function(x) { attr(x, "request") <- NULL; attr(x, "queryTime") <- NULL; x }

# Daily mean discharge, Rio Grande at Albuquerque, across a year boundary
daily <- read_waterdata_daily(
  monitoring_location_id = "USGS-08330000", parameter_code = "00060",
  statistic_id = "00003", time = c("2023-12-29", "2024-01-03"), skipGeometry = TRUE)
saveRDS(strip(daily), file.path(dir, "daily_abq.rds"))

# Station metadata
loc <- read_waterdata_monitoring_location(
  monitoring_location_id = "USGS-08330000", skipGeometry = TRUE)
saveRDS(strip(loc), file.path(dir, "location_abq.rds"))

# Annual peaks, Rio Grande at Otowi Bridge (first 12 years)
peaks <- read_waterdata_peaks(
  monitoring_location_id = "USGS-08313000", parameter_code = "00060", skipGeometry = TRUE)
saveRDS(strip(head(peaks, 12)), file.path(dir, "peaks_otowi.rds"))
