"""
Expenses Router - CRUD Operations
===================================
Provides Create, Read, Update, Delete endpoints for expenses.
Includes pagination, filtering, and AI auto-categorization.
"""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Expense, ExpenseCategory
from app.schemas import (
    ExpenseCreate,
    ExpenseUpdate,
    ExpenseResponse,
    ExpenseListResponse,
    ExpenseAnalytics,
    CategorySummary,
)
from app.services.ai_categorizer import AICategorizer

router = APIRouter()
categorizer = AICategorizer()


# ========================
# CREATE - Add New Expense
# ========================
@router.post("/", response_model=ExpenseResponse, status_code=201)
async def create_expense(
    expense_data: ExpenseCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new expense record.
    If no category is provided, the AI categorizer will auto-assign one
    based on the expense title and description.
    """
    # Auto-categorize if no category provided
    if expense_data.category is None:
        predicted_category = categorizer.categorize(
            title=expense_data.title,
            description=expense_data.description or "",
        )
        expense_data.category = ExpenseCategory(predicted_category)

    # Create the database record
    expense = Expense(
        title=expense_data.title,
        amount=expense_data.amount,
        category=expense_data.category,
        date=expense_data.date,
        description=expense_data.description,
    )
    db.add(expense)
    await db.flush()
    await db.refresh(expense)
    return expense


# ========================
# READ - Get All Expenses
# ========================
@router.get("/", response_model=ExpenseListResponse)
async def get_expenses(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(20, ge=1, le=100, description="Max records to return"),
    category: Optional[ExpenseCategory] = Query(None, description="Filter by category"),
    sort_by: str = Query("date", description="Sort field: date, amount, title"),
    sort_order: str = Query("desc", description="Sort order: asc or desc"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve a paginated list of expenses with optional filtering and sorting.
    """
    # Build the base query
    query = select(Expense)
    count_query = select(func.count(Expense.id))

    # Apply category filter
    if category:
        query = query.where(Expense.category == category)
        count_query = count_query.where(Expense.category == category)

    # Apply sorting
    sort_column = getattr(Expense, sort_by, Expense.date)
    if sort_order == "desc":
        query = query.order_by(desc(sort_column))
    else:
        query = query.order_by(sort_column)

    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar()

    # Apply pagination
    query = query.offset(skip).limit(limit)
    result = await db.execute(query)
    expenses = result.scalars().all()

    return ExpenseListResponse(total=total, expenses=expenses)


# ========================
# READ - Get Single Expense
# ========================
@router.get("/{expense_id}", response_model=ExpenseResponse)
async def get_expense(
    expense_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Retrieve a single expense by its ID."""
    result = await db.execute(select(Expense).where(Expense.id == expense_id))
    expense = result.scalar_one_or_none()

    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    return expense


# ========================
# UPDATE - Modify Expense
# ========================
@router.put("/{expense_id}", response_model=ExpenseResponse)
async def update_expense(
    expense_id: int,
    expense_data: ExpenseUpdate,
    db: AsyncSession = Depends(get_db),
):
    """
    Update an existing expense. Only provided fields are updated (partial update).
    """
    result = await db.execute(select(Expense).where(Expense.id == expense_id))
    expense = result.scalar_one_or_none()

    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    # Update only provided fields
    update_data = expense_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(expense, field, value)

    await db.flush()
    await db.refresh(expense)
    return expense


# ========================
# DELETE - Remove Expense
# ========================
@router.delete("/{expense_id}", status_code=204)
async def delete_expense(
    expense_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Delete an expense by its ID."""
    result = await db.execute(select(Expense).where(Expense.id == expense_id))
    expense = result.scalar_one_or_none()

    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    await db.delete(expense)


# ========================
# ANALYTICS - Expense Summary
# ========================
@router.get("/analytics/summary", response_model=ExpenseAnalytics)
async def get_analytics(db: AsyncSession = Depends(get_db)):
    """
    Get expense analytics including total spending, averages,
    and category breakdown with percentages.
    """
    # Total stats
    stats_result = await db.execute(
        select(
            func.sum(Expense.amount).label("total"),
            func.count(Expense.id).label("count"),
            func.avg(Expense.amount).label("average"),
        )
    )
    stats = stats_result.one()

    total_expenses = float(stats.total or 0)
    total_count = int(stats.count or 0)
    average_expense = float(stats.average or 0)

    # Highest expense
    highest_result = await db.execute(
        select(Expense).order_by(desc(Expense.amount)).limit(1)
    )
    highest_expense = highest_result.scalar_one_or_none()

    # Category breakdown
    category_result = await db.execute(
        select(
            Expense.category,
            func.sum(Expense.amount).label("total_amount"),
            func.count(Expense.id).label("count"),
        )
        .group_by(Expense.category)
        .order_by(desc("total_amount"))
    )
    categories = category_result.all()

    category_breakdown = [
        CategorySummary(
            category=row.category.value if row.category else "other",
            total_amount=float(row.total_amount),
            count=int(row.count),
            percentage=(
                round(float(row.total_amount) / total_expenses * 100, 2)
                if total_expenses > 0
                else 0
            ),
        )
        for row in categories
    ]

    return ExpenseAnalytics(
        total_expenses=total_expenses,
        total_count=total_count,
        average_expense=round(average_expense, 2),
        highest_expense=highest_expense,
        category_breakdown=category_breakdown,
    )
