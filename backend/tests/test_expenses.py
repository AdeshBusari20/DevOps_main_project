"""
Unit Tests - AI Categorizer & Expense Endpoints
=================================================
Tests for the AI categorization engine and expense CRUD operations.
"""

import pytest
from app.services.ai_categorizer import AICategorizer


class TestAICategorizer:
    """Test suite for the rule-based AI categorizer."""

    def setup_method(self):
        """Initialize categorizer before each test."""
        self.categorizer = AICategorizer()

    def test_food_categorization(self):
        """Test that food-related expenses are categorized correctly."""
        assert self.categorizer.categorize("Lunch at restaurant") == "food"
        assert self.categorizer.categorize("Starbucks coffee") == "food"
        assert self.categorizer.categorize("Zomato food delivery") == "food"
        assert self.categorizer.categorize("Dominos pizza order") == "food"

    def test_transport_categorization(self):
        """Test that transport expenses are categorized correctly."""
        assert self.categorizer.categorize("Uber ride to office") == "transport"
        assert self.categorizer.categorize("Metro card recharge") == "transport"
        assert self.categorizer.categorize("Petrol fuel station") == "transport"
        assert self.categorizer.categorize("Ola cab booking") == "transport"

    def test_housing_categorization(self):
        """Test that housing expenses are categorized correctly."""
        assert self.categorizer.categorize("Monthly rent payment") == "housing"
        assert self.categorizer.categorize("Apartment maintenance") == "housing"

    def test_utilities_categorization(self):
        """Test that utility expenses are categorized correctly."""
        assert self.categorizer.categorize("Electricity bill payment") == "utilities"
        assert self.categorizer.categorize("Jio mobile recharge") == "utilities"
        assert self.categorizer.categorize("Internet wifi bill") == "utilities"

    def test_healthcare_categorization(self):
        """Test that healthcare expenses are categorized correctly."""
        assert self.categorizer.categorize("Doctor consultation fee") == "healthcare"
        assert self.categorizer.categorize("Pharmacy medicine purchase") == "healthcare"

    def test_entertainment_categorization(self):
        """Test that entertainment expenses are categorized correctly."""
        assert self.categorizer.categorize("Netflix subscription") == "entertainment"
        assert self.categorizer.categorize("Movie tickets PVR cinema") == "entertainment"

    def test_shopping_categorization(self):
        """Test that shopping expenses are categorized correctly."""
        assert self.categorizer.categorize("Amazon order electronics") == "shopping"
        assert self.categorizer.categorize("Flipkart phone purchase") == "shopping"

    def test_education_categorization(self):
        """Test that education expenses are categorized correctly."""
        assert self.categorizer.categorize("Udemy course purchase") == "education"
        assert self.categorizer.categorize("College tuition fees") == "education"

    def test_groceries_categorization(self):
        """Test that grocery expenses are categorized correctly."""
        assert self.categorizer.categorize("BigBasket grocery order") == "groceries"
        assert self.categorizer.categorize("DMart vegetables and fruits") == "groceries"

    def test_unknown_categorization(self):
        """Test that unknown expenses default to 'other'."""
        assert self.categorizer.categorize("Random unknown thing xyz") == "other"
        assert self.categorizer.categorize("") == "other"

    def test_description_helps_categorization(self):
        """Test that description text improves categorization."""
        result = self.categorizer.categorize(
            title="Payment",
            description="Paid for uber ride to airport",
        )
        assert result == "transport"

    def test_confidence_scores(self):
        """Test that confidence scoring returns valid structure."""
        result = self.categorizer.get_confidence("Uber ride to restaurant")
        assert "predicted_category" in result
        assert "scores" in result
        assert isinstance(result["scores"], dict)
