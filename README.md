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
- `fetch_gage_streamflow()` - Standardized USGS daily streamflow data retrieval
- `fetch_gage_peak()` - Standardized USGS annual peak flow data retrieval
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

Interactive tool for retrieving and visualizing groundwater level data from USGS NWIS. Auto-discovers available data types at each site and prompts user for preferences. Supports two modes:
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

gage_annual_peak.r

Visualizes annual peak flows over time for a specified gage. Uses USGS peak flow data which represents the highest instantaneous flow each year. Displays peaks as points with data series start date. Uses utilities library with new fetch_gage_peak() function for standardized data retrieval and follows visualization conventions.
