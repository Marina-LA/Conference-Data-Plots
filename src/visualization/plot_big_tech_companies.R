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
  file.path(dirname(dirname(script_dir)), "outputs", "plots", "tech_companies_accepted_papers.pdf")
} else {
  file.path(script_dir, "outputs", "plots", "tech_companies_accepted_papers.pdf")
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
      Conference = recode(Conference, !!!CONFERENCE_MAPPING)
    )
  
  # Calculate aggregated percentages across all years for each conference
  df_aggregated <- df_clean %>%
    group_by(Conference, level_2) %>%
    summarise(
      percentage = mean(percentage, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Calculate known total for each conference (aggregated)
  known_sum <- df_aggregated %>%
    group_by(Conference) %>%
    summarise(known_total = sum(percentage, na.rm = TRUE), .groups = "drop")
  
  # Calculate remainder (unknown percentage)
  remainder <- known_sum %>%
    mutate(
      percentage = pmax(0, 100 - known_total),
      level_2 = "pct_unknown"
    ) %>%
    filter(percentage > 0) %>%
    select(Conference, level_2, percentage)
  
  # Combine and prepare final dataset
  df_final <- bind_rows(
    df_aggregated %>% select(Conference, level_2, percentage),
    remainder
  ) %>%
    mutate(
      level_2 = factor(level_2, levels = c("pct_unknown", "pct_has_big", "pct_no_big"))
    ) %>%
    arrange(Conference, desc(level_2))
  
  # Order conferences by big tech percentage (aggregated)
  conference_order_by_big <- df_final %>%
    filter(level_2 == "pct_has_big") %>%
    arrange(desc(percentage)) %>%
    pull(Conference)
  
  # Add Year column with "All Years" value to maintain compatibility
  df_final %>%
    mutate(
      Conference = factor(Conference, levels = conference_order_by_big),
      Year = "All Years"
    ) %>%
    filter(!is.na(Conference)) %>%
    arrange(Conference, level_2) %>%
    select(Conference, Year, level_2, percentage)
}

# =============================================================================
# PLOT CREATION
# =============================================================================

create_bigtech_plot <- function(data) {
  ggplot(data, aes(x = Conference, y = percentage, fill = level_2)) +
  geom_bar(stat = "identity", width = 0.7) +
  scale_fill_manual(
    values = CATEGORY_COLORS,
    labels = CATEGORY_LABELS,
		breaks = c("pct_has_big", "pct_no_big") 
  ) +
  scale_y_continuous(
    breaks = seq(0, 100, 10),
    labels = function(x) paste0(x, "%"),
    expand = c(0, 0),
    limits = c(0, 100)
  ) +
  labs(
    y = "Percentage of Papers",
    x = NULL
  ) +
  theme_minimal(base_size = 10, base_family = "serif") +
  theme(
    axis.text.x = element_text(
      angle = 45,
      vjust = 1,
      hjust = 1,
      size = 8
    ),
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

