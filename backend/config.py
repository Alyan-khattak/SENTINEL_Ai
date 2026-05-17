"""
SENTINEL Backend Configuration
Loads environment variables from .env using python-dotenv.
Never prints secrets. Provides typed settings.
"""

import os
from dotenv import load_dotenv

# Load from backend/.env explicitly
base_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(base_dir, ".env")
load_dotenv(dotenv_path=env_path)


class Settings:
    """Central typed configuration for the SENTINEL backend."""

    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    ENV: str = os.getenv("ENV", "dev")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./db/app.db")
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    BUDGET_LIMIT_PKR: int = int(os.getenv("BUDGET_LIMIT_PKR", "500000"))
    NOTIFICATION_DEADLINE_HOURS: int = int(os.getenv("NOTIFICATION_DEADLINE_HOURS", "2"))
    SUPPLIER_LEAD_TIME_HOURS: int = int(os.getenv("SUPPLIER_LEAD_TIME_HOURS", "48"))

    # Derived paths
    BASE_DIR: str = os.path.dirname(os.path.abspath(__file__))
    DB_PATH: str = os.path.join(BASE_DIR, "db", "app.db")
    TRACES_DIR: str = os.path.join(BASE_DIR, "traces")
    MOCK_DATA_DIR: str = os.path.join(os.path.dirname(BASE_DIR), "mock-data")


settings = Settings()
