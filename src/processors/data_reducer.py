"""
Data Reducer for Conference Data Analysis project.
Processes extended crawler data into reduced/processed format.
"""

import logging
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass

from src.utils.file_manager import FileManager
from src.utils.continent_mapper import ContinentMapper
from src.config.constants import DATA_DIRS

logger = logging.getLogger(__name__)


@dataclass
class ProcessingStats:
    """Statistics from data processing."""
    total_papers: int = 0
    papers_with_continent: int = 0
    papers_without_sufficient_data: int = 0
    unknown_countries: int = 0


class DataReducer:
    """
    Processes extended crawler data into reduced format with essential fields.
    Calculates predominant continent for each paper.
    """
    
    def __init__(self, project_root: Path):
        """
        Initialize DataReducer.
        
        Args:
            project_root: Root directory of project
        """
        self.project_root = Path(project_root)
        self.file_manager = FileManager(project_root)
        self.continent_mapper = ContinentMapper()
        
    def process_paper(self, paper: Dict, year: str) -> tuple[Dict, ProcessingStats]:
        """
        Process a single paper to extract essential fields.
        
        Args:
            paper: Paper data dictionary
            year: Publication year
            
        Returns:
            Tuple of (processed_paper_dict, processing_stats)
        """
        stats = ProcessingStats()
        stats.total_papers = 1
        
        # Extract authors and institutions
        authors_list = paper.get("Authors and Institutions", [])
        
        # Calculate predominant continent
        pred_continents = []
        no_inst_authors = 0
        unknown_country = 0
        
        if authors_list:
            pred_continents, no_inst_authors, unknown_country = \
                self.continent_mapper.get_predominant_continent(authors_list)
            
            # Track statistics
            if no_inst_authors > 0 or unknown_country > 0:
                sum_error = no_inst_authors + unknown_country
                if sum_error >= len(authors_list) / 2:
                    stats.papers_without_sufficient_data += 1
                    
            stats.unknown_countries += unknown_country
            
        if pred_continents:
            stats.papers_with_continent = 1
            
        # Build processed paper data
        processed_paper = {
            "Title": paper.get("Title", ""),
            "Year": paper.get("Year", year),
            "Predominant Continent": pred_continents,
            "Authors and Institutions": authors_list
        }
        
        return processed_paper, stats
        
    def process_conference(self, conference: str, 
                          extended_data: Dict) -> tuple[Dict, ProcessingStats]:
        """
        Process all papers for a conference.
        
        Args:
            conference: Conference name
            extended_data: Extended crawler data (dict by year)
            
        Returns:
            Tuple of (processed_data_by_year, total_stats)
        """
        logger.info(f"Processing conference: {conference}")
        
        data_per_year = {}
        total_stats = ProcessingStats()
        
        for year, papers in extended_data.items():
            year_papers = []
            
            for paper in papers:
                processed_paper, paper_stats = self.process_paper(paper, year)
                year_papers.append(processed_paper)
                
                # Accumulate stats
                total_stats.total_papers += paper_stats.total_papers
                total_stats.papers_with_continent += paper_stats.papers_with_continent
                total_stats.papers_without_sufficient_data += paper_stats.papers_without_sufficient_data
                total_stats.unknown_countries += paper_stats.unknown_countries
                
            data_per_year[year] = year_papers
            
            # Log year stats
            year_total = len(papers)
            if year_total > 0:
                logger.debug(f"  Year {year}: {year_total} papers processed")
                
        # Log conference summary
        if total_stats.total_papers > 0:
            sufficient_data_pct = (total_stats.papers_with_continent / 
                                  total_stats.total_papers * 100)
            logger.info(f"  Total: {total_stats.total_papers} papers, "
                       f"{sufficient_data_pct:.1f}% with continent data")
            
        return data_per_year, total_stats
        
    def process_all_conferences(self) -> Dict[str, ProcessingStats]:
        """
        Process all conferences from ExtendedCrawlerData to ProcessedData.
        
        Returns:
            Dictionary of conference -> stats
        """
        extended_dir = self.project_root / DATA_DIRS["crawler_extended"]
        output_dir = self.project_root / DATA_DIRS["processed"]
        
        if not extended_dir.exists():
            raise FileNotFoundError(f"Extended data directory not found: {extended_dir}")
            
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Find all conferences
        conferences = self.file_manager.get_conferences_from_directory(
            extended_dir, "_extended_data.json"
        )
        
        if not conferences:
            logger.warning(f"No conferences found in {extended_dir}")
            return {}
            
        logger.info(f"Found {len(conferences)} conferences to process")
        
        # Process each conference
        all_stats = {}
        
        for conference in conferences:
            input_path = extended_dir / f"{conference}_extended_data.json"
            output_path = output_dir / f"{conference}_data.json"
            
            try:
                # Load extended data
                extended_data = self.file_manager.load_json(input_path)
                
                # Process conference
                processed_data, stats = self.process_conference(conference, extended_data)
                
                # Save processed data
                self.file_manager.save_json(output_path, processed_data)
                logger.info(f"Saved: {output_path.name}")
                
                all_stats[conference] = stats
                
            except Exception as e:
                logger.error(f"Failed to process {conference}: {e}")
                continue
                
        return all_stats
        
    def generate_summary_report(self, stats: Dict[str, ProcessingStats]) -> str:
        """
        Generate summary report of processing results.
        
        Args:
            stats: Dictionary of conference -> stats
            
        Returns:
            Formatted summary report string
        """
        lines = [
            "=" * 70,
            "DATA PROCESSING SUMMARY",
            "=" * 70,
            ""
        ]
        
        total_papers = 0
        total_with_continent = 0
        
        for conference, conf_stats in sorted(stats.items()):
            total_papers += conf_stats.total_papers
            total_with_continent += conf_stats.papers_with_continent
            
            pct = (conf_stats.papers_with_continent / conf_stats.total_papers * 100 
                   if conf_stats.total_papers > 0 else 0)
            
            lines.append(f"{conference:15s}: {conf_stats.total_papers:4d} papers, "
                        f"{pct:5.1f}% with continent")
                        
        lines.extend([
            "",
            "-" * 70,
            f"{'TOTAL':15s}: {total_papers:4d} papers, "
            f"{total_with_continent / total_papers * 100 if total_papers > 0 else 0:5.1f}% "
            f"with continent",
            "=" * 70
        ])
        
        return "\n".join(lines)


def main():
    """Main entry point for data reducer."""
    import sys
    
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    # Get project root (assume script is in src/processors/)
    project_root = Path(__file__).parent.parent.parent
    
    # Process all conferences
    reducer = DataReducer(project_root)
    
    try:
        logger.info("Starting data reduction process...")
        stats = reducer.process_all_conferences()
        
        # Print summary
        summary = reducer.generate_summary_report(stats)
        print("\n" + summary)
        
        logger.info("Data reduction completed successfully!")
        return 0
        
    except Exception as e:
        logger.error(f"Data reduction failed: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())

