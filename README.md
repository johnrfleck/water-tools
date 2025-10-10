# water-tools
John Fleck's water tools

October 2025: Major refactoring and modernization.
- Created usgs_gage_utils.r - reusable utility library for all gage analysis tools
- Refactored gauge_this_year.r to use utilities (49% code reduction)
- Auto-detection of current year (no more manual updates)
- Consistent visualization standards across all tools
- Uses USGS spelling "gage" not "gauge" (honoring stream gager tradition)

## usgs_gage_utils.r

Reusable utility functions for USGS stream gage analysis. All tools now use this library to ensure consistency and eliminate code duplication.

**Data Fetching:** `fetch_gage_streamflow()` - Standardized USGS data retrieval
**Analysis:** Percentiles, current year detection, split medians for climate context
**Visualization:** Standard colors, themes, attribution, month labels

Example gage numbers:
- 08330000 - Rio Grande at Albuquerque, NM
- 08313000 - Rio Grande at Otowi Bridge, NM
- 08332010 - Rio Grande Floodway near Bernardo, NM

---

## Tools

generalflowjoyplot.r

Using USGS dataRetrieval interface, create joyplot of arbitrary USGS streamgauge daily discharge. This can provide insights into changes in streamflow seasonality over time, because of climate variability, climate change, and human interventions (dam operations, for example).

User inputs include gauge number and a "scale" factor that governs the relative height of the plots. "3" is a sane starting point. Larger numbers are needed to highlight highly variable systems.

gauge_this_year.r

For a specified gauge, downloads USGS data and plots current year flow in the context of historical percentiles and medians. Auto-detects current year. Displays percentile bands (10th-90th, 30th-70th), period of record median, and split medians (1981-2000 vs 2001-present) for climate context.

flow_threshold.r

For a specified gage, counts days per year where flow is above or below a user-specified threshold. Prompts for threshold direction (above/below). Useful for drought monitoring (low-flow conditions) or flood analysis (high-flow events). Includes current year for real-time monitoring. Uses utilities library with 5-year x-axis breaks.

annual_gage.r

For a specified gage, downloads USGS data and displays annual flow in thousand acre-feet with mean reference line overlay. Excludes current incomplete year. Uses utilities library for consistent data fetching and visualization. X-axis shows 5-year interval breaks for better readability.

general_groundwater.r

Graph USGS data for a specified groundwater monitoring well.

gauge_daily_five_year_boxplot.r

Graph daily flow at selected gauge in five-year binned boxplots. Log scale, useful for high-variability gauges, especially in showing low flows

flow_threshold_above.r

Graph number of days above a specified flow. Required input: USGS gauge number

gauge_daily_five_year_violin_jitter.r

Violin plot of flow at specified gauge, using ggplot's "jitter" to better visualize variability.

gauge_to_date.r

Total flow at a gauge year to date.

gauge_annual_peak.r

Annual peak flow at specified gauge
