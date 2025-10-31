#!/usr/bin/env Rscript
# =============================================================================
# Plot: Committee Members by Continent Distribution
# =============================================================================
# Generates stacked bar chart showing distribution of committee members
# across continents for each conference.
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

INPUT_CSV <- "data/processed/csv/unifiedCommitteeData.csv"
OUTPUT_PDF <- "outputs/plots/committee_continent_distribution.pdf"
PLOT_WIDTH <- PLOT_WIDTH_STANDARD
PLOT_HEIGHT <- PLOT_HEIGHT_STANDARD

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main <- function() {
  message("Generating committee distribution plot...")
  
  # Check input file exists
  if (!file.exists(INPUT_CSV)) {
    stop("Input file not found: ", INPUT_CSV)
  }
  
  # Create output directory
  dir.create(dirname(OUTPUT_PDF), recursive = TRUE, showWarnings = FALSE)
  
  # Generate plot using pipeline function
  plot <- pipeline_committee_distribution(
    csv_path = INPUT_CSV,
    output_path = OUTPUT_PDF,
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

