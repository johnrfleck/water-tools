# Test runner. From the repo root, run:  Rscript tests/testthat.R
# (or in RStudio: testthat::test_dir("tests/testthat"))
library(testthat)
test_dir("tests/testthat", reporter = "progress")
