# water-tools
John Fleck's water tools

October 2025: Major refactoring and modernization.
- Created usgs_gage_utils.r - reusable utility library for all gage analysis tools
- Refactored gauge_this_year.r to use utilities (49% code reduction)
- Auto-detection of current year (no more manual updates)
- Consistent visualization standards across all tools
- Uses USGS spelling "gage" not "gauge" (honoring stream gager tradition)
- Added comprehensive groundwater data support with automatic data discovery
- Rewritten general_groundwater.R with modular design and improved data handling

## usgs_gage_utils.r

Reusable utility functions for USGS stream gage and groundwater analysis. All tools now use this library to ensure consistency and eliminate code duplication.

**Stream Gage Functions:**
- `fetch_gage_streamflow()` - Standardized USGS streamflow data retrieval
- Percentile calculations, current year detection, split medians for climate context

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

generalflowjoyplot.r

Using USGS dataRetrieval interface, create joyplot of arbitrary USGS streamgauge daily discharge. This can provide insights into changes in streamflow seasonality over time, because of climate variability, climate change, and human interventions (dam operations, for example).

User inputs include gauge number and a "scale" factor that governs the relative height of the plots. "3" is a sane starting point. Larger numbers are needed to highlight highly variable systems.

gage_this_year.R

For a specified gage, downloads USGS data and plots current year flow in the context of historical percentiles and medians. Auto-detects current year. Displays percentile bands (10th-90th, 30th-70th), period of record median, and split medians (1981-2000 vs 2001-present) for climate context.

flow_threshold.r

For a specified gage, counts days per year where flow is above or below a user-specified threshold. Prompts for threshold direction (above/below). Useful for drought monitoring (low-flow conditions) or flood analysis (high-flow events). Includes current year for real-time monitoring. Uses utilities library with 5-year x-axis breaks.

annual_gage.r

For a specified gage, downloads USGS data and displays annual flow in thousand acre-feet with mean reference line overlay. Excludes current incomplete year. Uses utilities library for consistent data fetching and visualization. X-axis shows 5-year interval breaks for better readability.

general_groundwater.R

Interactive tool for retrieving and visualizing groundwater level data from USGS NWIS. Auto-discovers available data types at each site and prompts user for preferences. Supports two modes:
- **daily_only** (default): Daily values showing depth below land surface
- **manual_only**: Manual field measurements

Features automatic date range detection, period-of-record display, loess smoothing overlay, and standardized visualization matching other water-tools. Saves both PNG graphics and CSV data files. Uses utilities library for consistent data fetching and visualization standards.

gauge_daily_five_year_boxplot.r

Graph daily flow at selected gauge in five-year binned boxplots. Log scale, useful for high-variability gauges, especially in showing low flows

gauge_daily_five_year_violin_jitter.r

Violin plot of flow at specified gauge, using ggplot's "jitter" to better visualize variability.

gage_to_date.R

For a specified gage, calculates total flow accumulated from January 1 to current date for all years in historical record. Filters all years to same day-of-year for fair comparison. Includes current year for real-time monitoring. Useful for tracking wet/dry years. Uses utilities library with 5-year x-axis breaks.

gauge_annual_peak.r

Annual peak flow at specified gauge
