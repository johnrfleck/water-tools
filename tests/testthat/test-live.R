# Optional live checks against the real USGS service (Albuquerque and Otowi
# gages). They are SKIPPED by default so the normal test run stays offline and
# fast. To run them:
#
#   WATER_TOOLS_LIVE=true Rscript tests/testthat.R
#
# Plain language: these confirm USGS is still answering in the format our
# helpers expect. They are small requests (a week of data), but an occasional
# USGS hiccup can make them fail without it being our bug.

skip_if_not_live <- function() {
  testthat::skip_if(Sys.getenv("WATER_TOOLS_LIVE") != "true",
                    "Set WATER_TOOLS_LIVE=true to run live USGS checks")
}

test_that("live: Albuquerque daily flow has the expected shape", {
  skip_if_not_live()
  u <- load_utils()
  res <- u$fetch_gage_streamflow("08330000", "2024-01-01", "2024-01-07")
  expect_equal(nrow(res$data), 7)
  expect_true(all(c("Date", "Year", "DayOfYear", "flow") %in% names(res$data)))
  expect_true(all(res$data$flow > 0, na.rm = TRUE))
  expect_match(res$site_name, "ALBUQUERQUE", ignore.case = TRUE)
})

test_that("live: Otowi annual peaks include the 1895 start of record", {
  skip_if_not_live()
  u <- load_utils()
  res <- u$fetch_gage_peak("08313000", start_date = "1895-01-01", end_date = "1905-12-31")
  expect_true(all(c("peak_dt", "peak_va", "Year") %in% names(res$data)))
  expect_true(1895 %in% res$data$Year)
  expect_match(res$site_name, "OTOWI", ignore.case = TRUE)
})
