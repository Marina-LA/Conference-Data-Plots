"""
CSV Generator for Conference Data Analysis project.
Generates unified CSV files from processed data.
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
class CSVGenerationResult:
    """Result from CSV generation."""
    output_path: Path
    row_count: int
    success: bool
    error: Optional[str] = None


class CSVGenerator:
    """Generates unified CSV files from JSON data sources."""
    
    def __init__(self, project_root: Path):
        """
        Initialize CSVGenerator.
        
        Args:
            project_root: Root directory of project
        """
        self.project_root = Path(project_root)
        self.file_manager = FileManager(project_root)
        self.continent_mapper = ContinentMapper()
        
    def generate_papers_csv(self, output_path: Optional[Path] = None) -> CSVGenerationResult:
        """
        Generate unified papers CSV from ProcessedData JSON files.
        
        Args:
            output_path: Output CSV path (default: ProcessedData/unifiedPaperData.csv)
            
        Returns:
            CSVGenerationResult with generation details
        """
        if output_path is None:
            output_path = self.project_root / DATA_DIRS["processed"] / "unifiedPaperData.csv"
            
        try:
            processed_dir = self.project_root / DATA_DIRS["processed"]
            
            if not processed_dir.exists():
                return CSVGenerationResult(
                    output_path=output_path,
                    row_count=0,
                    success=False,
                    error="ProcessedData directory not found"
                )
                
            # Collect all papers
            all_rows = []
            
            for json_file in processed_dir.glob("*_data.json"):
                # Skip SoCC duplicates (use cloud_data.json as canonical)
                if json_file.stem.startswith("socc_"):
                    continue
                    
                conference = json_file.stem.replace("_data", "")
                data = self.file_manager.load_json(json_file)
                
                # Process each year
                for year, papers in data.items():
                    for paper in papers:
                        continents = paper.get("Predominant Continent", [])
                        continent = continents[0] if continents else None
                        
                        all_rows.append({
                            "Conference": conference,
                            "Year": year,
                            "Title": paper.get("Title", ""),
                            "Predominant Continent": continent
                        })
                        
            # Save CSV
            self.file_manager.save_csv(
                output_path,
                all_rows,
                fieldnames=["Conference", "Year", "Title", "Predominant Continent"]
            )
            
            logger.info(f"Generated papers CSV: {output_path} ({len(all_rows)} rows)")
            
            return CSVGenerationResult(
                output_path=output_path,
                row_count=len(all_rows),
                success=True
            )
            
        except Exception as e:
            logger.error(f"Failed to generate papers CSV: {e}")
            return CSVGenerationResult(
                output_path=output_path,
                row_count=0,
                success=False,
                error=str(e)
            )
            
    def generate_committee_csv(self, output_path: Optional[Path] = None) -> CSVGenerationResult:
        """
        Generate unified committee CSV from CommitteeData JSON files.
        
        Args:
            output_path: Output CSV path (default: ProcessedData/unifiedCommitteeData.csv)
            
        Returns:
            CSVGenerationResult with generation details
        """
        if output_path is None:
            output_path = self.project_root / DATA_DIRS["processed"] / "unifiedCommitteeData.csv"
            
        try:
            committee_dir = self.project_root / DATA_DIRS["committee"]
            
            if not committee_dir.exists():
                return CSVGenerationResult(
                    output_path=output_path,
                    row_count=0,
                    success=False,
                    error="CommitteeData directory not found"
                )
                
            # Collect all committee members
            all_rows = []
            
            for json_file in committee_dir.glob("*_committee.json"):
                conference = json_file.stem.replace("_committee", "")
                data = self.file_manager.load_json(json_file)
                
                # Process each year
                for year, members in data.items():
                    for member_name, institutions in members.items():
                        institution_list = []
                        countries = set()
                        
                        # Handle different data formats
                        if isinstance(institutions, dict):
                            # Normal: {institution: country}
                            for inst, country in institutions.items():
                                institution_list.append(inst)
                                if country:
                                    countries.add(country)
                        elif isinstance(institutions, str):
                            # Direct country value
                            countries.add(institutions)
                        
                        # Format institutions
                        institutions_str = ";".join([i for i in institution_list if i]) or None
                        
                        # Convert countries to continents
                        continents = set()
                        for country in countries:
                            continent = self.continent_mapper.country_to_continent(country)
                            if continent:
                                continents.add(continent)
                                
                        continent_str = ";".join(sorted(continents)) if continents else None
                        
                        all_rows.append({
                            "Conference": conference,
                            "Year": year,
                            "Name": member_name,
                            "Institution": institutions_str,
                            "Continent": continent_str
                        })
                        
            # Save CSV
            self.file_manager.save_csv(
                output_path,
                all_rows,
                fieldnames=["Conference", "Year", "Name", "Institution", "Continent"]
            )
            
            logger.info(f"Generated committee CSV: {output_path} ({len(all_rows)} rows)")
            
            return CSVGenerationResult(
                output_path=output_path,
                row_count=len(all_rows),
                success=True
            )
            
        except Exception as e:
            logger.error(f"Failed to generate committee CSV: {e}")
            return CSVGenerationResult(
                output_path=output_path,
                row_count=0,
                success=False,
                error=str(e)
            )
            
    def generate_citations_csv(self, output_path: Optional[Path] = None) -> CSVGenerationResult:
        """
        Generate unified citations CSV from CitationsCrawlerData.
        
        Args:
            output_path: Output CSV path (default: ProcessedData/unifiedCitationsData.csv)
            
        Returns:
            CSVGenerationResult with generation details
        """
        if output_path is None:
            output_path = self.project_root / DATA_DIRS["processed"] / "unifiedCitationsData.csv"
            
        try:
            citations_dir = self.project_root / DATA_DIRS["crawler_citations"]
            
            if not citations_dir.exists():
                return CSVGenerationResult(
                    output_path=output_path,
                    row_count=0,
                    success=False,
                    error="CitationsCrawlerData directory not found"
                )
                
            # Find all conferences with citation data
            conferences = set()
            
            # Check main directory
            for file in citations_dir.glob("*_citations_data.json"):
                conferences.add(file.stem.replace("_citations_data", ""))
                
            # Check intermediate directory
            intermediate_dir = citations_dir / "IntermediateCitations"
            if intermediate_dir.exists():
                for file in intermediate_dir.glob("*_citations_s2.json"):
                    conferences.add(file.stem.replace("_citations_s2", ""))
                    
            # Process each conference
            all_rows = []
            
            for conference in sorted(conferences):
                # Try primary file first, then fallback
                primary = citations_dir / f"{conference}_citations_data.json"
                fallback = intermediate_dir / f"{conference}_citations_s2.json"
                
                citation_file = primary if primary.exists() else fallback
                
                if not citation_file.exists():
                    continue
                    
                # Load JSON with tolerant encoding; skip invalid/empty files
                try:
                    data = self.file_manager.load_json(citation_file)
                except Exception as e:
                    logger.warning(f"Skipping citation file due to read/parse error: {citation_file} ({e})")
                    continue
                if not data:
                    logger.warning(f"Skipping empty citation file: {citation_file}")
                    continue
                
                # Count papers by continent
                continent_counts: Dict[str, int] = {}
                
                # Process citations
                if isinstance(data, dict):
                    for _, citing_list in data.items():
                        if not isinstance(citing_list, list):
                            continue
                            
                        for citation in citing_list:
                            if not isinstance(citation, dict):
                                continue
                                
                            # Extract continents from authors
                            continents = self._extract_continents_from_citation(citation)
                            
                            for continent in continents:
                                continent_counts[continent] = continent_counts.get(continent, 0) + 1
                                
                # Add to rows
                for continent, count in continent_counts.items():
                    all_rows.append({
                        "Conference": conference,
                        "Continent": continent,
                        "Num_Papers": count
                    })
                    
            # Save CSV
            self.file_manager.save_csv(
                output_path,
                all_rows,
                fieldnames=["Conference", "Continent", "Num_Papers"]
            )
            
            logger.info(f"Generated citations CSV: {output_path} ({len(all_rows)} rows)")
            
            return CSVGenerationResult(
                output_path=output_path,
                row_count=len(all_rows),
                success=True
            )
            
        except Exception as e:
            logger.error(f"Failed to generate citations CSV: {e}")
            return CSVGenerationResult(
                output_path=output_path,
                row_count=0,
                success=False,
                error=str(e)
            )
            
    def _extract_continents_from_citation(self, citation: Dict) -> set:
        """Extract unique continents from citation authors."""
        continents = set()
        
        authors = citation.get("Authors", [])
        if not isinstance(authors, list):
            return continents
            
        for author in authors:
            if not isinstance(author, dict):
                continue
                
            # Try different field names for institutions
            insts = (author.get("Institutions") or 
                    author.get("Affiliations") or [])
                    
            if not isinstance(insts, list):
                continue
                
            for inst in insts:
                if not isinstance(inst, dict):
                    continue
                    
                # Try different field names for country
                country = (inst.get("Country") or 
                          inst.get("country") or 
                          inst.get("CountryCode"))
                          
                continent = self.continent_mapper.country_to_continent(country)
                if continent:
                    continents.add(continent)
                    
        return continents
        
    def generate_all_csvs(self) -> Dict[str, CSVGenerationResult]:
        """
        Generate all unified CSV files.
        
        Returns:
            Dictionary mapping CSV type to generation result
        """
        logger.info("Generating all unified CSV files...")
        
        results = {
            "papers": self.generate_papers_csv(),
            "committee": self.generate_committee_csv(),
            "citations": self.generate_citations_csv()
        }
        
        # Summary
        success_count = sum(1 for r in results.values() if r.success)
        logger.info(f"CSV generation complete: {success_count}/{len(results)} successful")
        
        return results


def main():
    """Main entry point for CSV generator."""
    import sys
    
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    # Get project root
    project_root = Path(__file__).parent.parent.parent
    
    # Generate CSVs
    generator = CSVGenerator(project_root)
    
    try:
        results = generator.generate_all_csvs()
        
        # Check for failures
        failures = [name for name, result in results.items() if not result.success]
        
        if failures:
            logger.error(f"Failed to generate: {', '.join(failures)}")
            return 1
            
        logger.info("All CSV files generated successfully!")
        return 0
        
    except Exception as e:
        logger.error(f"CSV generation failed: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())

