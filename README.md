# water-tools
John Fleck's water tools

generalflowjoyplot.r

Using USGS dataRetrieval interface, create joyplot of arbitrary USGS streamgauge daily discharge. This can provide insights into changes in streamflow seasonality over time, because of climate variability, climate change, and human interventions (dam operations, for example).

User inputs include gauge number and a "scale" factor that governs the relative height of the plots. "3" is a sane starting point. Larger numbers are needed to highlight highly variable systems.

leesferry.jpg

Sample image of flow at Lee's Ferry on the Colorado River. USGS gauge #09380000

gauge_this_year.r

For a specified gauge, downloads USGS data and plots current year in the context of historical data for this point in a year.

flow_threshold.r

For a specified gauge, downloads USGS data and calculates and displays the number of days in each year when flow dropped below a specified threshold.