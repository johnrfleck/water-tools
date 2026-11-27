# Groundwater normalizers turn new-API output (monitoring_location_id, time,
# value) into the tidy columns the groundwater script uses. Built from small
# hand-made frames; no network.

u <- load_utils()

test_that(".normalize_dv() strips the USGS- prefix and drops missing readings", {
  df <- tibble::tibble(
    monitoring_location_id = "USGS-350534106354703",
    time = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")),
    value = c(55.2, NA, 55.4)
  )
  out <- u$.normalize_dv(df)
  expect_named(out, c("site_no", "date_time", "date", "depth_bls_ft", "source", "tz"))
  expect_equal(nrow(out), 2)
  expect_equal(unique(out$site_no), "350534106354703")
  expect_equal(unique(out$source), "dv")
  expect_equal(out$depth_bls_ft, c(55.2, 55.4))
})

test_that(".normalize_gwl() handles manual field measurements", {
  df <- tibble::tibble(
    monitoring_location_id = "USGS-350534106354703",
    time = as.POSIXct(c("2020-05-01 15:30:00", "2021-05-01 15:30:00"), tz = "UTC"),
    value = c(60.1, 61.7)
  )
  out <- u$.normalize_gwl(df)
  expect_equal(out$source, c("gwl", "gwl"))
  expect_equal(out$date, as.Date(c("2020-05-01", "2021-05-01")))
  expect_equal(out$depth_bls_ft, c(60.1, 61.7))
})

test_that("the %||% helper falls back for NULL, empty and blank values", {
  expect_equal(u$`%||%`(NULL, "x"), "x")
  expect_equal(u$`%||%`(character(0), "x"), "x")
  expect_equal(u$`%||%`("", "x"), "x")
  expect_equal(u$`%||%`("a", "x"), "a")
})
