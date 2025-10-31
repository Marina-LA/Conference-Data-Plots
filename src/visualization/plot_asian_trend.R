#!/usr/bin/env Rscript
# =============================================================================
# Plot: Asian Papers Trend Over Time
# =============================================================================
# Generates faceted line plots showing the percentage of Asian papers
# over time for each conference.
# =============================================================================

# Source utilities
tryCatch({
  script_dir <- dirname(sys.frame(1)$ofile)
}, error = function(e) {
  script_dir <<- getwd()
})
if (file.exists("src/visualization/plot_utils.R")) {
  source("src/visualization/plot_utils.R")
} else {
  source(file.path(script_dir, "plot_utils.R"))
}

# =============================================================================
# CONFIGURATION
# =============================================================================

INPUT_CSV <- "data/processed/csv/unifiedPaperData.csv"
OUTPUT_PDF <- "outputs/plots/asian_trend.pdf"
PLOT_WIDTH <- PLOT_WIDTH_STANDARD
PLOT_HEIGHT <- PLOT_HEIGHT_STANDARD

# =============================================================================
# DATA PROCESSING
# =============================================================================

process_asian_trend_data <- function(csv_path) {
  load_csv_data(csv_path) %>%
    rename(Predominant_Continent = `Predominant Continent`) %>%
    filter(!is.na(Predominant_Continent)) %>%
    # Standardize conference names
    mutate(Conference = tolower(Conference)) %>%
    standardize_conference_names() %>%
    # Calculate percentages by year
    group_by(Conference, Year) %>%
    summarise(
      total_papers = n(),
      asian_papers = sum(Predominant_Continent == "AS"),
      percentage_asian = asian_papers / total_papers * 100,
      .groups = "drop"
    ) %>%
    # Set conference factor order
    mutate(Conference = factor(Conference, levels = CONFERENCE_ORDER))
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main <- function() {
  message("Generating Asian papers trend plot...")
  
  # Check input file exists
  if (!file.exists(INPUT_CSV)) {
    stop("Input file not found: ", INPUT_CSV)
  }
  
  # Create output directory
  dir.create(dirname(OUTPUT_PDF), recursive = TRUE, showWarnings = FALSE)
  
  # Load and process data
  df <- process_asian_trend_data(INPUT_CSV)
  
  # Create plot
  plot <- create_faceted_trend_plot(
    df = df,
    y_col = "percentage_asian",
    y_label = "Percentage of Asian Papers",
    line_color = ASIA_TREND_COLOR
  )
  
  # Save plot
  save_conference_plot(
    plot = plot,
    filename = OUTPUT_PDF,
    width = PLOT_WIDTH,
    height = PLOT_HEIGHT
  )
  
  message("Plot saved: ", OUTPUT_PDF)
  
  invisible(plot)
}

# Run if called as script
if (!interactive()) {
  main()
}

