# Unit Testing Recommendations for water-tools

**Analysis Date:** October 26, 2025
**Analyzed By:** Claude Code Review

---

## Executive Summary

**Recommendation: YES, unit tests would be highly valuable for this project.**

The `usgs_gage_utils.r` library (500 lines) is a critical shared dependency used by all 11 analysis scripts. Unit tests would prevent regressions, enable confident refactoring, and ensure reliability for water resource management decisions.

**Focus Area:** Test the utility library functions, not the interactive scripts or external API calls.

**Estimated Effort:** 2-4 hours to create comprehensive test suite

---

## Why Unit Tests Make Sense

### 1. Critical Shared Utility Library
The `usgs_gage_utils.r` is a **single point of failure** - all 11 analysis scripts depend on it. Bugs in this library affect the entire toolkit.

### 2. Complex Data Processing Logic
The library contains calculation functions with edge cases:
- Percentile calculations across grouped data
- Date/time manipulations and year filtering
- Data normalization across 3 different USGS formats (gwl, dv, uv)
- Null handling and parameter prioritization

### 3. Recent Modernization
October 2025 refactoring created this shared library. Unit tests would:
- Prevent regressions during future improvements
- Document expected behavior of new abstractions
- Enable confident refactoring

### 4. High-Value Domain
Water resource management decisions rely on accurate data analysis. Testing ensures reliability for scientific work.

---

## Recommended Testing Approach

### Framework: `testthat`
R's standard testing framework - simple, well-documented, RStudio-integrated.

### Project Structure
```
water-tools/
├── usgs_gage_utils.r           # Core library (existing)
├── tests/
│   ├── testthat.R              # Test runner
│   └── testthat/
│       ├── test-calculations.R      # Percentile, median calculations
│       ├── test-helpers.R           # Null coalescing, normalizers
│       ├── test-visualization.R     # Colors, themes, attribution
│       └── test-file-ops.R          # File saving, directory creation
```

---

## What TO Test (High Value)

### 1. Pure Calculation Functions ✅

#### `calculate_daily_percentiles()` (usgs_gage_utils.r:325)
- **Test:** Correct percentile values (10th, 30th, 50th, 70th, 90th, min, max)
- **Edge cases:**
  - NA values in flow data
  - Single-day data
  - Empty groups
  - Verify percentile ordering (P10 ≤ P30 ≤ Median ≤ P70 ≤ P90)

#### `calculate_split_medians()` (usgs_gage_utils.r:370)
- **Test:** Correct medians for 1981-2000 vs 2001-present periods
- **Edge cases:**
  - Missing years in either period
  - Incomplete periods (e.g., only 1985-1990 available)
  - Data spanning only one period

#### `get_current_year_data()` (usgs_gage_utils.r:354)
- **Test:** Filters to current year correctly
- **Edge cases:**
  - Empty input data
  - Year boundary conditions (January 1, December 31)
  - No data for current year

### 2. Helper/Utility Functions ✅

#### `%||%` null coalescing operator (usgs_gage_utils.r:116)
- **Test:** Returns left value if not null/empty, otherwise right value
- **Edge cases:**
  - NULL
  - Empty string ("")
  - Empty vector (character(0))
  - Zero (0) - should NOT be treated as null
  - FALSE - should NOT be treated as null

#### Data Normalizers (usgs_gage_utils.r:137-179)
- `.normalize_gwl()` - Manual groundwater level measurements
- `.normalize_dv()` - Daily value groundwater data
- `.normalize_uv()` - Unit/instantaneous value groundwater data

**Tests:**
- Correct column mapping and renaming
- Type conversion (character to numeric, date handling)
- Timezone handling
- NA filtering
- Edge cases: Missing required columns, all-NA values

### 3. Visualization Configuration ✅

#### `gage_percentile_colors()` (usgs_gage_utils.r:407)
- **Test:** Returns correct named vector with blue/green colors

#### `gage_line_colors()` (usgs_gage_utils.r:420)
- **Test:** Returns 4-color named vector
- **Test:** Current year label auto-detection
- **Test:** Custom year parameter

#### `month_axis_scale()` (usgs_gage_utils.r:436)
- **Test:** Returns scale_x_continuous object
- **Test:** 12 breaks at correct day-of-year positions
- **Test:** Month abbreviation labels

#### `standard_gage_attribution()` (usgs_gage_utils.r:397)
- **Test:** Returns expected multi-line string
- **Test:** Contains USGS, Utton Center, GitHub URL

### 4. File Operations ✅

#### `save_dated_gage_plot()` (usgs_gage_utils.r:477)
- **Test:** Creates correct filename format (YYYY-MM-DD-prefix.png)
- **Test:** Creates ./graphics/ directory if missing
- **Test:** Returns invisible file path
- **Edge cases:**
  - Special characters in prefix
  - Existing file (should overwrite)
  - Verify file actually created with correct dimensions

---

## What NOT to Test (Low Value)

### 1. External API Calls ❌

**Functions to skip:**
- `fetch_gage_streamflow()` (usgs_gage_utils.r:35)
- `fetch_gage_peak()` (usgs_gage_utils.r:87)
- `fetch_gw_series()` (usgs_gage_utils.r:251)
- `suggest_gw_options()` (usgs_gage_utils.r:197)

**Reason:** Depend on USGS NWIS API availability and network connectivity

**Alternative:** Could add **integration tests** (separate from unit tests) or use mock/fixture data to test data processing logic without hitting the API

### 2. Interactive Scripts ❌

**Scripts to skip:**
- `gage_this_year.R`
- `gage_ridgeplot.r`
- `gage_annual_peak.r`
- All other 11 analysis scripts

**Reason:** Designed for manual use with user prompts (`readline()`)

**Alternative:** Manual testing checklist or end-to-end integration tests

### 3. Third-Party Package Functions ❌

**Don't test:**
- tidyverse/dplyr functions
- ggplot2 rendering
- dataRetrieval package functions

**Reason:** Assume well-tested packages work correctly

---

## Example Test File

**File:** `tests/testthat/test-calculations.R`

```r
library(testthat)
library(tidyverse)
library(lubridate)
source("../../usgs_gage_utils.r")

test_that("calculate_daily_percentiles returns correct structure", {
  # Create test data: 3 days with 10 observations each
  test_data <- tibble(
    DayOfYear = rep(1:3, each = 10),
    flow = c(
      runif(10, 100, 200),  # Day 1
      runif(10, 150, 250),  # Day 2
      runif(10, 80, 180)    # Day 3
    )
  )

  result <- calculate_daily_percentiles(test_data)

  # Check structure
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_named(result, c("DayOfYear", "Max", "Min", "Median", "P90", "P70", "P30", "P10"))

  # Check percentile ordering for each day
  expect_true(all(result$Min <= result$P10))
  expect_true(all(result$P10 <= result$P30))
  expect_true(all(result$P30 <= result$Median))
  expect_true(all(result$Median <= result$P70))
  expect_true(all(result$P70 <= result$P90))
  expect_true(all(result$P90 <= result$Max))
})

test_that("calculate_daily_percentiles handles NA values", {
  test_data <- tibble(
    DayOfYear = rep(1, 10),
    flow = c(100, 200, NA, 300, NA, 400, 500, NA, 600, 700)
  )

  result <- calculate_daily_percentiles(test_data)

  # Should compute stats ignoring NAs
  expect_false(is.na(result$Median))
  expect_equal(result$Min, 100)
  expect_equal(result$Max, 700)
})

test_that("null coalescing operator works correctly", {
  expect_equal(NULL %||% "default", "default")
  expect_equal("value" %||% "default", "value")
  expect_equal("" %||% "default", "default")
  expect_equal(character(0) %||% "default", "default")
  expect_equal(0 %||% 99, 0)  # Zero is not null
  expect_equal(FALSE %||% TRUE, FALSE)  # FALSE is not null
})

test_that("get_current_year_data filters correctly", {
  current_year <- year(Sys.Date())
  test_data <- tibble(
    Year = c(2022, 2023, current_year, current_year),
    flow = c(100, 150, 200, 250),
    Date = as.Date(c("2022-01-01", "2023-01-01",
                     paste0(current_year, "-01-01"),
                     paste0(current_year, "-06-15")))
  )

  result <- get_current_year_data(test_data)

  expect_equal(nrow(result), 2)
  expect_true(all(result$Year == current_year))
  expect_equal(result$flow, c(200, 250))
})

test_that("get_current_year_data handles empty data", {
  test_data <- tibble(
    Year = c(2020, 2021, 2022),
    flow = c(100, 150, 200)
  )

  # If current year is not in data, should return empty tibble
  current_year <- year(Sys.Date())
  if (!current_year %in% test_data$Year) {
    result <- get_current_year_data(test_data)
    expect_equal(nrow(result), 0)
  }
})

test_that("calculate_split_medians produces correct periods", {
  # Create test data spanning both periods
  test_data <- tibble(
    Year = rep(1985:2010, each = 365),
    DayOfYear = rep(1:365, times = 26),
    flow = runif(365 * 26, 50, 500)
  )

  result <- calculate_split_medians(test_data)

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 365)
  expect_true("Median_1981_2000" %in% names(result))
  expect_true("Median_2001_present" %in% names(result))

  # All medians should be positive (given our test data)
  expect_true(all(result$Median_1981_2000 > 0, na.rm = TRUE))
  expect_true(all(result$Median_2001_present > 0, na.rm = TRUE))
})

test_that("standard_gage_attribution returns expected text", {
  attribution <- standard_gage_attribution()

  expect_type(attribution, "character")
  expect_true(grepl("USGS", attribution))
  expect_true(grepl("Utton Center", attribution))
  expect_true(grepl("github.com/johnrfleck/water-tools", attribution))
})

test_that("gage_percentile_colors returns correct colors", {
  colors <- gage_percentile_colors()

  expect_type(colors, "character")
  expect_length(colors, 2)
  expect_named(colors, c("10th to 90th percentile", "30th to 70th percentile"))
  expect_equal(unname(colors), c("blue", "green"))
})

test_that("gage_line_colors returns correct structure", {
  colors <- gage_line_colors()

  expect_type(colors, "character")
  expect_length(colors, 4)
  expect_true("Period of record median" %in% names(colors))
  expect_true("Median 1981-2000" %in% names(colors))
  expect_true("Median 2001-Present" %in% names(colors))

  # Should auto-detect current year in fourth label
  current_year <- year(Sys.Date())
  expect_true(any(grepl(as.character(current_year), names(colors))))
})

test_that("gage_line_colors accepts custom year", {
  colors <- gage_line_colors(current_year = 2023)

  expect_true("Flow 2023" %in% names(colors))
})
```

**File:** `tests/testthat/test-file-ops.R`

```r
library(testthat)
library(ggplot2)
source("../../usgs_gage_utils.r")

test_that("save_dated_gage_plot creates correct filename", {
  # Create a simple test plot
  p <- ggplot(data.frame(x = 1:10, y = 1:10), aes(x, y)) + geom_point()

  # Save in temporary directory for testing
  old_wd <- getwd()
  temp_dir <- tempdir()
  setwd(temp_dir)

  tryCatch({
    filepath <- save_dated_gage_plot(p, "test-plot", width = 8, height = 5)

    # Check filename format
    expected_date <- format(Sys.Date(), "%Y-%m-%d")
    expected_filename <- sprintf("%s-test-plot.png", expected_date)
    expect_true(grepl(expected_filename, filepath))

    # Check file exists
    expect_true(file.exists(filepath))

    # Check graphics directory was created
    expect_true(dir.exists("./graphics"))

    # Cleanup
    unlink("./graphics", recursive = TRUE)
  }, finally = {
    setwd(old_wd)
  })
})
```

**File:** `tests/testthat.R`

```r
library(testthat)
library(tidyverse)
library(lubridate)

test_check("water-tools")
```

---

## Implementation Steps

### 1. Install testthat
```r
install.packages("testthat")
```

### 2. Initialize test structure
```r
# If using usethis package
install.packages("usethis")
usethis::use_testthat()

# Or manually create:
# - tests/testthat.R
# - tests/testthat/ directory
```

### 3. Write tests incrementally
Start with simple helpers and visualization functions, then move to complex calculations.

**Recommended order:**
1. `test-helpers.R` - Null coalescing, simple utilities
2. `test-visualization.R` - Color schemes, themes, attribution
3. `test-calculations.R` - Percentiles, medians, filtering
4. `test-file-ops.R` - File saving functions

### 4. Run tests
```r
# From R console
devtools::test()

# Or in RStudio: Ctrl+Shift+T (Windows/Linux) or Cmd+Shift+T (Mac)

# Run specific test file
testthat::test_file("tests/testthat/test-calculations.R")
```

### 5. Aim for 70-80% coverage
Focus on testing the utility library, not achieving 100% coverage. Prioritize:
- Functions with complex logic
- Functions used by multiple scripts
- Functions handling edge cases

---

## Benefits Summary

### Immediate Benefits
- ✅ Catch bugs before they affect 11 dependent scripts
- ✅ Document expected behavior through executable examples
- ✅ Verify edge cases in date handling and data normalization

### Long-term Benefits
- ✅ Enable safe refactoring and future improvements
- ✅ Prevent regressions when adding new features
- ✅ Professional quality for open-source scientific software
- ✅ Easier onboarding for contributors

### Risk Mitigation
- ✅ Reduce risk of incorrect hydrological analysis
- ✅ Increase confidence in data processing pipeline
- ✅ Provide safety net for ongoing modernization efforts

---

## Coverage Goal

**Target:** 70-80% line coverage of `usgs_gage_utils.r`

**Priority Functions (must test):**
1. `calculate_daily_percentiles()`
2. `calculate_split_medians()`
3. `get_current_year_data()`
4. `%||%` operator
5. Data normalizers (`.normalize_*`)
6. `save_dated_gage_plot()`

**Lower Priority (optional):**
- Visualization config functions (simple, low risk)
- Theme application functions

**Skip:**
- API fetching functions (external dependency)
- Interactive script files

---

## Maintenance

### When to Update Tests
- Adding new utility functions
- Modifying calculation logic
- Changing data structures
- Fixing bugs (add regression test)

### Continuous Testing
Consider setting up:
- Pre-commit hooks to run tests
- GitHub Actions for automated testing
- Test coverage reporting

---

## Questions or Concerns?

### "This seems like overhead for analysis scripts"
Unit tests are more valuable here than in typical analysis scripts because:
- Shared utility library affects all tools
- Scientific accuracy is critical
- Recent refactoring created reusable abstractions worth protecting

### "I don't have time for this"
Start small:
- Week 1: Test helpers and simple functions (1 hour)
- Week 2: Test core calculations (1 hour)
- Week 3: Test file operations (30 min)

Even partial coverage provides value.

### "What about API testing?"
For `fetch_*` functions, consider:
- **Unit tests with mocks:** Test data processing logic separately
- **Integration tests:** Occasional manual verification against live API
- **Fixture data:** Save sample USGS responses for offline testing

---

## Conclusion

Unit testing the `usgs_gage_utils.r` library is **highly recommended**. The modest time investment (2-4 hours) provides significant value:

- Protects critical shared infrastructure
- Enables confident modernization
- Ensures scientific reliability
- Demonstrates professional software engineering practices

**Next Step:** Implement the test suite using the examples provided above.

---

**Contact:** John Fleck, Utton Center, University of New Mexico School of Law
**Repository:** https://github.com/johnrfleck/water-tools
**License:** MIT License (2025)
