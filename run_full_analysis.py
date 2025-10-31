#!/usr/bin/env python3
"""
Conference Data Analysis - Main Pipeline

Processes conference data, generates unified datasets, and creates visualizations.

Usage:
    python run_full_analysis.py

Pipeline steps:
1. Process conference data
2. Generate CSV datasets
3. Analyze tech company participation
4. Verify R environment
5. Generate visualizations
"""

import sys
import logging
import time
from pathlib import Path
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent))

from src.processors.data_reducer import DataReducer
from src.processors.csv_generator import CSVGenerator
from src.processors.big_tech_analyzer import BigTechAnalyzer
from src.utils.file_manager import setup_project_directories

logging.basicConfig(
    level=logging.INFO,
    format='%(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def print_section_header(text, char="=", width=70):
    """Print formatted section header."""
    line = char * width
    print(f"\n{line}")
    print(f"  {text}")
    print(f"{line}\n")


def print_step_header(step, total, description, width=70):
    """Print formatted step header."""
    separator = "-" * width
    print(f"\nSTEP {step}/{total}: {description}")
    print(separator)


def main():
    """Execute complete analysis pipeline."""
    start_time = time.time()
    project_root = Path(__file__).parent
    
    print_section_header("CONFERENCE DATA ANALYSIS PIPELINE v2.0")
    print(f"Execution started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Working directory: {project_root}\n")
    
    logger.info("Initializing project directories")
    setup_project_directories(project_root)
    logger.info("Directory structure ready")
    
    total_steps = 5
    
    # Step 1: Data Processing
    print_step_header(1, total_steps, "DATA PROCESSING")
    logger.info("Processing extended crawler data")
    logger.info("Calculating predominant continents for each paper")
    
    try:
        reducer = DataReducer(project_root)
        stats = reducer.process_all_conferences()
        
        summary = reducer.generate_summary_report(stats)
        print(summary)
        
        logger.info("Data processing completed successfully")
        
    except Exception as e:
        logger.error(f"Data processing failed: {e}")
        return 1
    
    # Step 2: CSV Generation
    print_step_header(2, total_steps, "CSV GENERATION")
    logger.info("Generating unified CSV files")
    
    try:
        generator = CSVGenerator(project_root)
        results = generator.generate_all_csvs()
        
        for csv_type, result in results.items():
            if result.success:
                logger.info(f"{csv_type}: {result.row_count} records generated")
            else:
                logger.error(f"{csv_type}: {result.error}")
                
        logger.info("CSV generation completed")
        
    except Exception as e:
        logger.error(f"CSV generation failed: {e}")
        return 1
    
    # Step 3: Big Tech Analysis
    print_step_header(3, total_steps, "BIG TECH ANALYSIS")
    logger.info("Analyzing presence of major technology companies")
    
    try:
        analyzer = BigTechAnalyzer(project_root)
        results = analyzer.analyze_all_conferences()
        analyzer.generate_csv()
        analyzer.generate_continent_csv()
        
        summary = analyzer.generate_summary_report(results)
        print(summary)
        
        logger.info("Big tech analysis completed")
        
    except Exception as e:
        logger.warning(f"Big tech analysis warning: {e}")
        logger.info("Continuing pipeline execution")
    
    # Step 4: R Environment Check
    print_step_header(4, total_steps, "R ENVIRONMENT VERIFICATION")
    logger.info("Checking R installation and packages")
    
    try:
        import subprocess
        
        r_paths = [
            r"C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe",
            r"C:\Program Files\R\R-4.5.0\bin\x64\Rscript.exe",
            "Rscript"
        ]
        
        rscript = None
        for path in r_paths:
            if Path(path).exists() if path.startswith("C:") else True:
                rscript = path
                break
                
        if not rscript:
            logger.warning("Rscript not found - plots will not be generated")
        else:
            logger.info(f"R installation found: {rscript}")
            
            check_cmd = """
            required <- c("tidyverse", "ggplot2", "dplyr", "scales", "ggpattern")
            missing <- required[!(required %in% installed.packages()[,"Package"])]
            if(length(missing) > 0) {
                cat("Installing missing packages:", paste(missing, collapse=", "), "\\n")
                install.packages(missing, repos="https://cloud.r-project.org", quiet=TRUE)
            } else {
                cat("All required packages installed\\n")
            }
            """
            
            result = subprocess.run(
                [rscript, "-e", check_cmd],
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.stdout:
                logger.info(result.stdout.strip())
                
    except Exception as e:
        logger.warning(f"R verification warning: {e}")
    
    logger.info("R environment check completed")
    
    # Step 5: Visualization Generation
    print_step_header(5, total_steps, "VISUALIZATION GENERATION")
    logger.info("Generating all visualizations")
    
    plots_config = [
        ("plot_papers_distribution.R", "Papers distribution by continent"),
        ("plot_committee_distribution.R", "Committee distribution by continent"),
        ("plot_asian_trend.R", "Asian papers trend analysis"),
        ("plot_citations_distribution.R", "Accepted vs cited papers comparison"),
        ("plot_gini_simpson.R", "Gini-Simpson diversity index"),
        ("plot_big_tech_companies_by_year.R", "Big Tech vs Academic papers for each year"),
        ("plot_big_tech_by_continent.R", "Big Tech by continent"),
        ("plot_committee_papers_heatmap.R", "Committee vs Papers heatmap"),
        ("plot_big_tech_companies.R", "Big Tech Companies Analysis"),
        ("plot_asian_trend_distribution.R", "Asian Papers Distribution Trend"),
    ]
    
    generated_count = 0
    failed_count = 0
    
    for script, description in plots_config:
        script_path = project_root / "src" / "visualization" / script
        
        if not script_path.exists():
            logger.warning(f"Script not found: {script}")
            failed_count += 1
            continue
            
        try:
            logger.info(f"Generating: {description}")
            
            result = subprocess.run(
                [rscript, str(script_path)],
                cwd=project_root,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                logger.info(f"Successfully generated: {script}")
                generated_count += 1
            else:
                logger.error(f"Failed to generate {script}: {result.stderr[:100]}")
                failed_count += 1
                
        except Exception as e:
            logger.error(f"Error generating {script}: {str(e)[:100]}")
            failed_count += 1
    
    logger.info(f"Plots generated: {generated_count}/{len(plots_config)}")
    if failed_count > 0:
        logger.warning(f"Plots failed: {failed_count}")
        
    logger.info("Visualization generation completed")
    
    # Pipeline Summary
    elapsed = time.time() - start_time
    minutes = int(elapsed // 60)
    seconds = int(elapsed % 60)
    
    print_section_header("PIPELINE EXECUTION COMPLETED")
    
    print("Generated Files:")
    print("\nProcessed Data:")
    print("  - ProcessedData/*_data.json (13 conferences)")
    print("\nUnified CSVs:")
    print("  - ProcessedData/unifiedPaperData.csv")
    print("  - ProcessedData/unifiedCommitteeData.csv")
    print("  - ProcessedData/unifiedCitationsData.csv")
    print("  - outputs/csv/big_tech_analysis.csv")
    print("\nVisualizations:")
    print("  - outputs/plots/accepted_papers_continent_distribution.pdf")
    print("  - outputs/plots/committee_continent_distribution.pdf")
    print("  - outputs/plots/asian_trend.pdf")
    print("  - outputs/plots/citations_distribution.pdf")
    print("  - outputs/plots/gini_simpson_diversity_index.pdf")
    print(f"\nExecution time: {minutes}m {seconds}s")
    print("\nResults location: outputs/plots/")
    print("=" * 70)
    
    return 0


if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n\nPipeline interrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\n\nUnexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
