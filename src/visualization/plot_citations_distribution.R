#!/usr/bin/env Rscript
# =============================================================================
# Plot: Accepted vs Cited Papers Distribution
# =============================================================================
# Generates comparison plot showing distribution differences between
# accepted papers and cited papers by continent.
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
INPUT_CITATIONS_CSV <- "data/processed/csv/unifiedCitationsData.csv"
OUTPUT_PDF <- "outputs/plots/citations_distribution.pdf"
PLOT_WIDTH <- PLOT_WIDTH_STANDARD
PLOT_HEIGHT <- PLOT_HEIGHT_STANDARD

# =============================================================================
# DATA PROCESSING
# =============================================================================

process_paper_data <- function(df, data_type) {
  # Process paper data for comparison plot
  
  # Determine column names based on type
  continent_col <- ifelse(data_type == "accepted", 
                         "Predominant_Continent", "Continent")
  
  df_processed <- df %>%
    mutate(
      Continent = case_when(
        .data[[continent_col]] %in% c("NA", "EU", "AS") ~ .data[[continent_col]],
        .data[[continent_col]] %in% c("SA", "OC", "AF") ~ "Others",
        .data[[continent_col]] == "Unknown" ~ "Unknown",
        is.na(.data[[continent_col]]) | .data[[continent_col]] == "" ~ "Unknown",
        TRUE ~ .data[[continent_col]]
      )
    ) %>%
    group_by(Conference) %>%
    mutate(total_papers = ifelse(data_type == "accepted", n(), sum(Num_Papers))) %>%
    group_by(Conference, Continent, total_papers) %>%
    summarise(
      count = ifelse(data_type == "accepted", n(), sum(Num_Papers)),
      .groups = "drop"
    ) %>%
    mutate(
      percentage = (count / total_papers) * 100,
      type = paste(str_to_title(data_type), "Papers")
    )
  
  df_processed
}

load_and_prepare_comparison_data <- function(papers_path, citations_path) {
  #Load and prepare data for comparison plot.#
  
  # Load papers data
  accepted <- load_csv_data(papers_path) %>%
    rename(Predominant_Continent = `Predominant Continent`) %>%
    mutate(Conference = ifelse(tolower(Conference) == "cloud", "socc", Conference))
  
  # Load citations data
  cited <- load_csv_data(citations_path) %>%
    mutate(Conference = ifelse(tolower(Conference) == "cloud", "socc", Conference))
  
  # Process both datasets
  accepted_df <- process_paper_data(accepted, "accepted")
  cited_df <- process_paper_data(cited, "cited")
  
  # Combine and format
  combined_df <- bind_rows(accepted_df, cited_df) %>%
    mutate(
      Continent = factor(Continent, levels = CONTINENT_LEVELS),
      type = factor(type, levels = c("Cited Papers", "Accepted Papers"))
    ) %>%
    standardize_conference_names() %>%
    filter(!is.na(Conference))
  
  # Order by NA percentage
  na_percentages <- combined_df %>%
    filter(Continent == "NA") %>%
    group_by(Conference) %>%
    summarise(na_percentage = mean(percentage), .groups = "drop") %>%
    arrange(desc(na_percentage))
  
  combined_df %>%
    mutate(Conference = factor(Conference, levels = na_percentages$Conference))
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main <- function() {
  message("Generating citations distribution plot...")
  
  # Check input files exist
  if (!file.exists(INPUT_PAPERS_CSV)) {
    stop("Papers file not found: ", INPUT_PAPERS_CSV)
  }
  if (!file.exists(INPUT_CITATIONS_CSV)) {
    stop("Citations file not found: ", INPUT_CITATIONS_CSV)
  }
  
  # Create output directory
  dir.create(dirname(OUTPUT_PDF), recursive = TRUE, showWarnings = FALSE)
  
  # Load and process data
  df <- load_and_prepare_comparison_data(INPUT_PAPERS_CSV, INPUT_CITATIONS_CSV)
  
  # Create plot
  plot <- create_comparison_plot(df)
  
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

