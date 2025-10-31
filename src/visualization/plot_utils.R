# =============================================================================
# Plot Utilities - Shared functions for conference data visualization
# =============================================================================
# This file contains reusable functions for data processing and plot generation
# =============================================================================

# Load required libraries (suppress messages)
suppressPackageStartupMessages({
  suppressWarnings({
    library(ggpattern, quietly = TRUE, warn.conflicts = FALSE)
  })
})

# Source configuration
source(file.path(dirname(sys.frame(1)$ofile), "..", "config", "config.R"))

# =============================================================================
# DATA PROCESSING UTILITIES
# =============================================================================

#' Clean continent codes to standard format
#' @param df Dataframe
#' @param continent_col Name of continent column
#' @return Dataframe with Continent_Clean column
clean_continent_codes <- function(df, continent_col) {
  df %>%
    mutate(
      Continent_Clean = case_when(
        is.na(.data[[continent_col]]) ~ "Unknown",
        .data[[continent_col]] %in% c("NA", "EU", "AS") ~ .data[[continent_col]],
        .data[[continent_col]] %in% c("SA", "OC", "AF") ~ "Others",
        TRUE ~ "Unknown"
      )
    )
}

#' Standardize conference names
#' @param df Dataframe with Conference column
#' @return Dataframe with standardized Conference names
standardize_conference_names <- function(df) {
  df %>%
    mutate(
      Conference_Lower = tolower(Conference),
      Conference = recode(Conference_Lower, !!!CONFERENCE_MAPPING, .default = Conference)
    ) %>%
    select(-Conference_Lower) %>%
    filter(!is.na(Conference))
}

#' Process paper data with continent grouping
#' @param df Dataframe with papers data
#' @param continent_col Name of continent column
#' @return Processed dataframe
process_paper_continents <- function(df, continent_col = "Predominant Continent") {
  df %>%
    mutate(
      Continent_Clean = case_when(
        .data[[continent_col]] %in% c("NA", "EU", "AS") ~ .data[[continent_col]],
        .data[[continent_col]] %in% c("SA", "OC", "AF") ~ "Others",
        is.na(.data[[continent_col]]) | .data[[continent_col]] == "" ~ "Unknown",
        TRUE ~ "Others"
      )
    )
}

#' Calculate percentage distribution by conference and continent
#' @param df Dataframe with Conference and Continent columns
#' @param continent_col Name of continent column
#' @return Dataframe with percentages
calculate_continent_percentages <- function(df, continent_col = "Continent_Clean") {
  # Total count per conference
  total_counts <- df %>%
    group_by(Conference) %>%
    summarise(Total = n(), .groups = "drop")
  
  # Known continent counts (excluding Unknown)
  known_counts <- df %>%
    filter(.data[[continent_col]] != "Unknown") %>%
    group_by(Conference, .data[[continent_col]]) %>%
    summarise(Count = n(), .groups = "drop") %>%
    rename(Continent = !!continent_col)
  
  # Calculate percentages for known continents
  known_pct <- known_counts %>%
    left_join(total_counts, by = "Conference") %>%
    mutate(Percentage = Count / Total * 100) %>%
    ungroup() %>%
    select(Conference, Continent, Percentage)
  
  # Calculate Unknown as remainder to 100%
  unknown_pct <- known_pct %>%
    group_by(Conference) %>%
    summarise(known_sum = sum(Percentage), .groups = "drop") %>%
    mutate(
      Percentage = pmax(0, 100 - known_sum),
      Continent = "Unknown"
    ) %>%
    select(Conference, Continent, Percentage)
  
  # Combine
  bind_rows(known_pct, unknown_pct)
}

#' Apply readable labels to continents and conferences
#' @param df Dataframe
#' @param apply_conference_mapping Apply conference name mapping
#' @return Dataframe with readable labels
apply_readable_labels <- function(df, apply_conference_mapping = TRUE) {
  result <- df
  
  # Apply continent mapping if column exists (replace directly)
  if ("Continent" %in% names(df)) {
    result <- result %>%
      mutate(
        Continent = recode(Continent, !!!CONTINENT_MAPPING, .default = Continent)
      )
  }
  
  # Apply conference mapping if requested
  if (apply_conference_mapping && "Conference" %in% names(df)) {
    result <- result %>%
      mutate(
        Conference_Clean = tolower(Conference),
        Conference = recode(Conference_Clean, !!!CONFERENCE_MAPPING,
                           .default = Conference),
        Conference_Clean = NULL
      ) %>%
      filter(!is.na(Conference))
  }
  
  result
}

# =============================================================================
# PLOT CREATION UTILITIES
# =============================================================================

#' Create stacked bar plot with continent distribution
#' @param df Dataframe with Conference, Continent, Percentage
#' @param y_label Y-axis label
#' @param show_unknown Include Unknown category in legend
#' @param use_patterns Add stripe pattern for Unknown bars
#' @return ggplot object
create_continent_stacked_bars <- function(df, 
                                         y_label = "Percentage",
                                         show_unknown = FALSE,
                                         use_patterns = TRUE) {
  
  # Prepare data
  plot_df <- df %>%
    mutate(
      # Ensure continent is in readable format
      Continent = if_else(
        Continent %in% names(CONTINENT_MAPPING),
        recode(Continent, !!!CONTINENT_MAPPING),
        Continent
      ),
      # Set factor levels
      Continent = factor(
        Continent,
        levels = c("Unknown", "Others", "Asia", "Europe", "North America")
      )
    )
  
  # Create plot without patterns (simple bars)
  p <- ggplot(plot_df, aes(x = Conference, y = Percentage, fill = Continent)) +
    geom_bar(stat = "identity", width = 0.7)
  
  # Add scales and theme
  p <- p +
    scale_fill_manual(
      name = NULL,
      values = CONTINENT_COLORS,
      breaks = if (show_unknown) names(CONTINENT_COLORS) 
               else setdiff(names(CONTINENT_COLORS), "Unknown")
    ) +
    scale_y_continuous(
      breaks = seq(0, 100, 10),
      labels = function(x) paste0(x, "%"),
      expand = c(0, 0),
      limits = c(0, 100)
    ) +
    labs(
      y = y_label,
      x = NULL
    ) +
    theme_conference_bars()
  
  p
}

#' Create faceted line plot for trends
#' @param df Dataframe with Conference, Year, and metric columns
#' @param y_col Name of Y-axis column
#' @param y_label Y-axis label
#' @param line_color Line color
#' @return ggplot object
create_faceted_trend_plot <- function(df, y_col, y_label, 
                                     line_color = ASIA_TREND_COLOR) {
  
  # Create overlay data
  df_overlay <- df %>% 
    rename(Facet_Conference = Conference) %>%
    filter(!is.na(Facet_Conference))
  
  # Create plot
  ggplot() +
    # Background lines (all conferences)
    geom_line(
      data = df,
      aes(x = Year, y = .data[[y_col]], group = Conference),
      color = "grey80",
      linewidth = 0.3
    ) +
    # Highlighted lines (facet conference)
    geom_line(
      data = df_overlay,
      aes(x = Year, y = .data[[y_col]]),
      color = line_color,
      linewidth = 0.5
    ) +
    geom_point(
      data = df_overlay,
      aes(x = Year, y = .data[[y_col]]),
      color = line_color,
      size = 1
    ) +
    facet_wrap(~ Facet_Conference, ncol = 5, drop = TRUE) +
    scale_y_continuous(
      labels = percent_format(scale = 1),
      limits = c(0, 100)
    ) +
    labs(
      x = "Year",
      y = y_label
    ) +
    theme_conference_facets()
}

#' Create comparison plot (Accepted vs Cited papers)
#' @param df Dataframe with type, Conference, Continent, Percentage
#' @return ggplot object
create_comparison_plot <- function(df) {
  # Create outline data
  outline_df <- df %>%
    group_by(type, Conference) %>%
    summarise(percentage = sum(percentage), .groups = "drop")
  
  ggplot(df, aes(x = type, y = percentage, fill = Continent)) +
    geom_col(position = "stack") +
    geom_col(
      data = outline_df,
      aes(x = type, y = percentage),
      fill = NA,
      color = "black",
      linewidth = 0.1,
      inherit.aes = FALSE
    ) +
    facet_wrap(~ Conference, ncol = 2) +
    scale_fill_manual(
      values = CONTINENT_COLORS_BY_CODE,
      breaks = c("NA", "EU", "AS", "Others", "Unknown"),
      labels = c("North America", "Europe", "Asia", "Others", "Unknown")
    ) +
    labs(
      x = NULL,
      y = "Percentage of Papers"
    ) +
    scale_y_continuous(
      labels = label_percent(scale = 1, accuracy = 1),
      expand = expansion(mult = c(0, 0.05))
    ) +
    scale_x_discrete(expand = expansion(add = c(0.5, 0.5))) +
    coord_flip() +
    theme_conference_facets() +
    theme(
      axis.text.x = element_text(size = 6),
      axis.text.y = element_text(size = 8, face = "bold")
    )
}

# =============================================================================
# ORDERING UTILITIES
# =============================================================================

#' Order conferences by North America percentage
#' @param df Dataframe with Conference, continent column, and percentage column
#' @param continent_col Name of continent column
#' @param percentage_col Name of percentage column
#' @return Dataframe with Conference as ordered factor
order_by_na_percentage <- function(df, continent_col, percentage_col) {
  na_ordering <- df %>%
    filter(.data[[continent_col]] == "North America") %>%
    arrange(desc(.data[[percentage_col]])) %>%
    pull(Conference) %>%
    unique()
  
  df %>%
    mutate(Conference = factor(Conference, levels = na_ordering))
}

# =============================================================================
# COMPLETE PIPELINE FUNCTIONS
# =============================================================================

#' Complete pipeline: Load papers data and create distribution plot
#' @param csv_path Path to papers CSV
#' @param output_path Output PDF path
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @return ggplot object
pipeline_papers_distribution <- function(csv_path, output_path,
                                        width = PLOT_WIDTH_WIDE,
                                        height = PLOT_HEIGHT_WIDE) {
  
  # Load and process data
  df <- load_csv_data(csv_path) %>%
    rename(Predominant_Continent = `Predominant Continent`) %>%
    process_paper_continents("Predominant_Continent")
  
  # Calculate percentages
  df_stats <- calculate_continent_percentages(df)
  
  # Apply labels (this converts Continent codes to readable names)
  df_plot <- apply_readable_labels(df_stats, apply_conference_mapping = TRUE)
  
  # Order by North America percentage (after labels are applied)
  df_plot <- order_by_na_percentage(df_plot, "Continent", "Percentage")
  
  # Create plot
  plot <- create_continent_stacked_bars(
    df_plot,
    y_label = "Percentage of Papers",
    show_unknown = FALSE,
    use_patterns = FALSE
  )
  
  # Save
  save_conference_plot(plot, output_path, width, height)
  
  plot
}

#' Complete pipeline: Load committee data and create distribution plot
#' @param csv_path Path to committee CSV
#' @param output_path Output PDF path
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @return ggplot object
pipeline_committee_distribution <- function(csv_path, output_path,
                                           width = PLOT_WIDTH_STANDARD,
                                           height = PLOT_HEIGHT_STANDARD) {
  
  # Load and process data
  df <- load_csv_data(csv_path) %>%
    mutate(
      Continent_Clean = case_when(
        is.na(Continent) ~ "Unknown",
        Continent %in% c("NA", "EU", "AS") ~ Continent,
        Continent %in% c("SA", "OC", "AF") ~ "Others",
        TRUE ~ "Unknown"
      )
    )
  
  # Calculate percentages
  df_stats <- calculate_continent_percentages(df, "Continent_Clean")
  
  # Apply labels (this converts Continent codes to readable names)
  df_plot <- apply_readable_labels(df_stats, apply_conference_mapping = TRUE)
  
  # Order by North America percentage (after labels are applied)
  df_plot <- order_by_na_percentage(df_plot, "Continent", "Percentage")
  
  # Create plot
  plot <- create_continent_stacked_bars(
    df_plot,
    y_label = "Percentage of Members",
    show_unknown = FALSE,
    use_patterns = FALSE
  )
  
  # Save
  save_conference_plot(plot, output_path, width, height)
  
  plot
}

# Plot utilities loaded

