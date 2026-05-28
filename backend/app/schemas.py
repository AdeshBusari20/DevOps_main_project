"""
Pydantic Schemas - Request/Response Validation
================================================
Defines data validation schemas for API request bodies and responses.
Pydantic ensures type safety and automatic documentation in Swagger UI.
"""

from datetime import date as Date, datetime
from typing import Optional, List

from pydantic import BaseModel, Field, ConfigDict

from app.models import ExpenseCategory


# ========================
# Request Schemas (Input)
# ========================
class ExpenseCreate(BaseModel):
    """Schema for creating a new expense."""
    title: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="Short description of the expense",
        examples=["Uber ride to office"],
    )
    amount: float = Field(
        ...,
        gt=0,
        description="Expense amount (must be positive)",
        examples=[25.50],
    )
    category: Optional[ExpenseCategory] = Field(
        default=None,
        description="Expense category (auto-categorized if not provided)",
    )
    date: Date = Field(
        default_factory=Date.today,
        description="Date of the expense",
    )
    description: Optional[str] = Field(
        default=None,
        max_length=1000,
        description="Optional detailed description",
    )


class ExpenseUpdate(BaseModel):
    """Schema for updating an existing expense (partial update)."""
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    amount: Optional[float] = Field(None, gt=0)
    category: Optional[ExpenseCategory] = None
    date: Optional[Date] = None
    description: Optional[str] = Field(None, max_length=1000)


# ========================
# Response Schemas (Output)
# ========================
class ExpenseResponse(BaseModel):
    """Schema for returning an expense in API responses."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    amount: float
    category: ExpenseCategory
    date: Date
    description: Optional[str]
    created_at: datetime
    updated_at: datetime


class ExpenseListResponse(BaseModel):
    """Schema for returning a paginated list of expenses."""
    total: int = Field(description="Total number of expenses")
    expenses: List[ExpenseResponse]


# ========================
# Analytics Schemas
# ========================
class CategorySummary(BaseModel):
    """Summary of spending per category."""
    category: str
    total_amount: float
    count: int
    percentage: float


class ExpenseAnalytics(BaseModel):
    """Overall expense analytics."""
    total_expenses: float
    total_count: int
    average_expense: float
    highest_expense: Optional[ExpenseResponse]
    category_breakdown: List[CategorySummary]


# ========================
# Health Check Schema
# ========================
class HealthResponse(BaseModel):
    """Health check response schema."""
    status: str
    service: str
