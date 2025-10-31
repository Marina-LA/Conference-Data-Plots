# =============================================================================
# Centralized Configuration for R Plotting Scripts
# =============================================================================
# This file contains all shared constants, color schemes, and configurations
# used across R visualization scripts.
# =============================================================================

# Suppress package startup messages and warnings
options(tidyverse.quiet = TRUE)
options(warn = -1)
suppressPackageStartupMessages({
  suppressWarnings({
    library(tidyverse, quietly = TRUE, warn.conflicts = FALSE)
    library(scales, quietly = TRUE, warn.conflicts = FALSE)
  })
})
options(warn = 0)

# =============================================================================
# CONFERENCE CONFIGURATION
# =============================================================================

CONFERENCE_MAPPING <- c(
  "nsdi" = "NSDI",
  "sigcomm" = "SIGCOMM",
  "cloud" = "SoCC",
  "socc" = "SoCC",
  "eurosys" = "EuroSys",
  "ic2e" = "IC2E",
  "icdcs" = "ICDCS",
  "middleware" = "Middleware",
  "ieeecloud" = "IEEE Cloud",
  "IEEEcloud" = "IEEE Cloud",
  "ccgrid" = "CCGRID",
  "europar" = "Euro-Par",
  "asplos" = "ASPLOS",
  "atc" = "ATC",
  "osdi" = "OSDI"
)

CONFERENCE_ORDER <- c(
  "NSDI", "ASPLOS", "SIGCOMM", "SoCC", "OSDI", "EuroSys",
  "ATC", "IC2E", "ICDCS", "Middleware", "IEEE Cloud",
  "CCGRID", "Euro-Par"
)

# =============================================================================
# CONTINENT CONFIGURATION
# =============================================================================

CONTINENT_MAPPING <- c(
  "NA" = "North America",
  "EU" = "Europe",
  "AS" = "Asia",
  "SA" = "South America",
  "OC" = "Oceania",
  "AF" = "Africa",
  "Others" = "Others",
  "Unknown" = "Unknown"
)

# Continent levels for factor ordering (bottom to top in stacked plots)
CONTINENT_LEVELS <- c("Unknown", "Others", "AS", "EU", "NA")
CONTINENT_LEVELS_NAMED <- c("Unknown", "Others", "Asia", "Europe", "North America")

# Continent order for legends (left to right)
CONTINENT_ORDER <- c("North America", "Europe", "Asia", "Others", "Unknown")

# =============================================================================
# COLOR SCHEMES
# =============================================================================

# Primary continent colors (used in all plots)
CONTINENT_COLORS <- c(
  "North America" = "#1f3b6f",  # Dark blue
  "Europe" = "#1681c5",          # Medium blue
  "Asia" = "#7d7d7d",            # Gray
  "Others" = "#c5c5c5",          # Light gray
  "Unknown" = "#FFFFFF"          # White
)

# Continent colors by code (for easier reference)
CONTINENT_COLORS_BY_CODE <- c(
  "NA" = "#1f3b6f",
  "EU" = "#1681c5",
  "AS" = "#7d7d7d",
  "Others" = "#c5c5c5",
  "Unknown" = "#FFFFFF"
)

# Special colors for specific analyses
ASIA_TREND_COLOR <- "#4A90E2"
BIG_TECH_COLOR <- "#e74c3c"
ACADEMIA_COLOR <- "#3498db"

# =============================================================================
# PLOT THEME DEFAULTS
# =============================================================================

# Default plot dimensions (in inches)
PLOT_WIDTH_WIDE <- 10.5
PLOT_HEIGHT_WIDE <- 4
PLOT_WIDTH_STANDARD <- 6.99
PLOT_HEIGHT_STANDARD <- 4
PLOT_HEIGHT_TALL <- 8

# Font settings
PLOT_FONT_FAMILY <- "serif"
PLOT_BASE_SIZE <- 10

# =============================================================================
# HELPER FUNCTIONS FOR DATA LOADING
# =============================================================================

#' Load CSV data with standard NA handling
#' @param file_path Path to CSV file
#' @return Tibble with loaded data
load_csv_data <- function(file_path) {
  read_csv(file_path, na = c(""), show_col_types = FALSE)
}

#' Standardize conference names using mapping
#' @param df Dataframe with Conference column
#' @return Dataframe with standardized conference names
standardize_conference_names <- function(df) {
  df %>%
    mutate(
      Conference = tolower(Conference),
      Conference = recode(Conference, !!!CONFERENCE_MAPPING)
    ) %>%
    filter(!is.na(Conference))
}

#' Clean continent codes to standard groups (NA, EU, AS, Others, Unknown)
#' @param continent_col Name of continent column
#' @param df Dataframe
#' @return Dataframe with cleaned continent column
clean_continent_codes <- function(df, continent_col = "Continent") {
  df %>%
    mutate(
      !!continent_col := case_when(
        .data[[continent_col]] %in% c("NA", "EU", "AS") ~ .data[[continent_col]],
        .data[[continent_col]] %in% c("SA", "OC", "AF") ~ "Others",
        is.na(.data[[continent_col]]) | .data[[continent_col]] == "" ~ "Unknown",
        TRUE ~ "Others"
      )
    )
}

#' Order conferences by North America percentage (descending)
#' @param df Dataframe with Conference and percentage data
#' @param continent_col Name of continent column
#' @param percentage_col Name of percentage column
#' @return Dataframe with Conference as ordered factor
order_by_na_percentage <- function(df, continent_col = "Continent", percentage_col = "Percentage") {
  na_ordering <- df %>%
    filter(.data[[continent_col]] == "North America" | .data[[continent_col]] == "NA") %>%
    arrange(desc(.data[[percentage_col]])) %>%
    pull(Conference) %>%
    unique()
  
  df %>%
    mutate(Conference = factor(Conference, levels = na_ordering))
}

# =============================================================================
# THEME FUNCTIONS
# =============================================================================

#' Apply standard theme to plot
#' @param base_size Base font size
#' @param base_family Font family
#' @return ggplot2 theme
theme_conference_standard <- function(base_size = PLOT_BASE_SIZE, 
                                     base_family = PLOT_FONT_FAMILY) {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      text = element_text(family = base_family),
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "top",
      legend.key.size = unit(0.25, "cm"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(linewidth = 0.2),
      plot.margin = margin(t = 10, r = 10, b = 10, l = 10)
    )
}

#' Apply theme for bar plots
#' @param base_size Base font size
#' @return ggplot2 theme
theme_conference_bars <- function(base_size = PLOT_BASE_SIZE) {
  theme_conference_standard(base_size = base_size) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, 
                                 face = "bold", margin = margin(t = 6)),
      panel.grid.major.x = element_blank()
    )
}

#' Apply theme for faceted plots
#' @param base_size Base font size
#' @return ggplot2 theme
theme_conference_facets <- function(base_size = PLOT_BASE_SIZE) {
  theme_conference_standard(base_size = base_size) +
    theme(
      strip.text = element_text(face = "bold", size = base_size - 2),
      panel.spacing = unit(1, "lines")
    )
}

# =============================================================================
# SAVE PLOT FUNCTION
# =============================================================================

#' Save plot with standard settings
#' @param plot ggplot object
#' @param filename Output filename
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @param device Output device (default: "pdf")
save_conference_plot <- function(plot, filename, 
                                width = PLOT_WIDTH_STANDARD, 
                                height = PLOT_HEIGHT_STANDARD,
                                device = "pdf") {
  ggsave(
    filename = filename,
    plot = plot,
    device = device,
    width = width,
    height = height,
    units = "in",
    dpi = 300
  )
  message("Plot saved: ", filename)
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Configuration loaded (silent)

