# Percentile and split-median helpers, using small hand-built data whose
# answers are easy to verify by eye. No network.

u <- load_utils()

# Two day-of-year groups; flows 1..10 on day 1, constant 5 on day 2.
make_flow <- function() {
  tibble::tibble(
    DayOfYear = rep(c(1, 2), each = 10),
    flow = c(1:10, rep(5, 10))
  )
}

test_that("calculate_daily_percentiles() returns one row per day with expected columns", {
  p <- u$calculate_daily_percentiles(make_flow())
  expect_equal(nrow(p), 2)
  expect_named(p, c("DayOfYear", "Max", "Min", "Median", "P90", "P70", "P30", "P10"))
})

test_that("percentile values match base R quantile()", {
  p <- u$calculate_daily_percentiles(make_flow())
  d1 <- p[p$DayOfYear == 1, ]
  expect_equal(d1$Max, 10)
  expect_equal(d1$Min, 1)
  expect_equal(d1$Median, 5.5)
  expect_equal(unname(d1$P90), unname(quantile(1:10, 0.9)))
  expect_equal(unname(d1$P10), unname(quantile(1:10, 0.1)))
  expect_true(d1$P10 < d1$P30 && d1$P30 < d1$Median && d1$Median < d1$P70 && d1$P70 < d1$P90)
})

test_that("a constant day collapses all percentiles to that value", {
  p <- u$calculate_daily_percentiles(make_flow())
  d2 <- unlist(p[p$DayOfYear == 2, c("Max", "Min", "Median", "P90", "P70", "P30", "P10")])
  expect_true(all(d2 == 5))
})

test_that("NA flows are ignored", {
  df <- tibble::tibble(DayOfYear = 1, flow = c(1, 2, 3, NA))
  p <- u$calculate_daily_percentiles(df)
  expect_equal(p$Median, 2)
  expect_equal(p$Max, 3)
})

test_that("calculate_split_medians() separates 1981-2000 from 2001-present", {
  df <- tibble::tibble(
    Year = c(1990, 1995, 2005, 2010, 1970),
    DayOfYear = 1,
    flow = c(100, 200, 10, 30, 9999)   # 1970 is outside both windows
  )
  m <- u$calculate_split_medians(df)
  expect_named(m, c("DayOfYear", "Median_1981_2000", "Median_2001_present"))
  expect_equal(m$Median_1981_2000, 150)
  expect_equal(m$Median_2001_present, 20)
})

test_that("get_current_year_data() keeps only this year's rows", {
  this_year <- as.numeric(format(Sys.Date(), "%Y"))
  df <- tibble::tibble(Year = c(this_year - 1, this_year, this_year), flow = 1:3)
  out <- u$get_current_year_data(df)
  expect_equal(nrow(out), 2)
  expect_true(all(out$Year == this_year))
})
