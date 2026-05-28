"""
Database Connection & Session Management
==========================================
Configures the async SQLAlchemy engine and session factory.
Uses environment variables for database connection string.
"""

import os

from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker,
)
from sqlalchemy.orm import DeclarativeBase

# ========================
# Database URL
# ========================
# Read from environment variable, fallback to local PostgreSQL
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://expense_user:expense_pass_change_me@localhost:5432/expense_tracker",
)

# Convert postgresql:// to postgresql+asyncpg:// if needed
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)

# ========================
# SQLAlchemy Engine
# ========================
engine = create_async_engine(
    DATABASE_URL,
    echo=os.getenv("DEBUG", "false").lower() == "true",  # Log SQL in debug mode
    pool_size=10,          # Max connections in the pool
    max_overflow=20,       # Extra connections beyond pool_size
    pool_pre_ping=True,    # Verify connections before use
    pool_recycle=3600,     # Recycle connections after 1 hour
)

# ========================
# Session Factory
# ========================
async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


# ========================
# Declarative Base
# ========================
class Base(DeclarativeBase):
    """Base class for all ORM models."""
    pass


# ========================
# Dependency Injection
# ========================
async def get_db() -> AsyncSession:
    """
    FastAPI dependency that provides a database session.
    Automatically closes the session after the request.
    
    Usage in routers:
        @router.get("/")
        async def get_items(db: AsyncSession = Depends(get_db)):
            ...
    """
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
