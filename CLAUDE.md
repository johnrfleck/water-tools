# CLAUDE.md - AI Assistant Guide for water-tools

This document provides comprehensive guidance for AI assistants working with the water-tools repository.

## Project Overview

**water-tools** is a collection of R-based analysis and visualization tools for USGS water data, focused on streamflow (stream gages) and groundwater analysis. Created by John Fleck at the Utton Center, University of New Mexico School of Law.

**Purpose**: Provide accessible tools for water resource professionals, journalists, and researchers to analyze and visualize hydrological data from USGS National Water Information System (NWIS).

**License**: MIT (see LICENSE file)

**Key Insight**: The project uses "gage" not "gauge" - honoring USGS stream gager tradition.

## Recent Major Refactoring (October 2025)

The project underwent significant modernization:
- Created `usgs_gage_utils.r` - reusable utility library for all tools
- Refactored tools to use utilities (49% code reduction in some cases)
- Auto-detection of current year (no manual updates needed)
- Consistent visualization standards across all tools
- Added comprehensive groundwater data support
- Rewritten `general_groundwater.R` with modular design

## Repository Structure

```
water-tools/
├── usgs_gage_utils.r         # Core utility library - ALL tools depend on this
├── gage_this_year.R           # Current year flow vs historical percentiles
├── gage_to_date.R             # Year-to-date cumulative flow comparison
├── gage_ridgeplot.r           # Ridge plot of daily discharge patterns
├── annual_gage.r              # Annual flow totals visualization
├── flow_threshold.r           # Drought/flood threshold analysis
├── gage_annual_peak.r         # Annual peak flow visualization
├── gage_annual_boxplot.r      # Annual flow variability boxplots
├── gage_daily_five_year_boxplot.r      # Five-year period boxplots
├── gage_daily_five_year_violin_jitter.r # Violin plots with jitter
├── general_groundwater.R      # Interactive groundwater analysis tool
├── README.md                  # User-facing documentation
├── LICENSE                    # MIT License
├── .gitignore                 # Git ignore patterns
└── water-tools.Rproj          # RStudio project file

Generated directories (gitignored):
├── data/                      # CSV output files
└── graphics/                  # PNG visualization files
```

## Core Architecture

### The Utility Library: usgs_gage_utils.r

This is the **HEART** of the codebase. All tools source this file. It contains:

**Stream Gage Functions:**
- `fetch_gage_streamflow()` - Standardized USGS daily streamflow retrieval
- `fetch_gage_peak()` - Standardized USGS annual peak flow retrieval
- `calculate_daily_percentiles()` - Percentile calculations for historical context
- `get_current_year_data()` - Auto-detect and filter current year
- `calculate_split_medians()` - Climate context (1981-2000 vs 2001-present)

**Groundwater Functions:**
- `suggest_gw_options()` - Auto-discover available groundwater data at a site
- `fetch_gw_series()` - Retrieve groundwater levels (daily or manual)
- Normalizers for different USGS groundwater data formats

**Visualization Standards:**
- `standard_gage_attribution()` - Consistent attribution text with GitHub link
- `gage_percentile_colors()` - Standard color scheme (blue/green)
- `gage_line_colors()` - Standard line colors (black/red/purple/blue)
- `month_axis_scale()` - Month labels for x-axis
- `apply_gage_theme()` - Consistent ggplot2 theme (theme_bw + customization)
- `save_dated_gage_plot()` - Save plots with date-based filenames

### Tool Architecture Pattern

All analysis tools follow this pattern:

1. **Source utilities**: `source("usgs_gage_utils.r")` or `source("./usgs_gage_utils.r")`
2. **Interactive input**: Use `readline()` for gage numbers and parameters
3. **Fetch data**: Use utility functions (`fetch_gage_streamflow()`, `fetch_gw_series()`)
4. **Process data**: Use tidyverse/dplyr for data manipulation
5. **Visualize**: Use ggplot2 with standard utility functions
6. **Display**: `print(p)` to show plot

## Key Conventions

### File Naming
- Lowercase with underscores: `gage_this_year.R`, `annual_gage.r`
- Mixed `.r` and `.R` extensions (historical, both work)
- Descriptive names indicating purpose
- Utility library: `usgs_gage_utils.r` (singular form)

### Spelling Convention
- **ALWAYS** use "gage" not "gauge" - honoring USGS tradition
- This applies to: file names, variable names, comments, documentation

### Code Style
- **Libraries**: Always load at top: `dataRetrieval`, `tidyverse`, `lubridate`
- **Comments**: Header blocks explain purpose and provide example gage numbers
- **Example gages** (always include in comments):
  - 08330000 - Rio Grande at Albuquerque, NM
  - 08313000 - Rio Grande at Otowi Bridge, NM
  - 08332010 - Rio Grande Floodway near Bernardo, NM
- **Indentation**: 2 spaces (R convention)
- **Assignment**: Use `<-` not `=` for assignment
- **Pipes**: Use `%>%` from magrittr/tidyverse

### Data Processing Conventions
- **Date handling**: Use `lubridate` package
- **Current year**: Auto-detect with `year(Sys.Date())`
- **Column names**:
  - Use USGS naming: `Date`, `Year`, `DayOfYear`, `flow`
  - Groundwater: `date`, `depth_bls_ft` (below land surface)
- **NA handling**: Always use `na.rm = TRUE` in aggregations
- **Conversions**:
  - cfs to acre-feet per day: `* 1.98347`
  - cfs to annual acre-feet: `* 724`

### Visualization Standards

**Colors:**
- Percentile bands: blue (10-90th), green (30-70th)
- Median lines: black (period of record), red (1981-2000), purple (2001-present)
- Current year: blue
- Use `scale_fill_identity()` or `scale_color_manual()` from utilities

**Themes:**
- Base: `theme_bw()`
- Attribution: 8pt, left-justified on x-axis
- Legend: inset box, upper-right (0.98, 0.98), with border
- Apply with: `apply_gage_theme()`

**Axis Labels:**
- X-axis: Use `standard_gage_attribution()` for source info
- Y-axis: Descriptive units ("Streamflow, cfs", "thousand acre feet")
- X-axis breaks: 5-year intervals for readability
- Month labels: Use `month_axis_scale()` for day-of-year data

**Titles:**
- Format: "{Metric} at the {Site Name} USGS Gage"
- Include period of record: "Period of record: {start_year} to {end_year}"
- Subtitle: Include gage number and data series start date

**Output:**
- Print plots: `print(p)`
- Save to `./graphics/` directory (auto-created)
- Save CSV data to `./data/` directory (auto-created)
- Use date-based filenames with timestamps

## Development Workflows

### Adding a New Analysis Tool

1. **Plan the analysis**
   - What hydrological question does it answer?
   - What USGS data is needed?
   - What visualization best communicates the insight?

2. **Create the script file**
   - Name: `gage_{purpose}.r` or similar descriptive name
   - Start with header comment block (purpose + example gages)

3. **Source utilities**
   ```r
   source("usgs_gage_utils.r")
   ```

4. **Implement using standard pattern**
   - Interactive input with `readline()`
   - Fetch data with utility functions
   - Process with tidyverse
   - Visualize with standard theme/colors
   - Print result

5. **Test with example gages**
   - Test with all three standard Rio Grande gages
   - Verify data series start dates
   - Check edge cases (incomplete years, missing data)

6. **Document in README.md**
   - Add tool description
   - Explain what it does and when to use it
   - Mention key features

### Modifying Existing Tools

1. **Read the tool first** - Understand current implementation
2. **Check dependencies** - Does it use utility functions correctly?
3. **Preserve standards** - Maintain visualization conventions
4. **Test thoroughly** - Verify with example gages
5. **Update README** - If functionality changes

### Adding to usgs_gage_utils.r

This is **CRITICAL** because all tools depend on it.

1. **Understand impact** - Changes affect ALL tools
2. **Maintain backwards compatibility** - Don't break existing tool APIs
3. **Document thoroughly** - Use roxygen-style comments
4. **Follow patterns**:
   - Data fetching: Return list with `data`, `site_name`, `site_number`
   - Visualization: Return ggplot2 objects or scales
   - Naming: Descriptive function names with underscores
5. **Test comprehensively** - Verify no tools break

### Git Workflow

**Current Branch**: `claude/claude-md-mjc9wzdcuqvcyj6d-YYZ4o` (development branch for this session)

**Commit Messages:**
- Clear, descriptive subjects
- Use imperative mood: "Add feature" not "Added feature"
- Recent examples:
  - "Improve year-to-date flow visualization readability"
  - "Add comprehensive groundwater data support and rewrite general_groundwater.R"
  - "Modernize ridge plot tool: rename and update to ggridges package"

**Pushing:**
- Always push to the specified claude/* branch
- Use: `git push -u origin claude/claude-md-mjc9wzdcuqvcyj6d-YYZ4o`
- Retry with exponential backoff on network failures (2s, 4s, 8s, 16s)

## Working with Different Data Types

### Stream Gage Data

**Fetch with**: `fetch_gage_streamflow(site_number, start_date, end_date)`

**Returns**:
- `data`: Tibble with `Date`, `Year`, `DayOfYear`, `flow` columns
- `site_name`: Station name
- `site_number`: USGS site number

**Common operations**:
- Filter current year: `filter(Year == year(Sys.Date()))`
- Group by year: `group_by(Year)`
- Calculate percentiles: `calculate_daily_percentiles(data)`

### Peak Flow Data

**Fetch with**: `fetch_gage_peak(site_number, start_date, end_date)`

**Returns**:
- `data`: Tibble with peak flow data (`peak_dt`, `peak_va`, `Year`)
- `site_name`: Station name
- `site_number`: USGS site number

**Use for**: Annual maximum instantaneous discharge analysis

### Groundwater Data

**Discovery**: `suggest_gw_options(site_no)` - Auto-discover available data

**Fetch with**: `fetch_gw_series(site_no, mode, start_date, end_date)`

**Modes**:
- `"daily_only"`: Daily values (depth below land surface)
- `"manual_only"`: Manual field measurements

**Returns**: Tibble with `site_no`, `date_time`, `date`, `depth_bls_ft`, `source`, `tz`

## Common Patterns to Follow

### Interactive Script Pattern

```r
# Header comment with purpose and example gages
source("usgs_gage_utils.r")

# Get user input
siteNo <- readline(prompt = "Enter a gage number: ")

# Optional: Uncomment for testing
# siteNo <- "08330000"

# Fetch data
gage_data <- fetch_gage_streamflow(siteNo)
daily_data <- gage_data$data
site_name <- gage_data$site_name

# Process data
# ... your analysis here ...

# Visualize with standards
p <- ggplot(...) +
  # ... your visualization ...
  labs(
    title = paste("...", site_name, "USGS Gage..."),
    x = standard_gage_attribution(),
    y = "..."
  ) +
  apply_gage_theme()

print(p)
```

### Date Range Calculation Pattern

```r
# Get current year automatically
current_year <- year(Sys.Date())

# Calculate start/end from data
start_year <- min(data$Year, na.rm = TRUE)
end_year <- max(data$Year, na.rm = TRUE)

# Create 5-year interval breaks for x-axis
year_min <- min(data$Year)
year_max <- max(data$Year)
year_breaks <- seq(ceiling(year_min / 5) * 5, floor(year_max / 5) * 5, by = 5)
```

### Title Creation Pattern

```r
# For time series with period of record
title <- paste("Daily Flows at the", site_name, "USGS Gage\nPeriod of record:",
               start_year, "to present")

# For specific metrics with subtitle
subtitle_text <- sprintf("Annual flow\nUSGS gage %s\nData series start date: %s",
                        siteNo, format(start_date, "%Y-%m-%d"))
```

### Percentile Visualization Pattern

```r
# Calculate stats
stats_df <- calculate_daily_percentiles(dailyStreamflow)

# Plot with ribbons and lines
p <- ggplot(stats_df, aes(x = DayOfYear)) +
  geom_ribbon(aes(ymin = P10, ymax = P90, fill = "10th to 90th percentile"), alpha = 0.3) +
  geom_ribbon(aes(ymin = P30, ymax = P70, fill = "30th to 70th percentile"), alpha = 0.3) +
  scale_fill_manual(values = gage_percentile_colors(), name = NULL) +
  month_axis_scale() +
  # ... rest of plot ...
```

## Testing and Validation

### Manual Testing Checklist

When modifying tools, test with:

1. **Standard example gages** (all three Rio Grande sites)
2. **Edge cases**:
   - Very old gages with long records
   - Recently established gages with short records
   - Gages with data gaps
   - Current incomplete year handling
3. **Interactive input**:
   - Valid inputs
   - Invalid inputs (error handling)
   - Default values

### Validation Points

- **Data fetching**: Verify USGS data returns successfully
- **Date handling**: Check current year auto-detection
- **Calculations**: Spot-check percentiles and aggregations
- **Visualizations**: Verify plots display correctly
- **Output files**: Check graphics/ and data/ directories
- **Attribution**: Verify GitHub link in all plots

## Important Notes for AI Assistants

### DO:
- ✓ Always source `usgs_gage_utils.r` in analysis tools
- ✓ Use utility functions for data fetching and visualization
- ✓ Follow visualization standards (colors, theme, attribution)
- ✓ Include example gage numbers in comments
- ✓ Use "gage" not "gauge"
- ✓ Auto-detect current year with `year(Sys.Date())`
- ✓ Test with standard Rio Grande example gages
- ✓ Update README.md when adding/modifying tools
- ✓ Use 5-year interval breaks for readability
- ✓ Handle NA values in aggregations

### DON'T:
- ✗ Don't break backwards compatibility in usgs_gage_utils.r
- ✗ Don't hardcode years (auto-detect instead)
- ✗ Don't use inconsistent colors/themes
- ✗ Don't forget attribution text with GitHub link
- ✗ Don't create tools without sourcing utilities
- ✗ Don't use "gauge" spelling
- ✗ Don't skip header comments and examples
- ✗ Don't commit generated graphics/ or data/ directories

### When Making Changes:

1. **Understand the utility library** - Read usgs_gage_utils.r first
2. **Follow established patterns** - Look at existing tools for examples
3. **Preserve standards** - Visualization consistency is key
4. **Test thoroughly** - Use example gages from comments
5. **Document changes** - Update README.md and code comments
6. **Commit clearly** - Descriptive commit messages

## Dependencies

**Required R Packages:**
- `dataRetrieval` - USGS data access
- `tidyverse` - Data manipulation and ggplot2
- `lubridate` - Date/time handling
- `ggridges` - Ridge plots (for gage_ridgeplot.r)

**Installation:**
```r
install.packages(c("dataRetrieval", "tidyverse", "lubridate", "ggridges"))
```

## Common Tasks Reference

### Add a new visualization to existing tool

1. Read the tool source code
2. Check if utility functions can help
3. Add ggplot2 layer using standard colors
4. Apply `apply_gage_theme()` at the end
5. Test with example gages

### Add new utility function

1. Open `usgs_gage_utils.r`
2. Add to appropriate section (Data Fetching, Visualization, etc.)
3. Use roxygen-style documentation comments
4. Return consistent data structures
5. Test with multiple tools that might use it

### Fix a bug

1. Reproduce with example gage number
2. Identify root cause
3. Fix while maintaining patterns
4. Test with all three example gages
5. Check if fix affects other tools (if in utilities)

### Update visualization standard

1. Modify function in `usgs_gage_utils.r`
2. Test with ALL tools (they all use utilities)
3. Update this CLAUDE.md if pattern changes
4. Document in commit message

## Repository Philosophy

This repository prioritizes:

1. **Accessibility** - Tools are easy to use for non-programmers
2. **Consistency** - All tools follow same patterns and standards
3. **Reusability** - Common code in utilities, DRY principle
4. **Clarity** - Clear variable names, thorough comments
5. **Reproducibility** - Standard attribution with GitHub link
6. **Tradition** - Honor USGS conventions (e.g., "gage" spelling)

## Questions or Issues?

When encountering unfamiliar patterns:
- Check `usgs_gage_utils.r` for utility functions
- Look at similar tools for examples
- Refer to recent commit messages for context
- Check README.md for user-facing documentation

---

**Last Updated**: 2025-12-19
**Repository**: https://github.com/johnrfleck/water-tools
**Maintainer**: John Fleck, Utton Center, University of New Mexico School of Law
