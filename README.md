# water-tools
John Fleck's water tools

generalflowjoyplot.r

Using USGS dataRetrieval interface, create joyplot of arbitrary USGS streamgauge daily discharge. This can provide insights into changes in streamflow seasonality over time, because of climate variability, climate change, and human interventions (dam operations, for example).

User inputs include gauge number and a "scale" factor that governs the relative height of the plots. "3" is a sane starting point. Larger numbers are needed to highlight highly variable systems.

gauge_this_year.r

For a specified gauge, downloads USGS data and plots current year in the context of historical data for this point in a year.

flow_threshold.r

For a specified gauge, downloads USGS data and calculates and displays the number of days in each year when flow dropped below a specified threshold.

annual_gauge.r

For a specified gauge, downloads USGS data and calculates and displays annual flow, in acre feet, along with mean and median.

general_groundwater.r

Graph USGS data for a specified groundwater monitoring well.

gauge_daily_five_year_boxplot.r

Graph daily flow at selected gauge in five-year binned boxplots. Log scale, useful for high-variability gauges, especially in showing low flows

flow_threshold_above.f

Graph number of days above a specified flow. Required input: USGS gauge number

gauge_daily_five_year_violin_jitter.r

Violin plot of flow at specified gauge, using ggplot's "jitter" to better visualize variability.