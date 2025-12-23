# One-off analysis: Rio Grande flow totals for 2025
# Downloads and sums flow from 4 gage locations
# Purpose: to evaluate efficiency of late season movement of 
# Prior and Paramount water
# Done Dec. 23, 2025
# John Fleck, Utton Center, University of New Mexico School of Law

source("./usgs_gage_utils.r")

# Gage numbers
cochiti <- "08317400"
san_marcial_floodway <- "08358400"
san_marcial_conveyance <- "08358300"
elephant_butte_narrows <- "08359500"

# Date range: Entire calendar year 2025 change this date as needed
start_date <- "2025-01-01"
end_date <- Sys.Date()

# Fetch data for each gage
cat("Fetching Cochiti data...\n")
cochiti_data <- fetch_gage_streamflow(cochiti, start_date, end_date)

cat("Fetching San Marcial Floodway data...\n")
sm_floodway_data <- fetch_gage_streamflow(san_marcial_floodway, start_date, end_date)

cat("Fetching San Marcial Conveyance Channel data...\n")
sm_conveyance_data <- fetch_gage_streamflow(san_marcial_conveyance, start_date, end_date)

cat("Fetching Elephant Butte Narrows data...\n")
eb_narrows_data <- fetch_gage_streamflow(elephant_butte_narrows, start_date, end_date)

# Conversion factor: 1 cfs-day = 1.983471 acre-feet
cfs_to_af <- 1.983471

# Calculate totals (sum of daily cfs)
cochiti_total_cfs <- sum(cochiti_data$data$flow, na.rm = TRUE)
sm_floodway_total_cfs <- sum(sm_floodway_data$data$flow, na.rm = TRUE)
sm_conveyance_total_cfs <- sum(sm_conveyance_data$data$flow, na.rm = TRUE)
eb_narrows_total_cfs <- sum(eb_narrows_data$data$flow, na.rm = TRUE)

# San Marcial combined (both channels)
san_marcial_combined_total_cfs <- sm_floodway_total_cfs + sm_conveyance_total_cfs

# Convert to acre-feet
cochiti_total_af <- cochiti_total_cfs * cfs_to_af
sm_floodway_total_af <- sm_floodway_total_cfs * cfs_to_af
sm_conveyance_total_af <- sm_conveyance_total_cfs * cfs_to_af
san_marcial_combined_total_af <- san_marcial_combined_total_cfs * cfs_to_af
eb_narrows_total_af <- eb_narrows_total_cfs * cfs_to_af

# Display results
cat("\n========================================\n")
cat("Flow Totals from", start_date, "to", as.character(end_date), "\n")
cat("========================================\n\n")

cat("Cochiti (", cochiti, "):\n")
cat("  Site:", cochiti_data$site_name, "\n")
cat("  Total flow:", format(round(cochiti_total_af), big.mark = ","), "acre-feet\n\n")

cat("San Marcial Combined (", san_marcial_floodway, "+", san_marcial_conveyance, "):\n")
cat("  Floodway:", sm_floodway_data$site_name, "\n")
cat("  Conveyance:", sm_conveyance_data$site_name, "\n")
cat("  Floodway total:", format(round(sm_floodway_total_af), big.mark = ","), "acre-feet\n")
cat("  Conveyance total:", format(round(sm_conveyance_total_af), big.mark = ","), "acre-feet\n")
cat("  COMBINED TOTAL:", format(round(san_marcial_combined_total_af), big.mark = ","), "acre-feet\n\n")

cat("Elephant Butte Narrows (", elephant_butte_narrows, "):\n")
cat("  Site:", eb_narrows_data$site_name, "\n")
cat("  Total flow:", format(round(eb_narrows_total_af), big.mark = ","), "acre-feet\n\n")

# Create bar chart
plot_data <- tibble(
  Location = factor(c("Cochiti", "San Marcial", "Elephant Butte Narrows"),
                   levels = c("Elephant Butte Narrows", "San Marcial", "Cochiti")),
  Total_AF = c(cochiti_total_af, san_marcial_combined_total_af, eb_narrows_total_af)
)

p <- ggplot(plot_data, aes(x = Location, y = Total_AF)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = format(round(Total_AF), big.mark = ",")),
            vjust = -0.5, size = 4) +
  coord_flip() +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = paste("Rio Grande Flow Totals:", start_date, "to", as.character(end_date)),
    y = "Acre-Feet",
    x = NULL,
    caption = standard_gage_attribution()
  ) +
  theme_bw() +
  theme(
    axis.title.x = element_text(size = 8, hjust = 0),
    plot.caption = element_text(hjust = 0, size = 8)
  )

print(p)

# Save plot
save_dated_gage_plot(p, "nov-flow-summary", width = 10, height = 5)
