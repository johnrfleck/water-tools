# Loads usgs_gage_utils.r into an isolated environment for the tests.
#
# Plain language: the utils file calls the USGS web service. For offline tests
# we put stand-in ("stub") versions of the read_waterdata_*() functions in that
# environment, so the helpers pick up saved sample data instead of the network.

repo_root <- function() {
  # testthat runs with the working directory set to tests/testthat
  normalizePath(file.path(testthat::test_path(), "..", ".."))
}

fixture <- function(name) readRDS(testthat::test_path("fixtures", name))

#' Source the utils into a fresh environment, optionally with stubbed USGS calls
load_utils <- function(stubs = list()) {
  env <- new.env(parent = globalenv())
  suppressPackageStartupMessages(
    sys.source(file.path(repo_root(), "usgs_gage_utils.r"), envir = env)
  )
  for (nm in names(stubs)) assign(nm, stubs[[nm]], envir = env)
  env
}

#' Stubs that return the saved Albuquerque / Otowi sample data
offline_stubs <- function() {
  list(
    read_waterdata_daily = function(...) fixture("daily_abq.rds"),
    read_waterdata_monitoring_location = function(...) fixture("location_abq.rds"),
    read_waterdata_peaks = function(...) fixture("peaks_otowi.rds")
  )
}
