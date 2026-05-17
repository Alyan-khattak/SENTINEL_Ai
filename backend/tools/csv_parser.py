"""
SENTINEL CSV Parser Tool
Canon: planning.md Hour 6 T2
"""

import os
import pandas as pd
from utils.logger import logger


def parse(file_path: str) -> str:
    """
    Parse a CSV file and return its content as formatted text.
    """
    abs_path = os.path.abspath(file_path)
    try:
        df = pd.read_csv(abs_path)
        # Return a text representation with summary
        summary = f"CSV file with {len(df)} rows and {len(df.columns)} columns.\n"
        summary += f"Columns: {', '.join(df.columns.tolist())}\n\n"
        summary += df.to_string(index=False)
        return summary
    except Exception as e:
        logger.error(f"Cannot parse CSV {file_path}: {e}")
        return f"[Error parsing CSV {file_path}]"
