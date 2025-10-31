# Conference Data Analysis

<div align="center">
    <img src="logo.png" alt="Conference Data Analysis" width="500">
</div>

## Overview

This project analyzes geographic diversity in academic conferences, examining the distribution of accepted papers and program committee members across continents. The analysis covers 13 major systems conferences and provides insights into geographical representation patterns over time.

## Quick Start

Run the complete analysis pipeline:

```bash
python run_full_analysis.py
```

Processes conference data, generates datasets, and creates visualizations. Runtime: 5-7 minutes.

## Requirements

- Python 3.8 or higher
- R 4.0 or higher (for visualization generation)

Install Python dependencies:

```bash
pip install -r requirements.txt
```

Python packages: pandas, pycountry  
R packages: tidyverse, ggplot2, scales (auto-installed on first run)

## Project Structure

```
ConferenceData/
├── run_full_analysis.py      # Main execution script
├── requirements.txt           # Python dependencies
│
├── data/
│   ├── raw/                   # Source data (not modified)
│   │   ├── crawler/           # Conference papers data
│   │   └── committees/        # Committee member data
│   └── processed/             # Generated datasets
│       ├── json/              # Processed conference files
│       └── csv/               # Unified analysis datasets
│
├── src/                       # Source code
│   ├── config/                # Configuration files
│   ├── utils/                 # Utility functions
│   ├── processors/            # Data processing modules
│   └── visualization/         # R visualization scripts
│
└── outputs/
    ├── plots/                 # Generated visualizations (PDF)
    └── csv/                   # Analysis results (CSV)
```

## What Gets Generated

### Processed Datasets

In `data/processed/csv/`:

- **unifiedPaperData.csv** - All accepted papers with continent information
- **unifiedCommitteeData.csv** - All committee members with continent data  
- **unifiedCitationsData.csv** - Citation analysis data

### Visualizations

In `outputs/plots/`:

1. **accepted_papers_continent_distribution.pdf** - Distribution of accepted papers by continent for each conference
2. **committee_continent_distribution.pdf** - Distribution of committee members by continent
3. **asian_trend.pdf** - Temporal trend of Asian representation across conferences
4. **citations_distribution.pdf** - Comparison of paper and citation patterns
5. **gini_simpson_diversity_index.pdf** - Diversity metrics for each conference
6. **tech_companies_accepted_papers.pdf** - Big Tech vs Academic participation in papers
7. **tech_companies_by_continent_accepted_papers.pdf** - Big Tech participation by continent
8. **papers_vs_committee_continent_gap.pdf** - Heatmap showing committee-paper geographic gaps

### Analysis Results

In `outputs/csv/`:

- **big_tech_analysis.csv** - Participation metrics for major technology companies

## Conferences Analyzed

The analysis includes the following conferences:

**Tier 1:** NSDI, SIGCOMM, OSDI, ASPLOS, EuroSys, ATC  
**Additional:** IC2E, ICDCS, Middleware, IEEE Cloud, CCGRID, Euro-Par, SoCC

## Pipeline Steps

The main script executes these steps in sequence:

1. **Data Processing** - Processes raw conference data and calculates predominant continent for each paper based on author affiliations
2. **CSV Generation** - Creates unified datasets combining all conferences
3. **Big Tech Analysis** - Identifies and analyzes participation of major technology companies
4. **R Package Verification** - Ensures required R packages are installed
5. **Visualization Generation** - Creates all analysis plots

## Usage Examples

### Run Complete Pipeline

```bash
python run_full_analysis.py
```

### Run Individual Components

Process data only:
```bash
python -m src.processors.data_reducer
```

Generate CSV files only:
```bash
python -m src.processors.csv_generator
```

Generate a specific plot:
```bash
Rscript src/visualization/plot_papers_distribution.R
```

## Configuration

### Python Settings

Edit `src/config/constants.py` to modify:
- Conference list and mappings
- Company classification rules
- Continent mappings
- Color schemes

### R Settings

Edit `src/config/config.R` to modify:
- Plot dimensions and styling
- Color palettes
- Theme configurations

## Data Sources

1. **Conference Papers** - Author names, affiliations, and paper metadata from proceedings
2. **Committee Information** - Program committee member names and institutional affiliations

Geographic information is normalized to continent-level granularity.

## Methodology

### Geographic Classification

Affiliation mapping process:
1. Extract institution from author metadata
2. Identify country from institution
3. Map to continent (ISO 3166)
4. Calculate predominant continent for multi-author papers (majority rule)

### Continent Grouping

- **North America** (NA) - United States, Canada, Mexico
- **Europe** (EU) - All European countries
- **Asia** (AS) - Asian countries including Middle East
- **Others** - Oceania, Africa, South America
- **Unknown** - Missing or unresolved geographic data

### Company Classification

Technology companies identified via pattern matching on affiliations. Classifies institutions as industry or academic.

## Code Organization

Modular architecture:

- **src/config/** - Configuration (Python and R)
- **src/utils/** - Shared utilities
- **src/processors/** - Data processing modules
- **src/visualization/** - R visualization scripts

Design: separation of concerns, reusable components, type hints, consistent naming.

## Troubleshooting

**Module not found:**
- Run from ConferenceData directory
- Install dependencies: `pip install -r requirements.txt`

**Missing data:**
- Verify `data/raw/` contains input files
- Check directory structure matches layout

**R errors:**
- R must be in system PATH
- R packages auto-install on first run
- Data processing works without R

## Output Interpretation

**Distribution plots:** Stacked bars show percentage by continent. Ordered by North American representation (descending). Unknown data in white.

**Trend analysis:** Line plots show geographic distribution over time. Each conference in separate facet, focal conference highlighted.

**Diversity index:** Gini-Simpson index (0-1 scale). 0 = no diversity, 1 = maximum diversity. Higher = more balanced representation.

## Version

Current version: 2.0  
Last updated: October 2025

---

For questions or issues, please refer to the source code documentation or open an issue in the repository.
