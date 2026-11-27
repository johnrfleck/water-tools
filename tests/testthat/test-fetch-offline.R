# Shape checks for the fetch helpers, run against saved sample data so they work
# offline. If USGS changes a column name or type, these fail loudly here
# instead of deep inside a plotting script.

test_that("fetch_gage_streamflow() returns Date, Year, DayOfYear and flow", {
  u <- load_utils(offline_stubs())
  res <- u$fetch_gage_streamflow("08330000", "2023-12-29", "2024-01-03")

  expect_named(res, c("data", "site_name", "site_number"))
  expect_equal(res$site_number, "08330000")
  expect_equal(res$site_name, "RIO GRANDE AT ALBUQUERQUE, NM")

  d <- res$data
  expect_true(all(c("Date", "Year", "DayOfYear", "flow") %in% names(d)))
  expect_s3_class(d$Date, "Date")
  expect_type(d$Year, "double")
  expect_type(d$DayOfYear, "double")
  expect_type(d$flow, "double")
})

test_that("streamflow values are derived correctly and sorted by date", {
  u <- load_utils(offline_stubs())
  d <- u$fetch_gage_streamflow("08330000")$data

  expect_false(is.unsorted(d$Date))
  expect_equal(d$flow[d$Date == as.Date("2023-12-30")], 520)
  expect_equal(d$DayOfYear[d$Date == as.Date("2023-12-31")], 365)
  expect_equal(d$DayOfYear[d$Date == as.Date("2024-01-01")], 1)
  expect_equal(d$Year[d$Date == as.Date("2024-01-01")], 2024)
})

test_that("fetch_gage_streamflow() sends the prefixed ID and discharge codes", {
  seen <- NULL
  stubs <- offline_stubs()
  stubs$read_waterdata_daily <- function(...) { seen <<- list(...); fixture("daily_abq.rds") }
  u <- load_utils(stubs)
  u$fetch_gage_streamflow("08330000", "2023-12-29", "2024-01-03")

  expect_equal(seen$monitoring_location_id, "USGS-08330000")
  expect_equal(seen$parameter_code, "00060")   # 00060 = discharge (flow)
  expect_equal(seen$statistic_id, "00003")     # 00003 = daily mean
  expect_equal(seen$time, c("2023-12-29", "2024-01-03"))
})

test_that("fetch_site_name() falls back to the site number when lookup fails", {
  stubs <- offline_stubs()
  stubs$read_waterdata_monitoring_location <- function(...) stop("network down")
  u <- load_utils(stubs)
  expect_equal(u$fetch_site_name("08330000"), "08330000")

  stubs$read_waterdata_monitoring_location <- function(...) fixture("location_abq.rds")[0, ]
  u <- load_utils(stubs)
  expect_equal(u$fetch_site_name("08330000"), "08330000")
})

test_that("fetch_gage_peak() returns peak_dt, peak_va, Year and filters by year", {
  u <- load_utils(offline_stubs())
  res <- u$fetch_gage_peak("08313000", start_date = "1900-01-01", end_date = "1903-12-31")
  d <- res$data

  expect_true(all(c("peak_dt", "peak_va", "Year") %in% names(d)))
  expect_s3_class(d$peak_dt, "Date")
  expect_type(d$peak_va, "double")
  expect_equal(d$Year, 1900:1903)
  expect_equal(d$peak_va[d$Year == 1903], 19700)
})

test_that("fetch_gage_peak() keeps peaks whose date is missing but year is known", {
  stubs <- offline_stubs()
  stubs$read_waterdata_peaks <- function(...) {
    p <- fixture("peaks_otowi.rds")[1:2, ]
    p$time[2] <- as.Date(NA)   # year known, day unknown
    p
  }
  u <- load_utils(stubs)
  d <- u$fetch_gage_peak("08313000")$data
  expect_equal(nrow(d), 2)
  expect_equal(d$Year, c(1895, 1896))
})
