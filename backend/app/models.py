"""
Database Models - SQLAlchemy ORM
================================
Defines the database schema for the expense tracker application.
Uses SQLAlchemy's declarative base with async support.
"""

import enum
from datetime import datetime, date

from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    Date,
    DateTime,
    Text,
    Enum as SAEnum,
)
from app.database import Base


class ExpenseCategory(str, enum.Enum):
    """Predefined expense categories for AI categorization."""
    FOOD = "food"
    TRANSPORT = "transport"
    HOUSING = "housing"
    UTILITIES = "utilities"
    HEALTHCARE = "healthcare"
    ENTERTAINMENT = "entertainment"
    SHOPPING = "shopping"
    EDUCATION = "education"
    TRAVEL = "travel"
    SUBSCRIPTIONS = "subscriptions"
    GROCERIES = "groceries"
    PERSONAL = "personal"
    BUSINESS = "business"
    OTHER = "other"


class Expense(Base):
    """
    Expense model representing a single expense record.
    
    Attributes:
        id: Auto-incrementing primary key
        title: Short description of the expense (e.g., "Uber ride")
        amount: Expense amount in the user's currency
        category: AI-categorized or manually selected category
        date: Date the expense occurred
        description: Optional detailed description
        created_at: Timestamp when the record was created
        updated_at: Timestamp when the record was last modified
    """
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(255), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    category = Column(
        SAEnum(ExpenseCategory),
        default=ExpenseCategory.OTHER,
        nullable=False,
        index=True,
    )
    date = Column(Date, default=date.today, nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    def __repr__(self):
        return (
            f"<Expense(id={self.id}, title='{self.title}', "
            f"amount={self.amount}, category='{self.category}')>"
        )
