# =============================================================================
# Big Tech Companies by Continent - Accepted Papers Distribution
# =============================================================================

script_dir <- tryCatch({
  dirname(sys.frame(1)$ofile)
}, error = function(e) {
  getwd()
})

if (basename(script_dir) == "visualization") {
  source(file.path(script_dir, "plot_utils.R"))
  source(file.path(dirname(script_dir), "config", "config.R"))
} else {
  source(file.path(script_dir, "src", "visualization", "plot_utils.R"))
  source(file.path(script_dir, "src", "config", "config.R"))
}

# =============================================================================
# CONFIGURATION
# =============================================================================

INPUT_CSV_CONTINENT <- if (basename(script_dir) == "visualization") {
  file.path(dirname(dirname(script_dir)), "outputs", "csv", "big_companies_by_continent_analysis.csv")
} else {
  file.path(script_dir, "outputs", "csv", "big_companies_by_continent_analysis.csv")
}

INPUT_CSV_MAIN <- if (basename(script_dir) == "visualization") {
  file.path(dirname(dirname(script_dir)), "outputs", "csv", "big_tech_analysis.csv")
} else {
  file.path(script_dir, "outputs", "csv", "big_tech_analysis.csv")
}

OUTPUT_PDF <- if (basename(script_dir) == "visualization") {
  file.path(dirname(dirname(script_dir)), "outputs", "plots", "tech_companies_by_continent_accepted_papers.pdf")
} else {
  file.path(script_dir, "outputs", "plots", "tech_companies_by_continent_accepted_papers.pdf")
}

CATEGORY_COLORS <- c(
  "pct_big_na" = "#FF6B6B",
  "pct_big_eu" = "#4ECDC4",
  "pct_big_as" = "#FFE66D",
  "pct_big_other" = "#95E1D3",
  "pct_no_big" = "#1f3b6f",
  "pct_unknown" = "#FFFFFF"
)

CATEGORY_LABELS <- c(
  "pct_big_na" = "Big Tech (NA)",
  "pct_big_eu" = "Big Tech (EU)",
  "pct_big_as" = "Big Tech (AS)",
  "pct_big_other" = "Big Tech (Other)",
  "pct_no_big" = "Academic"
)

# =============================================================================
# DATA PROCESSING
# =============================================================================

process_bigtech_continent_data <- function(csv_path_continent, csv_path_main) {
  df <- read.csv(csv_path_continent, na.strings = "")
  df_main <- read.csv(csv_path_main, na.strings = "")
  
  all_categories <- c("pct_big_na", "pct_big_eu", "pct_big_as", "pct_big_other", "pct_no_big")
  
  df_base <- df %>%
    filter(level_2 %in% all_categories) %>%
    rename(percentage = X0) %>%
    mutate(Conference_lower = tolower(Conference))
  
  all_combo <- df_base %>%
    select(Conference_lower, Year) %>%
    distinct()
  
  complete_grid <- expand.grid(
    Conference_lower = unique(all_combo$Conference_lower),
    Year = unique(all_combo$Year),
    level_2 = all_categories,
    stringsAsFactors = FALSE
  )
  
  df_clean <- complete_grid %>%
    left_join(
      df_base %>% select(Conference_lower, Year, level_2, percentage),
      by = c("Conference_lower", "Year", "level_2")
    ) %>%
    mutate(percentage = ifelse(is.na(percentage), 0, percentage)) %>%
    mutate(
      Conference = recode(Conference_lower, !!!CONFERENCE_MAPPING),
      level_2 = factor(level_2, levels = c("pct_big_na", "pct_big_eu", "pct_big_as", "pct_big_other", "pct_no_big"))
    ) %>%
    select(Conference, Year, level_2, percentage)
  
  df_main_clean <- df_main %>%
    mutate(
      Conference = tolower(Conference),
      Conference = recode(Conference, !!!CONFERENCE_MAPPING)
    ) %>%
    select(Conference, Year, pct_has_big, pct_no_big, pct_all_none)
  
  big_totals <- df_clean %>%
    filter(level_2 %in% c("pct_big_na", "pct_big_eu", "pct_big_as", "pct_big_other")) %>%
    group_by(Conference, Year) %>%
    summarise(big_sum = sum(percentage, na.rm = TRUE), .groups = "drop")
  
  df_scaled <- df_clean %>%
    left_join(big_totals, by = c("Conference", "Year")) %>%
    left_join(df_main_clean, by = c("Conference", "Year")) %>%
    mutate(
      scale_factor = ifelse(level_2 %in% c("pct_big_na", "pct_big_eu", "pct_big_as", "pct_big_other") & big_sum > 0,
                            pct_has_big / big_sum, 1)
    ) %>%
    mutate(
      percentage = ifelse(level_2 %in% c("pct_big_na", "pct_big_eu", "pct_big_as", "pct_big_other"),
                          percentage * scale_factor, percentage)
    ) %>%
    select(Conference, Year, level_2, percentage, pct_no_big, pct_all_none)
  
  df_academic_unknown <- df_scaled %>%
    select(Conference, Year, pct_no_big, pct_all_none) %>%
    distinct() %>%
    tidyr::pivot_longer(cols = c(pct_no_big, pct_all_none), names_to = "level_2", values_to = "percentage") %>%
    mutate(level_2 = dplyr::recode(level_2, pct_no_big = "pct_no_big", pct_all_none = "pct_unknown"))
  
  df_plot <- bind_rows(
    df_scaled %>% filter(level_2 %in% c("pct_big_na", "pct_big_eu", "pct_big_as", "pct_big_other")) %>% select(Conference, Year, level_2, percentage),
    df_academic_unknown %>% select(Conference, Year, level_2, percentage)
  ) %>%
    mutate(
      level_2 = factor(level_2, levels = c("pct_unknown", "pct_big_na", "pct_big_eu", "pct_big_as", "pct_big_other", "pct_no_big"))
    ) %>%
    arrange(Conference, Year, level_2)
  
  totals <- df_plot %>%
    group_by(Conference, Year) %>%
    summarise(total = sum(percentage, na.rm = TRUE), .groups = "drop") %>%
    mutate(correction = 100 - total)
  
  df_plot <- df_plot %>%
    left_join(totals %>% select(Conference, Year, correction), by = c("Conference", "Year")) %>%
    mutate(
      percentage = ifelse(level_2 == "pct_no_big", percentage + correction, percentage)
    ) %>%
    select(-correction)
  
  conference_order_by_big <- df_main_clean %>%
    group_by(Conference) %>%
    summarise(mean_big_pct = mean(pct_has_big, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(mean_big_pct)) %>%
    pull(Conference)
  
  df_plot %>%
    mutate(Conference = factor(Conference, levels = conference_order_by_big)) %>%
    filter(!is.na(Conference))
}

# =============================================================================
# PLOT CREATION
# =============================================================================

create_bigtech_continent_plot <- function(data) {
  ggplot(data, aes(x = factor(Year), y = percentage, fill = level_2)) +
    geom_bar(stat = "identity", width = 0.7, position = "stack") +
    facet_wrap(~ Conference, nrow = 3, ncol = 5) +
    scale_fill_manual(
      name = NULL,
      values = CATEGORY_COLORS,
      labels = CATEGORY_LABELS,
      breaks = c("pct_big_na", "pct_big_eu", "pct_big_as", "pct_big_other", "pct_no_big")
    ) +
    scale_y_continuous(limits = c(0, 100)) +
    labs(y = "Percentage of Papers") +
    theme_minimal(base_size = 10, base_family = "serif") +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 0.5, 
                                  size = 6, margin = margin(t = -4)),
      axis.title.x = element_blank(),
      axis.ticks.length.x = unit(0.1, "cm"),
      legend.position = "top",
      legend.key.size = unit(0.25, "cm"),
      legend.title = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(linewidth = 0.2),
      text = element_text(family = "serif"),
      plot.margin = margin(t = 10, r = 10, b = 10, l = 10)
    )
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

if (!file.exists(INPUT_CSV_CONTINENT)) {
  stop("Input file not found: ", INPUT_CSV_CONTINENT)
}
if (!file.exists(INPUT_CSV_MAIN)) {
  stop("Input file not found: ", INPUT_CSV_MAIN)
}

data <- process_bigtech_continent_data(INPUT_CSV_CONTINENT, INPUT_CSV_MAIN)
plot <- create_bigtech_continent_plot(data)

dir.create(dirname(OUTPUT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUTPUT_PDF, plot = plot, device = "pdf", width = 6.99, height = 3.5, units = "in")

