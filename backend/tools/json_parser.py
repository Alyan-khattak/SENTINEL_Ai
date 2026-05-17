"""
SENTINEL JSON Parser Tool
Canon: planning.md Hour 6 T2
"""

import json
import os
from utils.logger import logger


def parse(file_path: str) -> str:
    """
    Parse a JSON file and return its content as formatted text.
    """
    abs_path = os.path.abspath(file_path)
    try:
        with open(abs_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return json.dumps(data, indent=2, default=str)
    except Exception as e:
        logger.error(f"Cannot parse JSON {file_path}: {e}")
        return f"[Error parsing JSON {file_path}]"
