# =============================================================================
# Big Tech Companies Analysis - Accepted Papers Distribution
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

INPUT_CSV <- if (basename(script_dir) == "visualization") {
  file.path(dirname(dirname(script_dir)), "outputs", "csv", "big_tech_analysis.csv")
} else {
  file.path(script_dir, "outputs", "csv", "big_tech_analysis.csv")
}

OUTPUT_PDF <- if (basename(script_dir) == "visualization") {
  file.path(dirname(dirname(script_dir)), "outputs", "plots", "tech_companies_accepted_papers_by_year.pdf")
} else {
  file.path(script_dir, "outputs", "plots", "tech_companies_accepted_papers_by_year.pdf")
}

CATEGORY_COLORS <- c(
  "pct_has_big" = "#c5c5c5",
  "pct_no_big" = "#1f3b6f",
  "pct_unknown" = "#FFFFFF"
)

CATEGORY_LABELS <- c(
  "pct_has_big" = "Big Tech",
  "pct_no_big" = "Academic"
)

# =============================================================================
# DATA PROCESSING
# =============================================================================

process_bigtech_data <- function(csv_path) {
  df <- read.csv(csv_path, na.strings = "")
  
  # Transform from wide to long format
  df_long <- df %>%
    tidyr::pivot_longer(
      cols = c(pct_has_big, pct_no_big, pct_all_none),
      names_to = "level_2",
      values_to = "percentage"
    )
  
  df_clean <- df_long %>%
    filter(level_2 %in% c("pct_has_big", "pct_no_big")) %>%
    mutate(
      Conference = tolower(Conference),
      Conference = recode(Conference, !!!CONFERENCE_MAPPING),
      level_2 = factor(level_2, levels = c("pct_has_big", "pct_no_big"))
    )
  
  known_sum <- df_clean %>%
    group_by(Conference, Year) %>%
    summarise(known_total = sum(percentage, na.rm = TRUE), .groups = "drop")
  
  remainder <- known_sum %>%
    mutate(
      percentage = pmax(0, 100 - known_total),
      level_2 = "pct_unknown"
    ) %>%
    filter(percentage > 0) %>%
    select(Conference, Year, level_2, percentage)
  
  df_clean <- bind_rows(
    df_clean %>% select(Conference, Year, level_2, percentage),
    remainder
  ) %>%
    mutate(
      level_2 = factor(level_2, levels = c("pct_unknown", "pct_has_big", "pct_no_big"))
    ) %>%
    arrange(Conference, Year, desc(level_2))
  
  conference_order_by_big <- df_clean %>%
    filter(level_2 == "pct_has_big") %>%
    group_by(Conference) %>%
    summarise(mean_big_pct = mean(percentage, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(mean_big_pct)) %>%
    pull(Conference)
  
  df_clean %>%
    mutate(Conference = factor(Conference, levels = conference_order_by_big)) %>%
    filter(!is.na(Conference)) %>%
    arrange(Conference, Year, level_2)
}

# =============================================================================
# PLOT CREATION
# =============================================================================

create_bigtech_plot <- function(data) {
  ggplot(data, aes(x = factor(Year), y = percentage, fill = level_2)) +
    geom_bar(stat = "identity", width = 0.7, position = "stack") +
    facet_wrap(~ Conference, nrow = 3, ncol = 5) +
    scale_fill_manual(
      name = NULL,
      values = CATEGORY_COLORS,
      labels = CATEGORY_LABELS,
      breaks = c("pct_has_big", "pct_no_big")
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

if (!file.exists(INPUT_CSV)) {
  stop("Input file not found: ", INPUT_CSV)
}

data <- process_bigtech_data(INPUT_CSV)
plot <- create_bigtech_plot(data)

dir.create(dirname(OUTPUT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUTPUT_PDF, plot = plot, device = "pdf", width = 6.99, height = 3.5, units = "in")

