"""
SENTINEL Cache — In-memory dict keyed by prompt hash.
Per-run cache, cleared between runs.
Canon: planning.md Hour 3 T2
"""

import hashlib
from typing import Optional


class RunCache:
    """Simple in-memory cache for LLM responses within a single run."""

    def __init__(self):
        self._store: dict[str, str] = {}

    def _hash_key(self, prompt: str) -> str:
        """Generate a deterministic cache key from prompt content."""
        return hashlib.md5(prompt.encode()).hexdigest()

    def get(self, prompt: str) -> Optional[str]:
        """Retrieve cached response for a prompt, or None."""
        key = self._hash_key(prompt)
        return self._store.get(key)

    def set(self, prompt: str, response: str) -> None:
        """Cache a response for a prompt."""
        key = self._hash_key(prompt)
        self._store[key] = response

    def clear(self) -> None:
        """Clear all cached entries (between runs)."""
        self._store.clear()

    @property
    def size(self) -> int:
        return len(self._store)
