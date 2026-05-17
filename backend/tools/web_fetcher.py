"""
SENTINEL Web Fetcher Tool
Canon: planning.md Hour 6 T3
Uses requests + BeautifulSoup to fetch and clean HTML pages.
For hackathon, mostly handles local files as mock web sources.
"""

import os
from utils.logger import logger


def parse(url_or_path: str) -> str:
    """
    Fetch and clean a web page or local HTML file.
    Returns cleaned text content.
    """
    # Local file
    if os.path.exists(url_or_path):
        try:
            with open(url_or_path, "r", encoding="utf-8") as f:
                html = f.read()
            return _clean_html(html)
        except Exception as e:
            logger.error(f"Cannot read local file {url_or_path}: {e}")
            return f"[Error reading {url_or_path}]"

    # Remote URL
    try:
        import requests
        from bs4 import BeautifulSoup

        response = requests.get(url_or_path, timeout=10)
        response.raise_for_status()
        return _clean_html(response.text)
    except Exception as e:
        logger.error(f"Cannot fetch URL {url_or_path}: {e}")
        return f"[Error fetching {url_or_path}]"


def _clean_html(html: str) -> str:
    """Strip HTML tags and return clean text."""
    try:
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(html, "html.parser")
        # Remove script and style tags
        for tag in soup(["script", "style"]):
            tag.decompose()
        return soup.get_text(separator="\n", strip=True)
    except ImportError:
        # Fallback if BS4 not available
        import re
        return re.sub(r"<[^>]+>", "", html)
