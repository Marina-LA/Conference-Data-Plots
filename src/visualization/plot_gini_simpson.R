#!/usr/bin/env Rscript
# =============================================================================
# Plot: Gini-Simpson Diversity Index
# =============================================================================
# Calculates and visualizes the Gini-Simpson diversity index for
# geographic distribution of papers in conferences.
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

INPUT_PAPERS_CSV <- "data/processed/csv/unifiedPaperData.csv"
INPUT_COMMITTEE_CSV <- "data/processed/csv/unifiedCommitteeData.csv"  
INPUT_CITATIONS_CSV <- "data/processed/csv/unifiedCitationsData.csv"
OUTPUT_PDF <- "outputs/plots/gini_simpson_diversity_index.pdf"
PLOT_WIDTH <- PLOT_WIDTH_STANDARD
PLOT_HEIGHT <- PLOT_HEIGHT_STANDARD

# =============================================================================
# DIVERSITY INDEX CALCULATION
# =============================================================================

#' Calculate Gini-Simpson diversity index
#' @param proportions Vector of proportions (should sum to 1)
#' @return Diversity index (0 to 1, higher = more diverse)
calculate_gini_simpson <- function(proportions) {
  # Remove zero proportions
  proportions <- proportions[proportions > 0]
  
  # Calculate Gini-Simpson: 1 - sum(p^2)
  diversity <- 1 - sum(proportions^2)
  
  return(diversity)
}

#' Calculate diversity index for each conference
#' @param df Dataframe with Conference and Continent columns
#' @return Dataframe with diversity indices
calculate_conference_diversity <- function(df) {
  df %>%
    group_by(Conference, Continent) %>%
    summarise(count = n(), .groups = "drop") %>%
    group_by(Conference) %>%
    mutate(
      total = sum(count),
      proportion = count / total
    ) %>%
    summarise(
      diversity_index = calculate_gini_simpson(proportion),
      .groups = "drop"
    )
}

# =============================================================================
# DATA PROCESSING
# =============================================================================

process_diversity_data <- function(csv_path) {
  # Load and process data for diversity analysis
  
  load_csv_data(csv_path) %>%
    rename(Predominant_Continent = `Predominant Continent`) %>%
    # Clean continent codes
    clean_continent_codes("Predominant_Continent") %>%
    rename(Continent = Continent_Clean) %>%
    # Filter out Unknown
    filter(Continent != "Unknown") %>%
    # Standardize conference names
    standardize_conference_names()
}

# =============================================================================
# VISUALIZATION
# =============================================================================

create_diversity_plot <- function(df) {
  #Create bar plot of diversity indices.#
  
  # Order by diversity index
  df <- df %>%
    arrange(desc(diversity_index)) %>%
    mutate(Conference = factor(Conference, levels = Conference))
  
  # Create plot
  ggplot(df, aes(x = Conference, y = diversity_index)) +
    geom_col(fill = "#1681c5", width = 0.7) +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", linewidth = 0.3) +
    scale_y_continuous(
      limits = c(0, 1),
      breaks = seq(0, 1, 0.1),
      expand = c(0, 0)
    ) +
    labs(
      y = "Gini-Simpson Diversity Index",
      x = NULL
    ) +
    theme_conference_bars() +
    theme(
      panel.grid.major.y = element_line(color = "gray90", linewidth = 0.2)
    )
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main <- function() {
  message("Generating Gini-Simpson diversity index plot...")
  
  # Check input files exist
  if (!file.exists(INPUT_PAPERS_CSV)) {
    stop("Input file not found: ", INPUT_PAPERS_CSV)
  }
  
  # Create output directory
  dir.create(dirname(OUTPUT_PDF), recursive = TRUE, showWarnings = FALSE)
  
  # Load and process data
  df <- process_diversity_data(INPUT_PAPERS_CSV)
  
  # Calculate diversity indices
  diversity_df <- calculate_conference_diversity(df)
  
  # Print summary
  message("\nDiversity Indices:")
  for (i in 1:nrow(diversity_df)) {
    message(sprintf("  %15s: %.3f", 
                   diversity_df$Conference[i], 
                   diversity_df$diversity_index[i]))
  }
  
  # Create plot
  plot <- create_diversity_plot(diversity_df)
  
  # Save plot
  save_conference_plot(
    plot = plot,
    filename = OUTPUT_PDF,
    width = PLOT_WIDTH,
    height = PLOT_HEIGHT
  )
  
  message("\nPlot saved: ", OUTPUT_PDF)
  
  invisible(plot)
}

# Run if called as script
if (!interactive()) {
  main()
}

