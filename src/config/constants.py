"""
Centralized configuration and constants for the Conference Data Analysis project.
This module contains all shared constants used across data processing scripts.
"""

from typing import Dict, List

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

PROJECT_NAME = "Conference Data Analysis"
VERSION = "2.0.0"

# ============================================================================
# DIRECTORY PATHS
# ============================================================================

# Relative paths from project root
DATA_DIRS = {
    "crawler_base": "CrawlerData/BaseCrawlerData",
    "crawler_extended": "CrawlerData/ExtendedCrawlerData",
    "crawler_citations": "CrawlerData/CitationsCrawlerData",
    "committee": "CommitteeData",
    "processed": "ProcessedData",
    "databases_relational": "Databases/RelationalDB",
    "databases_graph": "Databases/GraphDB",
}

OUTPUT_DIRS = {
    "plots": "outputs/plots",
    "csv": "outputs/csv",
    "reports": "outputs/reports",
}

# ============================================================================
# CONFERENCE CONFIGURATION
# ============================================================================

# Conference name mappings (lowercase -> display name)
CONFERENCE_MAPPING: Dict[str, str] = {
    "nsdi": "NSDI",
    "sigcomm": "SIGCOMM",
    "cloud": "SoCC",
    "socc": "SoCC",
    "eurosys": "EuroSys",
    "ic2e": "IC2E",
    "icdcs": "ICDCS",
    "middleware": "Middleware",
    "ieeecloud": "IEEE Cloud",
    "IEEEcloud": "IEEE Cloud",
    "ccgrid": "CCGRID",
    "europar": "Euro-Par",
    "asplos": "ASPLOS",
    "atc": "ATC",
    "osdi": "OSDI",
}

# Default conference order for plots
CONFERENCE_ORDER: List[str] = [
    "NSDI", "ASPLOS", "SIGCOMM", "SoCC", "OSDI", "EuroSys",
    "ATC", "IC2E", "ICDCS", "Middleware", "IEEE Cloud",
    "CCGRID", "Euro-Par"
]

# ============================================================================
# CONTINENT CONFIGURATION
# ============================================================================

# Continent code mappings
CONTINENT_MAPPING: Dict[str, str] = {
    "NA": "North America",
    "EU": "Europe",
    "AS": "Asia",
    "SA": "South America",
    "OC": "Oceania",
    "AF": "Africa",
    "Others": "Others",
    "Unknown": "Unknown",
}

# Continent groupings for analysis (combines small continents into "Others")
CONTINENT_GROUPS: Dict[str, str] = {
    "NA": "NA",
    "EU": "EU",
    "AS": "AS",
    "SA": "Others",
    "OC": "Others",
    "AF": "Others",
}

# Continent display order (for stacked plots)
CONTINENT_ORDER: List[str] = ["Unknown", "Others", "Asia", "Europe", "North America"]
CONTINENT_ORDER_CODES: List[str] = ["Unknown", "Others", "AS", "EU", "NA"]

# ============================================================================
# COLOR SCHEMES
# ============================================================================

# Primary color scheme for continents (used in all plots)
CONTINENT_COLORS: Dict[str, str] = {
    "North America": "#1f3b6f",  # Dark blue
    "Europe": "#1681c5",          # Medium blue
    "Asia": "#7d7d7d",            # Gray
    "Others": "#c5c5c5",          # Light gray
    "Unknown": "#FFFFFF",         # White
}

# Continent colors by code (for easier R integration)
CONTINENT_COLORS_BY_CODE: Dict[str, str] = {
    "NA": "#1f3b6f",
    "EU": "#1681c5",
    "AS": "#7d7d7d",
    "Others": "#c5c5c5",
    "Unknown": "#FFFFFF",
}

# Special colors for specific analyses
SPECIAL_COLORS: Dict[str, str] = {
    "asia_trend": "#4A90E2",      # Used in Asian trend plot
    "big_tech": "#e74c3c",        # Red for big tech companies
    "academia": "#3498db",        # Blue for academia
}

# ============================================================================
# BIG TECH COMPANIES
# ============================================================================

BIG_TECH_COMPANIES = {
    # North America
    'ibm', 'ibm research', 'ibm linux technology center',
    'microsoft', 'microsoft azure', 'azure', 'microsoft research',
    'google', 'google cloud', 'alphabet',
    'amazon', 'amazon web services', 'aws',
    'facebook', 'meta', 'meta platforms',
    'apple', 'intel', 'oracle', 'oracle labs',
    'cisco', 'cisco systems', 'hp', 'hewlett packard', 'hp labs',
    'hpe', 'hewlett packard enterprise', 'nvidia', 'vmware', 'netflix',
    'uber', 'twitter', 'yahoo', 'snap', 'salesforce',
    'amd', 'advanced micro devices', 'qualcomm', 'broadcom',
    
    # Asia
    'huawei', 'alibaba', 'alibaba cloud', 'bytedance', 'tencent',
    'baidu', 'samsung', 'xiaomi', 'tiktok',
    
    # Europe
    'arm', 'arm ltd', 'arm limited', 'arm holdings',
    'ericsson', 'nokia', 'siemens', 'orange', 'atos',
    'deutsche telekom', 'bosch', 'airbus', 'sap', 
    'telefonica', 'telefónica', 'vodafone', 'thales', 'philips'
}

# ============================================================================
# COUNTRY CODE FIXES
# ============================================================================

# Special cases for country code normalization
COUNTRY_CODE_FIXES: Dict[str, str] = {
    "UK": "GB",
    "U.K.": "GB",
    "U.S.": "US",
    "USA": "US",
    "UAE": "AE",
    "Korea": "KR",
    "South Korea": "KR",
    "North Korea": "KP",
    "Russia": "RU",
    "Viet Nam": "VN",
    "Vietnam": "VN",
}

# ============================================================================
# PLOT CONFIGURATION
# ============================================================================

# Default plot dimensions (width, height in inches)
PLOT_SIZES: Dict[str, tuple] = {
    "wide": (10.5, 4),
    "standard": (6.99, 4),
    "square": (6, 6),
    "tall": (6.99, 8),
}

# Plot theme defaults
PLOT_DEFAULTS = {
    "dpi": 300,
    "font_family": "serif",
    "base_font_size": 10,
}

# ============================================================================
# DATA VALIDATION
# ============================================================================

# Required fields for different data types
REQUIRED_FIELDS = {
    "paper": ["Title", "Year", "Authors and Institutions"],
    "committee": ["Name", "Year", "Institution"],
    "citation": ["Title", "Authors"],
}

# ============================================================================
# EXPORT FORMATS
# ============================================================================

CSV_ENCODING = "utf-8"
JSON_INDENT = 4
JSON_ENSURE_ASCII = False


