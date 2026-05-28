"""
Categories Router
==================
Provides endpoints for listing and managing expense categories.
"""

from fastapi import APIRouter, Depends
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Expense, ExpenseCategory

router = APIRouter()


@router.get("/")
async def list_categories():
    """List all available expense categories."""
    return {
        "categories": [
            {"value": cat.value, "label": cat.value.replace("_", " ").title()}
            for cat in ExpenseCategory
        ]
    }


@router.get("/stats")
async def category_stats(db: AsyncSession = Depends(get_db)):
    """
    Get spending statistics for each category.
    Returns total amount, count, and percentage per category.
    """
    # Get overall total
    total_result = await db.execute(select(func.sum(Expense.amount)))
    grand_total = float(total_result.scalar() or 0)

    # Get per-category stats
    result = await db.execute(
        select(
            Expense.category,
            func.sum(Expense.amount).label("total_amount"),
            func.count(Expense.id).label("count"),
        )
        .group_by(Expense.category)
        .order_by(desc("total_amount"))
    )
    rows = result.all()

    stats = []
    for row in rows:
        stats.append({
            "category": row.category.value if row.category else "other",
            "total_amount": round(float(row.total_amount), 2),
            "count": int(row.count),
            "percentage": (
                round(float(row.total_amount) / grand_total * 100, 2)
                if grand_total > 0
                else 0
            ),
        })

    return {
        "grand_total": round(grand_total, 2),
        "categories": stats,
    }
