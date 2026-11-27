# usgs_site_id(): adds the "USGS-" prefix the new API requires.
# (Plain language: the new USGS service wants "USGS-08330000", not "08330000".)

u <- load_utils()

test_that("bare site numbers get the USGS- prefix", {
  expect_equal(u$usgs_site_id("08330000"), "USGS-08330000")
  expect_equal(u$usgs_site_id(8330000), "USGS-8330000")  # numeric input is coerced
})

test_that("IDs that already have an agency prefix are left alone", {
  expect_equal(u$usgs_site_id("USGS-08330000"), "USGS-08330000")
  expect_equal(u$usgs_site_id("  08313000 "), "USGS-08313000")  # whitespace trimmed
})

test_that("it is vectorized", {
  expect_equal(u$usgs_site_id(c("08330000", "USGS-08313000")),
               c("USGS-08330000", "USGS-08313000"))
})
