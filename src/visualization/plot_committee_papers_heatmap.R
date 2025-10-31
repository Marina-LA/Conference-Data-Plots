# =============================================================================
# Committee vs Papers Heatmap - Geographic Gap Analysis
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

INPUT_PAPERS <- if (basename(script_dir) == "visualization") {
  file.path(dirname(dirname(script_dir)), "data", "processed", "csv", "unifiedPaperData.csv")
} else {
  file.path(script_dir, "data", "processed", "csv", "unifiedPaperData.csv")
}

INPUT_COMMITTEE <- if (basename(script_dir) == "visualization") {
  file.path(dirname(dirname(script_dir)), "data", "processed", "csv", "unifiedCommitteeData.csv")
} else {
  file.path(script_dir, "data", "processed", "csv", "unifiedCommitteeData.csv")
}

OUTPUT_PDF <- if (basename(script_dir) == "visualization") {
  file.path(dirname(dirname(script_dir)), "outputs", "plots", "papers_vs_committee_continent_gap.pdf")
} else {
  file.path(script_dir, "outputs", "plots", "papers_vs_committee_continent_gap.pdf")
}

# =============================================================================
# DATA PROCESSING
# =============================================================================

normalize_text <- function(x) {
  x <- ifelse(is.na(x) | x == "", "unknown", as.character(x))
  x <- gsub("\\s+", " ", trimws(tolower(x)))
  x
}

normalize_conference <- function(x) {
  x <- ifelse(is.na(x) | x == "", "", x)
  x <- tolower(x)
  x <- gsub("[\u2012\u2013\u2014\u2212]", "-", x)
  x <- gsub("\\s+", " ", trimws(x))
  x
}

process_heatmap_data <- function(papers_path, committee_path) {
  papers <- read.csv(papers_path, stringsAsFactors = FALSE, na.strings = "")
  committee <- read.csv(committee_path, stringsAsFactors = FALSE, na.strings = "")
  
  papers <- papers %>%
    mutate(Continent = normalize_text(Predominant.Continent),
           Conference = normalize_conference(Conference)) %>%
    select(Conference, Year, Continent)
  
  committee <- committee %>%
    mutate(Continent = normalize_text(Continent),
           Conference = normalize_conference(Conference)) %>%
    select(Conference, Year, Continent)
  
  papers_counts <- papers %>%
    group_by(Conference, Continent) %>%
    summarise(n = n(), .groups = "drop")
  
  papers_totals <- papers_counts %>%
    group_by(Conference) %>%
    summarise(total = sum(n), .groups = "drop")
  
  papers_pct <- papers_counts %>%
    left_join(papers_totals, by = "Conference") %>%
    mutate(papers_pct = ifelse(total > 0, 100 * n / total, NA_real_)) %>%
    select(Conference, Continent, papers_pct)
  
  committee_counts <- committee %>%
    group_by(Conference, Continent) %>%
    summarise(n = n(), .groups = "drop")
  
  committee_totals <- committee_counts %>%
    group_by(Conference) %>%
    summarise(total = sum(n), .groups = "drop")
  
  committee_pct <- committee_counts %>%
    left_join(committee_totals, by = "Conference") %>%
    mutate(committee_pct = ifelse(total > 0, 100 * n / total, NA_real_)) %>%
    select(Conference, Continent, committee_pct)
  
  df <- full_join(papers_pct, committee_pct, by = c("Conference","Continent"))
  
  df <- df %>%
    mutate(Conference = tolower(Conference), 
           Conference = recode(Conference, !!!CONFERENCE_MAPPING)) %>%
    group_by(Conference, Continent) %>%
    summarise(
      papers_pct = dplyr::first(papers_pct),
      committee_pct = dplyr::first(committee_pct),
      .groups = "drop"
    )
  
  continent_map <- c(
    "na" = "North America",
    "north america" = "North America",
    "america" = "North America",
    "american" = "North America",
    "north_america" = "North America",
    "n. america" = "North America",
    "eu" = "Europe",
    "europe" = "Europe",
    "european" = "Europe",
    "as" = "Asia",
    "asia" = "Asia",
    "asian" = "Asia",
    "oc" = "Other",
    "oceania" = "Other",
    "af" = "Other",
    "africa" = "Other",
    "sa" = "Other",
    "south america" = "Other",
    "other" = "Other",
    "unknown" = "Other",
    "eu;na" = "Europe",
    "na;eu" = "North America",
    "as;na" = "Asia",
    "na;as" = "North America",
    "na;oc" = "North America",
    "as;eu" = "Asia",
    "as;oc" = "Asia"
  )
  
  df <- df %>% 
    mutate(Continent = recode(Continent, !!!continent_map))
  
  df <- df %>%
    group_by(Conference, Continent) %>%
    summarise(
      papers_pct = sum(papers_pct, na.rm = TRUE),
      committee_pct = sum(committee_pct, na.rm = TRUE),
      .groups = "drop"
    )
  
  df_mean <- df %>%
    mutate(
      papers_mean = papers_pct,
      committee_mean = committee_pct,
      gap = committee_pct - papers_pct
    ) %>%
    select(Conference, Continent, papers_mean, committee_mean, gap)
  
  continent_levels <- c("North America","Europe","Asia","Other")
  
  df_mean %>%
    mutate(
      Continent = factor(Continent, levels = continent_levels),
      Conference = factor(Conference, levels = CONFERENCE_ORDER)
    ) %>%
    tidyr::complete(Conference, Continent,
                    fill = list(papers_mean = NA_real_, committee_mean = NA_real_, gap = NA_real_))
}

# =============================================================================
# PLOT CREATION
# =============================================================================

create_heatmap_plot <- function(data) {
  ggplot(data, aes(x = Continent, y = Conference, fill = gap)) +
    geom_tile(color = "white", linewidth = 0.5) +
    scale_fill_gradient2(low = "#377eb8", mid = "#f7f7f7", high = "#e41a1c", midpoint = 0,
                         name = "Committee - Papers (pp)", na.value = "white") +
    geom_text(aes(label = ifelse(!is.na(gap), sprintf("%+.1f", gap), ""),
                  color = ifelse(!is.na(gap) & abs(gap) > 8, "on_dark", "on_light")),
              size = 3.2, family = "serif", na.rm = TRUE) +
    scale_color_manual(values = c(on_dark = "#FFFFFF", on_light = "#222222"), guide = "none") +
    labs(title = "Program Committee vs Accepted Papers - Continent Gap",
         subtitle = "Values in percentage points (pp). Red: Committee > Papers; Blue: Papers > Committee.",
         x = NULL, y = NULL) +
    theme_minimal(base_size = 12, base_family = "serif") +
    theme(
      legend.position = "top",
      axis.text.x = element_text(angle = 0, hjust = 0.5),
      panel.grid = element_blank(),
      plot.title = element_text(face = "bold"),
      plot.margin = margin(t = 10, r = 14, b = 10, l = 10)
    ) +
    scale_y_discrete(drop = FALSE)
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

if (!file.exists(INPUT_PAPERS)) {
  stop("Input file not found: ", INPUT_PAPERS)
}
if (!file.exists(INPUT_COMMITTEE)) {
  stop("Input file not found: ", INPUT_COMMITTEE)
}

data <- process_heatmap_data(INPUT_PAPERS, INPUT_COMMITTEE)
plot <- create_heatmap_plot(data)

n_conf <- length(unique(data$Conference))
pdf_height <- max(6, 0.35 * n_conf)

dir.create(dirname(OUTPUT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUTPUT_PDF, plot = plot, device = "pdf", width = 9.5, height = pdf_height, units = "in")


