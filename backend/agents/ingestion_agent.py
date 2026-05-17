"""
SENTINEL Ingestion Agent (Module 2)
Converts heterogeneous source files into unified Source objects.
Canon: idea.md Module 2, planning.md Hour 6 T4
"""

import json
import os
from datetime import datetime, timezone
from uuid import uuid4

from models.source import Source
from tools import pdf_parser, csv_parser, json_parser, web_fetcher
from utils.logger import logger


def _extract_metadata(content: str, source_type: str, file_path: str) -> dict:
    """Extract metadata from source content."""
    metadata = {
        "file_path": file_path,
        "source_type": source_type,
        "content_length": len(content),
    }

    # Try to extract dates from JSON content
    if source_type == "json":
        try:
            data = json.loads(content)
            if "report_date" in data:
                metadata["report_date"] = data["report_date"]
            if "captured_at" in data:
                metadata["captured_at"] = data["captured_at"]
            if "feed_timestamp" in data:
                metadata["feed_timestamp"] = data["feed_timestamp"]
        except (json.JSONDecodeError, TypeError):
            pass

    return metadata


def _extract_timestamp(content: str, source_type: str) -> datetime:
    """Extract the most relevant timestamp from the source content."""
    now = datetime.now(timezone.utc)

    if source_type == "json":
        try:
            data = json.loads(content)
            for key in ["report_date", "captured_at", "feed_timestamp"]:
                if key in data:
                    val = data[key]
                    try:
                        return datetime.fromisoformat(str(val).replace("Z", "+00:00"))
                    except (ValueError, TypeError):
                        try:
                            return datetime.strptime(str(val), "%Y-%m-%d").replace(tzinfo=timezone.utc)
                        except ValueError:
                            pass
        except (json.JSONDecodeError, TypeError):
            pass

    if source_type == "csv":
        # For CSV, extract last recorded_at from content
        try:
            lines = content.strip().split("\n")
            if len(lines) > 1:
                last_line = lines[-1]
                parts = last_line.split(",")
                for part in reversed(parts):
                    try:
                        return datetime.fromisoformat(part.strip()).replace(tzinfo=timezone.utc)
                    except ValueError:
                        continue
        except Exception:
            pass

    return now


async def run_ingestion(source_paths: list[dict], run_id: str = "") -> list[Source]:
    """
    Parse all source files into unified Source objects.

    Args:
        source_paths: List of dicts with 'type' and 'path' keys
        run_id: Current run ID for logging

    Returns:
        List of Source objects
    """
    logger.info(f"[{run_id}] Ingestion Agent starting with {len(source_paths)} sources")
    sources = []

    for src in source_paths:
        src_type = src["type"]
        src_path = src["path"]
        raw_content = src.get("raw_content")

        try:
            if raw_content is not None:
                content = raw_content
            else:
                # Resolve path relative to project root
                if not os.path.isabs(src_path):
                    # Try from backend dir first, then from project root
                    backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
                    abs_path = os.path.join(backend_dir, src_path)
                    if not os.path.exists(abs_path):
                        abs_path = os.path.join(os.path.dirname(backend_dir), src_path)
                else:
                    abs_path = src_path

                if src_type == "pdf":
                    content = pdf_parser.parse(abs_path)
                elif src_type == "csv":
                    content = csv_parser.parse(abs_path)
                elif src_type == "json":
                    content = json_parser.parse(abs_path)
                elif src_type in ("web", "realtime_feed"):
                    content = web_fetcher.parse(abs_path)
                else:
                    logger.warning(f"[{run_id}] Unknown source type: {src_type}")
                    content = f"[Unsupported source type: {src_type}]"

            metadata = _extract_metadata(content, src_type, src_path)
            recorded_at = _extract_timestamp(content, src_type)

            source = Source(
                source_id=f"src_{uuid4().hex[:8]}",
                source_type=src_type,
                content=content,
                metadata=metadata,
                recorded_at=recorded_at,
                ingested_at=datetime.now(timezone.utc),
            )
            sources.append(source)
            logger.info(f"[{run_id}] Ingested {src_type} source: {src_path}")

        except Exception as e:
            logger.error(f"[{run_id}] Failed to ingest {src_path}: {e}")
            # Create error source rather than failing the whole pipeline
            sources.append(Source(
                source_id=f"src_{uuid4().hex[:8]}",
                source_type=src_type,
                content=f"[Error: {str(e)}]",
                metadata={"file_path": src_path, "error": str(e)},
                recorded_at=datetime.now(timezone.utc),
                ingested_at=datetime.now(timezone.utc),
            ))

    logger.info(f"[{run_id}] Ingestion complete: {len(sources)} sources processed")
    return sources
