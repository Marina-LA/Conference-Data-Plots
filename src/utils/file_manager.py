"""
File management utilities for Conference Data Analysis project.
Handles all file I/O operations including JSON and CSV files.
"""

import json
import os
import csv
from pathlib import Path
from typing import Any, Dict, List, Optional
import logging

logger = logging.getLogger(__name__)


class FileManager:
    """Centralized file management for JSON and CSV operations."""
    
    def __init__(self, project_root: Optional[Path] = None):
        """
        Initialize FileManager.
        
        Args:
            project_root: Root directory of the project. If None, uses current working directory.
        """
        self.project_root = project_root or Path.cwd()
        
    def load_json(self, path: Path | str, encoding: str = 'utf-8') -> Dict | List:
        """
        Load JSON file.
        
        Args:
            path: Path to JSON file
            encoding: File encoding (default: utf-8)
            
        Returns:
            Parsed JSON data
            
        Raises:
            FileNotFoundError: If file doesn't exist
            json.JSONDecodeError: If file is not valid JSON
        """
        path = Path(path)
        
        if not path.exists():
            raise FileNotFoundError(f"JSON file not found: {path}")
            
        # Try multiple decoders to handle mixed encodings in crawled data
        encodings_to_try = [encoding, 'utf-8-sig', 'latin-1']
        last_error: Exception | None = None
        for enc in encodings_to_try:
            try:
                with open(path, 'r', encoding=enc) as f:
                    data = json.load(f)
                    logger.debug(f"Loaded JSON from {path} with encoding {enc}")
                    return data
            except UnicodeDecodeError as e:
                last_error = e
                continue
            except json.JSONDecodeError as e:
                # If bytes read fine but JSON is invalid, fail fast
                logger.error(f"Invalid JSON in {path}: {e}")
                raise
        # If we exhausted decoders due to Unicode errors, raise the last one
        if last_error:
            raise last_error
            
    def save_json(self, path: Path | str, data: Dict | List, 
                  encoding: str = 'utf-8', indent: int = 4) -> None:
        """
        Save data to JSON file.
        
        Args:
            path: Output file path
            data: Data to save
            encoding: File encoding (default: utf-8)
            indent: JSON indentation (default: 4)
        """
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(path, 'w', encoding=encoding) as f:
            json.dump(data, f, ensure_ascii=False, indent=indent)
            logger.debug(f"Saved JSON to {path}")
            
    def load_csv(self, path: Path | str, encoding: str = 'utf-8') -> List[Dict]:
        """
        Load CSV file as list of dictionaries.
        
        Args:
            path: Path to CSV file
            encoding: File encoding (default: utf-8)
            
        Returns:
            List of dictionaries (one per row)
        """
        path = Path(path)
        
        if not path.exists():
            raise FileNotFoundError(f"CSV file not found: {path}")
            
        with open(path, 'r', encoding=encoding, newline='') as f:
            reader = csv.DictReader(f)
            data = list(reader)
            logger.debug(f"Loaded {len(data)} rows from {path}")
            return data
            
    def save_csv(self, path: Path | str, data: List[Dict], 
                 fieldnames: Optional[List[str]] = None,
                 encoding: str = 'utf-8') -> None:
        """
        Save data to CSV file.
        
        Args:
            path: Output file path
            data: List of dictionaries to save
            fieldnames: Column names (if None, uses keys from first row)
            encoding: File encoding (default: utf-8)
        """
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        if not data:
            logger.warning(f"No data to save to {path}")
            return
            
        if fieldnames is None:
            fieldnames = list(data[0].keys())
            
        with open(path, 'w', encoding=encoding, newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(data)
            logger.debug(f"Saved {len(data)} rows to {path}")
            
    def exists(self, path: Path | str) -> bool:
        """Check if file or directory exists."""
        return Path(path).exists()
        
    def create_dir(self, path: Path | str) -> None:
        """Create directory if it doesn't exist."""
        Path(path).mkdir(parents=True, exist_ok=True)
        
    def list_files(self, directory: Path | str, pattern: str = "*") -> List[Path]:
        """
        List files in directory matching pattern.
        
        Args:
            directory: Directory to search
            pattern: Glob pattern (default: "*")
            
        Returns:
            List of matching file paths
        """
        directory = Path(directory)
        
        if not directory.is_dir():
            return []
            
        return list(directory.glob(pattern))
        
    def get_conferences_from_directory(self, directory: Path | str, 
                                      suffix: str = "_data.json") -> List[str]:
        """
        Extract conference names from files in directory.
        
        Args:
            directory: Directory to search
            suffix: File suffix to match (default: "_data.json")
            
        Returns:
            List of conference names
        """
        directory = Path(directory)
        conferences = []
        
        if not directory.is_dir():
            return conferences
            
        for file_path in directory.glob(f"*{suffix}"):
            conf_name = file_path.stem.replace(suffix.replace('.json', ''), '')
            # Handle both "conf_data.json" and "conf_extended_data.json" patterns
            conf_name = conf_name.replace('_extended', '').replace('_base', '').replace('_citations', '')
            if conf_name and conf_name not in conferences:
                conferences.append(conf_name)
                
        return sorted(conferences)
        
    def merge_json(self, path: Path | str, new_data: Dict) -> None:
        """
        Merge new data into existing JSON file.
        
        Args:
            path: Path to JSON file
            new_data: Data to merge
        """
        path = Path(path)
        
        if not path.exists():
            self.save_json(path, new_data)
            return
            
        existing_data = self.load_json(path)
        
        if isinstance(existing_data, dict) and isinstance(new_data, dict):
            existing_data.update(new_data)
            self.save_json(path, existing_data)
        else:
            logger.warning(f"Cannot merge non-dict data in {path}")


def setup_project_directories(project_root: Path) -> None:
    """
    Create standard project directory structure.
    
    Args:
        project_root: Root directory of project
    """
    directories = [
        "outputs/plots",
        "outputs/csv",
        "outputs/reports",
        "outputs/temp",
    ]
    
    for directory in directories:
        (project_root / directory).mkdir(parents=True, exist_ok=True)
        
    logger.info(f"Project directories created at {project_root}")


