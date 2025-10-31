"""
Continent mapping utilities for Conference Data Analysis project.
Handles country to continent conversion with special case handling.
"""

import logging
from typing import Optional, List, Set, Dict
import pycountry_convert as pc

from src.config.constants import COUNTRY_CODE_FIXES, CONTINENT_GROUPS

logger = logging.getLogger(__name__)


class ContinentMapper:
    """Handles country to continent code conversion with robust error handling."""
    
    def __init__(self):
        """Initialize ContinentMapper with country code fixes."""
        self.country_fixes = COUNTRY_CODE_FIXES
        
    def normalize_alpha2(self, code: Optional[str]) -> Optional[str]:
        """
        Normalize country code to standard ISO Alpha-2 format.
        
        Args:
            code: Country code or name
            
        Returns:
            Normalized 2-letter country code or None
        """
        if not isinstance(code, str):
            return None
            
        code = code.strip()
        
        # Check special fixes first
        if code in self.country_fixes:
            return self.country_fixes[code]
            
        # If already valid 2-letter code
        if len(code) == 2 and code.isalpha():
            return code.upper()
            
        return None
        
    def country_name_to_alpha2(self, name: Optional[str]) -> Optional[str]:
        """
        Convert country name to ISO Alpha-2 code.
        
        Args:
            name: Country name
            
        Returns:
            2-letter country code or None
        """
        if not isinstance(name, str):
            return None
            
        name = name.strip()
        
        # Try special fixes first
        if name in self.country_fixes:
            return self.country_fixes[name]
            
        # Try pycountry_convert
        try:
            return pc.country_name_to_country_alpha2(name)
        except Exception:
            # Try without punctuation
            name_cleaned = name.replace(".", "").replace(",", "")
            try:
                return pc.country_name_to_country_alpha2(name_cleaned)
            except Exception:
                logger.debug(f"Could not convert country name: {name}")
                return None
                
    def country_to_alpha2(self, value: Optional[str]) -> Optional[str]:
        """
        Convert country code or name to Alpha-2 format.
        Tries normalization first, then name conversion.
        
        Args:
            value: Country code or name
            
        Returns:
            2-letter country code or None
        """
        # Try as code first
        code = self.normalize_alpha2(value)
        if code:
            return code
            
        # Try as name
        return self.country_name_to_alpha2(value)
        
    def alpha2_to_continent(self, alpha2: Optional[str]) -> Optional[str]:
        """
        Convert ISO Alpha-2 country code to continent code.
        
        Args:
            alpha2: 2-letter country code
            
        Returns:
            Continent code (NA, EU, AS, SA, OC, AF) or None
        """
        if not alpha2 or not isinstance(alpha2, str):
            return None
            
        try:
            return pc.country_alpha2_to_continent_code(alpha2)
        except Exception:
            logger.debug(f"Could not convert country code to continent: {alpha2}")
            return None
            
    def country_to_continent(self, country: Optional[str]) -> Optional[str]:
        """
        Convert country (code or name) to continent code.
        
        Args:
            country: Country code or name
            
        Returns:
            Continent code or None
        """
        alpha2 = self.country_to_alpha2(country)
        return self.alpha2_to_continent(alpha2)
        
    def group_continent(self, continent_code: Optional[str]) -> str:
        """
        Group continent codes into major categories.
        NA, EU, AS stay as-is, others become "Others", None becomes "Unknown".
        
        Args:
            continent_code: Continent code (NA, EU, AS, SA, OC, AF)
            
        Returns:
            Grouped continent code (NA, EU, AS, Others, Unknown)
        """
        if not continent_code:
            return "Unknown"
            
        return CONTINENT_GROUPS.get(continent_code, "Others")
        
    def extract_continents_from_institutions(self, 
                                            institutions: List[Dict]) -> Set[str]:
        """
        Extract unique continent codes from list of institutions.
        
        Args:
            institutions: List of institution dictionaries with Country field
            
        Returns:
            Set of continent codes
        """
        continents = set()
        
        if not institutions:
            return continents
            
        for inst in institutions:
            if not isinstance(inst, dict):
                continue
                
            country = inst.get("Country") or inst.get("country") or inst.get("CountryCode")
            continent = self.country_to_continent(country)
            
            if continent:
                continents.add(continent)
                
        return continents
        
    def get_predominant_continent(self, 
                                  authors: List[Dict]) -> tuple[List[str], int, int]:
        """
        Determine predominant continent from list of authors.
        
        Args:
            authors: List of author dictionaries with Institutions field
            
        Returns:
            Tuple of (predominant_continents, no_inst_count, unknown_count)
        """
        if not authors:
            return ([], 0, 0)
            
        continent_count: Dict[str, int] = {}
        no_inst_data = 0
        unknown_country = 0
        
        for author in authors:
            if not isinstance(author, dict):
                continue
                
            institutions = author.get("Institutions") or []
            
            if not institutions:
                no_inst_data += 1
                continue
                
            # Get unique countries for this author
            unique_countries = set()
            for inst in institutions:
                if isinstance(inst, dict) and "Country" in inst:
                    unique_countries.add(inst["Country"])
                    
            # Convert to continents
            for country in unique_countries:
                if not country or not isinstance(country, str) or len(country.strip()) != 2:
                    unknown_country += 1
                    continent = "Unknown"
                else:
                    try:
                        continent = pc.country_alpha2_to_continent_code(country)
                    except Exception:
                        unknown_country += 1
                        continent = "Unknown"
                        
                continent_count[continent] = continent_count.get(continent, 0) + 1
                
        # Find max count
        if not continent_count:
            return ([], no_inst_data, unknown_country)
            
        max_count = max(continent_count.values())
        predominant = [cont for cont, count in continent_count.items() 
                      if count == max_count]
        
        return (predominant, no_inst_data, unknown_country)


