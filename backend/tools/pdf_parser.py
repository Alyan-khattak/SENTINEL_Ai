"""
SENTINEL PDF Parser Tool
Canon: planning.md Hour 6 T2
"""

import os
from utils.logger import logger


def parse(file_path: str) -> str:
    """
    Parse a PDF file and return its text content.
    Falls back to .txt reading if pdfplumber fails.
    """
    abs_path = os.path.abspath(file_path)

    # Try pdfplumber first
    if abs_path.endswith(".pdf"):
        try:
            import pdfplumber
            text_parts = []
            with pdfplumber.open(abs_path) as pdf:
                for page in pdf.pages:
                    page_text = page.extract_text()
                    if page_text:
                        text_parts.append(page_text)
            if text_parts:
                return "\n".join(text_parts)
        except Exception as e:
            logger.warning(f"pdfplumber failed for {file_path}: {e}")

    # Fallback: try reading as text (for .txt companion files)
    txt_path = abs_path.replace(".pdf", ".txt")
    if os.path.exists(txt_path):
        with open(txt_path, "r", encoding="utf-8") as f:
            return f.read()

    # Last resort: try reading the file directly
    try:
        with open(abs_path, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()
    except Exception as e:
        logger.error(f"Cannot parse {file_path}: {e}")
        return f"[Error parsing {file_path}]"
