# water-tools
John Fleck's water tools: R scripts for looking at USGS stream gage and groundwater data, plus Middle Rio Grande Conservancy District (MRGCD) gage data from the U.S. Bureau of Reclamation (USBR).

Each script is interactive: run it in R or RStudio and it prompts for a gage number (or other options), downloads the data, and draws a plot. Plots are saved to `./graphics/` with a date in the file name.

## Setup

1. Install R, then the packages the scripts use:

   ```r
   install.packages(c("dataRetrieval", "tidyverse", "lubridate", "scales", "ggridges"))
   ```

   `dataRetrieval` needs to be a **recent release**. The new USGS functions (`read_waterdata_*`, including `read_waterdata_peaks()`) only exist in newer versions. If something says a function "could not be found", run `install.packages("dataRetrieval")` again.
2. Open `water-tools.Rproj` (or set your working directory to this folder), because the scripts load the shared library with `source("./usgs_gage_utils.r")`.
3. Optional: get a free USGS API key (sign up through the USGS Water Data API site, api.waterdata.usgs.gov) and set it as the `API_USGS_PAT` environment variable (for example, add `API_USGS_PAT=your-key` to your `~/.Renviron` file and restart R). Without a key everything still works, but USGS limits how many requests you can make per hour. A key raises that limit, which matters if you run several scripts back to back or pull long records.

## What changed (and why it matters)

**November 2026: new USGS Water Data API.** USGS is retiring its old NWIS web services (the `readNWIS*` functions in `dataRetrieval`; "NWIS" is the National Water Information System). The shared helpers and the groundwater and peak-flow scripts now use the replacement, the USGS Water Data API (an OGC API, which is just a modern, standardized way for programs to ask USGS for data), through these `dataRetrieval` functions:

| Data | Function |
|---|---|
| Daily mean flow, daily groundwater values | `read_waterdata_daily()` |
| Station names and details | `read_waterdata_monitoring_location()` |
| Manual groundwater measurements | `read_waterdata_field_measurements()` |
| Which data series exist at a site | `read_waterdata_ts_meta()` |
| Annual peak flows | `read_waterdata_peaks()` |

Two practical consequences:

- **Site IDs carry a `"USGS-"` prefix** in the new API (`"USGS-08330000"` instead of `"08330000"`). You do not need to change how you type gage numbers: the helper `usgs_site_id()` adds the prefix for you, and leaves IDs that already have one alone.
- **Column names differ** in the raw data (date is `time`, the reading is `value`). `fetch_gage_streamflow()` and `fetch_gage_peak()` translate these back to the names the plotting scripts have always used (`Date`, `Year`, `DayOfYear`, `flow`; `peak_dt`, `peak_va`), so the scripts did not need to change.

**October 2025: major refactoring and modernization.**
- Created `usgs_gage_utils.r`, a reusable utility library for all gage analysis tools
- Refactored `gage_this_year.R` to use the utilities (49% code reduction)
- Auto-detection of current year (no more manual updates)
- Consistent visualization standards across all tools
- Uses USGS spelling "gage" not "gauge" (honoring stream gager tradition)
- Added comprehensive groundwater data support with automatic data discovery
- Rewrote `general_groundwater.R` with modular design and improved data handling

## usgs_gage_utils.r

Reusable utility functions for USGS stream gage and groundwater analysis. All tools now use this library to ensure consistency and eliminate code duplication.

**Data source:** daily flow, site names, peak flows and groundwater all come from the new USGS Water Data API via the `read_waterdata_*` functions in the `dataRetrieval` package (see Setup above for the version requirement and the optional `API_USGS_PAT` key).

**Stream Gage Functions:**
- `fetch_gage_streamflow()` - Standardized USGS daily streamflow data retrieval (returns a list: `data` with `Date`, `Year`, `DayOfYear`, `flow`; plus `site_name` and `site_number`)
- `fetch_gage_peak()` - Standardized USGS annual peak flow data retrieval (`peak_dt`, `peak_va`, `Year`)
- `fetch_site_name()` and `usgs_site_id()` - station-name lookup and the `"USGS-"` ID helper
- `calculate_daily_percentiles()`, `get_current_year_data()`, `calculate_split_medians()` - percentile bands (the range of flows that usually occur on each calendar day), current-year filtering, and 1981-2000 vs. 2001-present medians for climate context

**Groundwater Functions:**
- `suggest_gw_options()` - Auto-discover available groundwater data at a site
- `fetch_gw_series()` - Retrieve groundwater levels (daily or manual measurements)
- Normalizers for handling different USGS groundwater data formats

**Visualization:** Standard colors, themes, attribution (with GitHub link), month labels

Example gage numbers:
- 08330000 - Rio Grande at Albuquerque, NM
- 08313000 - Rio Grande at Otowi Bridge, NM
- 08332010 - Rio Grande Floodway near Bernardo, NM

---

## Tools

gage_ridgeplot.r

Creates ridge plot (formerly called "joyplot") visualization of daily discharge patterns over time. Useful for identifying changes in streamflow seasonality due to climate variability, climate change, and human interventions (dam operations, diversions, etc.).

Prompts for gage number and scale factor. Scale factor controls vertical spacing/overlap of ridges - "3" is a good starting point. Larger numbers create more overlap, useful for highlighting highly variable systems. Uses utilities library for data fetching and follows standardized visualization conventions. Updated to use modern ggridges package with readable 5-year y-axis intervals.

gage_this_year.R

For a specified gage, downloads USGS data and plots current year flow in the context of historical percentiles and medians. Auto-detects current year. Displays percentile bands (10th-90th, 30th-70th), period of record median, and split medians (1981-2000 vs 2001-present) for climate context.

MRGCD_gage.R

For a specified MRGCD gage identifier, downloads 30-minute MRGCD-USBR Middle Rio Grande archive data and plots current year flow in the context of historical percentile bands and the period-of-record median. Prompts for a high-flow cutoff value to mask spurious readings before aggregating to daily mean flow. Always downloads current data from USBR rather than using a local cache.

flow_threshold.r

For a specified gage, counts days per year where flow is above or below a user-specified threshold. Prompts for threshold direction (above/below). Useful for drought monitoring (low-flow conditions) or flood analysis (high-flow events). Includes current year for real-time monitoring. Uses utilities library with 5-year x-axis breaks.

annual_gage.r

For a specified gage, downloads USGS data and displays annual flow in thousand acre-feet with mean reference line overlay. Excludes current incomplete year. Uses utilities library for consistent data fetching and visualization. X-axis shows 5-year interval breaks for better readability.

general_groundwater.R

Interactive tool for retrieving and visualizing groundwater level data from the USGS Water Data API. Auto-discovers available data types at each site and prompts user for preferences. Supports two modes:
- **daily_only** (default): Daily values showing depth below land surface
- **manual_only**: Manual field measurements

Features automatic date range detection, period-of-record display, loess smoothing overlay, and standardized visualization matching other water-tools. Saves both PNG graphics and CSV data files. Uses utilities library for consistent data fetching and visualization standards.

gage_daily_five_year_boxplot.r

Creates boxplot visualization of daily flows grouped into five-year periods. Useful for visualizing flow variability and changes over time. Uses linear scale with angled x-axis labels for readability. Uses utilities library for data fetching and follows standardized visualization conventions.

gage_annual_boxplot.r

Creates boxplot visualization of daily flows for each individual year. Shows year-to-year flow variability with one boxplot per year. X-axis labels every 5th year for readability, with smaller outlier points to reduce clutter. Useful for seeing detailed annual patterns and trends over long time periods. Uses utilities library and standardized visualization conventions.

gage_daily_five_year_violin_jitter.r

Creates violin plot with jitter overlay of daily flows grouped into five-year periods. Uses log scale to better visualize flow variability, particularly at low flows. Shows both distribution shape (violin) and individual data points (jitter). Y-axis uses comma formatting (not exponential notation) for readability on log scale. Uses utilities library for data fetching and follows standardized visualization conventions.

gage_to_date.R

For a specified gage, calculates total flow accumulated from January 1 to current date for all years in historical record. Filters all years to same day-of-year for fair comparison. Includes current year for real-time monitoring. Useful for tracking wet/dry years. Uses utilities library with 5-year x-axis breaks.

nov_flow_summary.r

A one-off (not interactive) analysis from December 2025: totals the 2025 flow, in acre-feet, at four Rio Grande gages (Cochiti, the San Marcial floodway and conveyance channel, and Elephant Butte Narrows) and draws a bar chart. It was written to evaluate how efficiently water was moved late in the season. Gage numbers and the date range are set at the top of the script, so edit them to reuse it for another year or set of gages. Uses `fetch_gage_streamflow()` from the utilities library.

gage_annual_peak.r

Visualizes annual peak flows over time for a specified gage. Uses USGS peak flow data which represents the highest instantaneous flow each year. Displays peaks as points with data series start date. Uses utilities library with new fetch_gage_peak() function for standardized data retrieval and follows visualization conventions.

---

## Tests

Automated checks (using the `testthat` package) cover the shared helpers in `usgs_gage_utils.r`:

- the `"USGS-"` site-ID helper;
- the shape of what `fetch_gage_streamflow()` and `fetch_gage_peak()` return (the `Date`, `Year`, `DayOfYear`, `flow` columns and so on);
- the percentile and split-median calculations;
- the groundwater data normalizers.

To run them from this folder (install the test package once with `install.packages("testthat")`):

```
Rscript tests/testthat.R
```

or, in RStudio, `testthat::test_dir("tests/testthat")`.

**They run offline.** The fetch tests use small saved samples of real USGS responses ("fixtures", in `tests/testthat/fixtures/`) in place of the network, so they are fast and do not depend on USGS being up. The point is to catch breakage if USGS changes its data format: if a column is renamed, a test fails here, rather than a plot quietly breaking later. To refresh the saved samples, run `Rscript tests/make_fixtures.R` (needs internet).

**Optional live checks** call the real USGS service for the Albuquerque (08330000) and Otowi Bridge (08313000) gages. They are skipped unless you ask for them:

```
WATER_TOOLS_LIVE=true Rscript tests/testthat.R
```

These confirm USGS is still answering in the format the helpers expect. An occasional failure may just be a USGS outage rather than a bug.
