"""
Big Tech Company Analysis Module
=================================
Analyzes the presence of big tech companies vs. academia in conference papers.
"""

import logging
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple
from dataclasses import dataclass

from src.utils.file_manager import FileManager
from src.config.constants import BIG_TECH_COMPANIES, DATA_DIRS

logger = logging.getLogger(__name__)


@dataclass
class BigTechStats:
    """Statistics for big tech company analysis."""
    total_papers: int = 0
    has_big_tech: int = 0
    no_big_tech: int = 0
    all_none: int = 0
    pct_has_big: float = 0.0
    pct_no_big: float = 0.0
    pct_all_none: float = 0.0


class BigTechAnalyzer:
    """
    Analyzes the presence of big tech companies in conference papers.
    
    This analyzer classifies papers into three categories:
    1. Has big tech company (at least one author from a big tech company)
    2. No big tech (all authors from academia or other institutions)
    3. All None (no institution data available)
    """
    
    def __init__(self, project_root: Path):
        """
        Initialize BigTechAnalyzer.
        
        Args:
            project_root: Root directory of project
        """
        self.project_root = Path(project_root)
        self.file_manager = FileManager(project_root)
        
        # Compile regex pattern for efficient matching
        self.company_pattern = self._compile_company_pattern()
        
    def _compile_company_pattern(self) -> re.Pattern:
        """
        Compile regex pattern for big tech company matching.
        
        Returns:
            Compiled regex pattern
        """
        # Escape special regex characters in company names
        escaped_companies = [re.escape(company) for company in BIG_TECH_COMPANIES]
        
        # Create pattern that matches whole words only
        pattern = r'(?<!\w)(' + '|'.join(escaped_companies) + r')(?!\w)'
        
        return re.compile(pattern, re.IGNORECASE)
        
    def extract_institutions(self, paper: Dict) -> List[str]:
        """
        Extract institution names from a paper.
        
        Args:
            paper: Paper dictionary with Authors and Institutions field
            
        Returns:
            List of institution names (may include None)
        """
        institutions = []
        
        authors_institutions = paper.get('Authors and Institutions', {})
        
        # Handle empty or None case
        if not authors_institutions:
            return [None]
            
        # Extract institutions from each author
        for author in authors_institutions:
            author_institutions = author.get('Institutions', [])
            
            if not author_institutions:
                institutions.append(None)
                continue
                
            # Process each institution
            for inst in author_institutions:
                if isinstance(inst, dict):
                    inst_name = inst.get('Institution Name', None)
                    if inst_name:
                        institutions.append(inst_name.lower().strip())
                elif isinstance(inst, str):
                    institutions.append(inst.lower().strip())
                else:
                    institutions.append(None)
                    
        return institutions
        
    def classify_paper(self, institutions: List[str]) -> str:
        """
        Classify paper based on institution affiliations.
        
        Args:
            institutions: List of institution names
            
        Returns:
            Classification: 'has_big_company', 'no_big_company', or 'all_none'
        """
        if not institutions:
            return 'all_none'
            
        all_are_none = True
        contains_big_company = False
        
        for inst in institutions:
            if inst is None:
                continue
                
            all_are_none = False
            
            # Check if institution matches any big tech company
            if self.company_pattern.search(inst):
                contains_big_company = True
                break
                
        if all_are_none:
            return 'all_none'
            
        return 'has_big_company' if contains_big_company else 'no_big_company'
        
    def analyze_conference(self, conference: str, 
                          papers_by_year: Dict[str, List[Dict]]) -> Dict[str, BigTechStats]:
        """
        Analyze big tech presence for a conference across all years.
        
        Args:
            conference: Conference name
            papers_by_year: Dictionary mapping year to list of papers
            
        Returns:
            Dictionary mapping year to statistics
        """
        stats_by_year = {}
        
        for year, papers in papers_by_year.items():
            stats = self._analyze_year(papers)
            stats_by_year[year] = stats
            
        return stats_by_year
        
    def _analyze_year(self, papers: List[Dict]) -> BigTechStats:
        """
        Analyze big tech presence for papers in a single year.
        
        Args:
            papers: List of paper dictionaries
            
        Returns:
            Statistics for the year
        """
        stats = BigTechStats(total_papers=len(papers))
        
        classifications = []
        
        for paper in papers:
            institutions = self.extract_institutions(paper)
            classification = self.classify_paper(institutions)
            classifications.append(classification)
            
        # Count classifications
        stats.has_big_tech = classifications.count('has_big_company')
        stats.no_big_tech = classifications.count('no_big_company')
        stats.all_none = classifications.count('all_none')
        
        # Calculate percentages
        if stats.total_papers > 0:
            stats.pct_has_big = (stats.has_big_tech / stats.total_papers) * 100
            stats.pct_no_big = (stats.no_big_tech / stats.total_papers) * 100
            stats.pct_all_none = (stats.all_none / stats.total_papers) * 100
            
        return stats
        
    def analyze_all_conferences(self) -> List[Dict]:
        """
        Analyze big tech presence across all conferences.
        
        Returns:
            List of result dictionaries suitable for CSV export
        """
        processed_dir = self.project_root / DATA_DIRS["processed"]
        
        if not processed_dir.exists():
            raise FileNotFoundError(f"ProcessedData directory not found: {processed_dir}")
            
        results = []
        
        # Find all conference data files
        conferences = self.file_manager.get_conferences_from_directory(
            processed_dir, "_data.json"
        )
        
        logger.info(f"Analyzing {len(conferences)} conferences for big tech presence...")
        
        for conference in conferences:
            # Skip SoCC duplicate (use cloud as canonical)
            if conference.lower() == "socc":
                continue
                
            data_file = processed_dir / f"{conference}_data.json"
            
            try:
                papers_by_year = self.file_manager.load_json(data_file)
                stats_by_year = self.analyze_conference(conference, papers_by_year)
                
                # Convert to CSV format
                for year, stats in stats_by_year.items():
                    results.append({
                        'Conference': conference,
                        'Year': year,
                        'pct_has_big': round(stats.pct_has_big, 2),
                        'pct_no_big': round(stats.pct_no_big, 2),
                        'pct_all_none': round(stats.pct_all_none, 2)
                    })
                    
                logger.info(f"  Analyzed: {conference} ({len(stats_by_year)} years)")
                
            except Exception as e:
                logger.error(f"  Failed to analyze {conference}: {e}")
                continue
                
        return results
        
    def generate_csv(self, output_path: Path = None) -> Path:
        """
        Generate CSV file with big tech analysis results.
        
        Args:
            output_path: Output CSV path (default: outputs/csv/big_tech_analysis.csv)
            
        Returns:
            Path to generated CSV file
        """
        if output_path is None:
            output_path = self.project_root / "outputs" / "csv" / "big_tech_analysis.csv"
            
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Analyze all conferences
        results = self.analyze_all_conferences()
        
        # Save to CSV
        self.file_manager.save_csv(
            output_path,
            results,
            fieldnames=['Conference', 'Year', 'pct_has_big', 'pct_no_big', 'pct_all_none']
        )
        
        logger.info(f"Generated big tech analysis CSV: {output_path}")
        logger.info(f"  Total records: {len(results)}")
        
        return output_path
    
    def analyze_by_continent(self, conference: str,
                            papers_by_year: Dict[str, List[Dict]]) -> List[Dict]:
        """
        Analyze big tech presence by continent for a conference.
        
        Args:
            conference: Conference name
            papers_by_year: Dictionary mapping year to list of papers
            
        Returns:
            List of results by continent
        """
        results = []
        
        for year, papers in papers_by_year.items():
            continent_stats = {
                'NA': {'has_big': 0, 'no_big': 0, 'total': 0},
                'EU': {'has_big': 0, 'no_big': 0, 'total': 0},
                'AS': {'has_big': 0, 'no_big': 0, 'total': 0},
                'Other': {'has_big': 0, 'no_big': 0, 'total': 0}
            }
            
            for paper in papers:
                # Get predominant continent
                continent = paper.get('Predominant Continent', 'Unknown')
                if continent == 'Unknown' or not continent:
                    continue
                
                # Handle if continent is a list (shouldn't be, but just in case)
                if isinstance(continent, list):
                    continent = continent[0] if continent else 'Unknown'
                
                if not isinstance(continent, str) or continent == 'Unknown':
                    continue
                    
                continent = continent.upper()
                if continent not in continent_stats:
                    continent = 'Other'
                
                # Classify paper
                institutions = self.extract_institutions(paper)
                classification = self.classify_paper(institutions)
                
                if classification == 'has_big_company':
                    continent_stats[continent]['has_big'] += 1
                elif classification == 'no_big_company':
                    continent_stats[continent]['no_big'] += 1
                    
                continent_stats[continent]['total'] += 1
            
            # Calculate percentages for each continent
            total_papers = sum(stats['total'] for stats in continent_stats.values())
            
            if total_papers > 0:
                for continent, stats in continent_stats.items():
                    if stats['total'] > 0:
                        pct_big = (stats['has_big'] / total_papers) * 100
                        pct_no_big = (stats['no_big'] / total_papers) * 100
                        
                        results.append({
                            'Conference': conference,
                            'Year': year,
                            'level_2': f'pct_big_{continent.lower()}',
                            'X0': round(pct_big, 2)
                        })
        
        return results
    
    def generate_continent_csv(self, output_path: Path = None) -> Path:
        """
        Generate CSV file with big tech analysis by continent.
        
        Args:
            output_path: Output CSV path
            
        Returns:
            Path to generated CSV file
        """
        if output_path is None:
            output_path = self.project_root / "outputs" / "csv" / "big_companies_by_continent_analysis.csv"
            
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        processed_dir = self.project_root / DATA_DIRS["processed"]
        
        if not processed_dir.exists():
            raise FileNotFoundError(f"ProcessedData directory not found: {processed_dir}")
        
        results = []
        
        conferences = self.file_manager.get_conferences_from_directory(
            processed_dir, "_data.json"
        )
        
        logger.info(f"Analyzing {len(conferences)} conferences by continent...")
        
        for conference in conferences:
            if conference.lower() == "socc":
                continue
                
            data_file = processed_dir / f"{conference}_data.json"
            
            try:
                papers_by_year = self.file_manager.load_json(data_file)
                continent_results = self.analyze_by_continent(conference, papers_by_year)
                results.extend(continent_results)
                
                logger.info(f"  Analyzed: {conference}")
                
            except Exception as e:
                logger.error(f"  Failed to analyze {conference}: {e}")
                continue
        
        # Save to CSV
        self.file_manager.save_csv(
            output_path,
            results,
            fieldnames=['Conference', 'Year', 'level_2', 'X0']
        )
        
        logger.info(f"Generated continent analysis CSV: {output_path}")
        logger.info(f"  Total records: {len(results)}")
        
        return output_path
        
    def generate_summary_report(self, results: List[Dict]) -> str:
        """
        Generate summary report of big tech analysis.
        
        Args:
            results: List of analysis results
            
        Returns:
            Formatted report string
        """
        lines = [
            "=" * 70,
            "BIG TECH COMPANY ANALYSIS SUMMARY",
            "=" * 70,
            ""
        ]
        
        # Group by conference
        by_conference = {}
        for result in results:
            conf = result['Conference']
            if conf not in by_conference:
                by_conference[conf] = []
            by_conference[conf].append(result)
            
        # Calculate averages per conference
        for conf in sorted(by_conference.keys()):
            conf_results = by_conference[conf]
            
            avg_big_tech = sum(r['pct_has_big'] for r in conf_results) / len(conf_results)
            avg_academia = sum(r['pct_no_big'] for r in conf_results) / len(conf_results)
            
            lines.append(f"{conf:15s}: {avg_big_tech:5.1f}% Big Tech, "
                        f"{avg_academia:5.1f}% Academia")
                        
        lines.extend([
            "",
            "-" * 70,
            f"Total conferences analyzed: {len(by_conference)}",
            f"Total records: {len(results)}",
            "=" * 70
        ])
        
        return "\n".join(lines)


def main():
    """Main entry point for big tech analyzer."""
    import sys
    
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    # Get project root
    project_root = Path(__file__).parent.parent.parent
    
    # Analyze big tech presence
    analyzer = BigTechAnalyzer(project_root)
    
    try:
        logger.info("Starting big tech company analysis...")
        
        # Generate CSV
        output_path = analyzer.generate_csv()
        
        # Load results and print summary
        results = analyzer.file_manager.load_csv(output_path)
        summary = analyzer.generate_summary_report(results)
        print("\n" + summary)
        
        logger.info("Big tech analysis completed successfully!")
        return 0
        
    except Exception as e:
        logger.error(f"Big tech analysis failed: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())

