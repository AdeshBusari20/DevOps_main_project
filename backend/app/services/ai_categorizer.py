"""
AI Expense Categorizer - Rule-Based Engine
============================================
Automatically categorizes expenses based on keywords in the title
and description. Uses a weighted keyword matching algorithm.

Future Enhancement:
    Integrate with OpenAI API for receipt OCR and smart prediction.
"""

import re
from typing import Dict, List


class AICategorizer:
    """
    Rule-based AI categorizer that matches expense titles/descriptions
    against predefined keyword patterns to assign categories.
    
    The algorithm:
    1. Normalize input text (lowercase, strip whitespace)
    2. Check each category's keywords against the text
    3. Score matches by keyword specificity (longer keywords = higher weight)
    4. Return the category with the highest score
    5. Default to "other" if no match found
    """

    def __init__(self):
        # Keyword mappings: category -> list of keywords
        # More specific keywords are weighted higher automatically
        self.category_keywords: Dict[str, List[str]] = {
            "food": [
                "restaurant", "lunch", "dinner", "breakfast", "coffee",
                "cafe", "pizza", "burger", "sushi", "takeout", "takeaway",
                "doordash", "uber eats", "zomato", "swiggy", "food delivery",
                "meal", "snack", "biryani", "dosa", "thali", "canteen",
                "cafeteria", "mcdonald", "kfc", "dominos", "starbucks",
            ],
            "transport": [
                "uber", "lyft", "taxi", "cab", "bus", "metro", "train",
                "fuel", "petrol", "diesel", "gas station", "parking",
                "toll", "auto rickshaw", "ola", "rapido", "bike ride",
                "flight", "airline", "railway", "transport",
            ],
            "housing": [
                "rent", "mortgage", "property tax", "home insurance",
                "maintenance", "repair", "plumber", "electrician",
                "furniture", "apartment", "house", "flat", "pg",
                "hostel", "accommodation", "lease",
            ],
            "utilities": [
                "electricity", "water bill", "gas bill", "internet",
                "wifi", "broadband", "phone bill", "mobile recharge",
                "jio", "airtel", "vodafone", "bsnl", "postpaid",
                "prepaid", "utility",
            ],
            "healthcare": [
                "doctor", "hospital", "pharmacy", "medicine", "medical",
                "dental", "dentist", "eye", "optician", "therapy",
                "gym", "fitness", "yoga", "health insurance", "clinic",
                "lab test", "diagnostic", "apollo", "consultation",
            ],
            "entertainment": [
                "movie", "netflix", "amazon prime", "hotstar", "spotify",
                "youtube premium", "concert", "theatre", "gaming", "game",
                "playstation", "xbox", "steam", "cinema", "multiplex",
                "pvr", "inox", "park", "amusement", "club",
            ],
            "shopping": [
                "amazon", "flipkart", "myntra", "ajio", "clothes",
                "shoes", "electronics", "gadget", "phone", "laptop",
                "headphones", "watch", "jewelry", "cosmetics", "makeup",
                "shopping", "mall", "online order", "fashion",
            ],
            "education": [
                "course", "udemy", "coursera", "book", "tuition",
                "school", "college", "university", "exam", "certification",
                "training", "workshop", "seminar", "education", "fees",
                "stationery", "notebook", "textbook", "library",
            ],
            "travel": [
                "hotel", "airbnb", "booking", "vacation", "holiday",
                "trip", "travel", "luggage", "passport", "visa",
                "tourism", "sightseeing", "resort", "beach", "mountain",
            ],
            "subscriptions": [
                "subscription", "membership", "annual plan", "monthly plan",
                "premium", "pro plan", "saas", "cloud storage", "dropbox",
                "icloud", "google one", "github", "linkedin premium",
                "newspaper", "magazine",
            ],
            "groceries": [
                "grocery", "supermarket", "vegetables", "fruits", "milk",
                "bread", "rice", "dal", "oil", "spices", "blinkit",
                "bigbasket", "zepto", "dmart", "reliance fresh",
                "more supermarket", "provisions", "ration",
            ],
            "personal": [
                "haircut", "salon", "spa", "laundry", "dry cleaning",
                "personal care", "grooming", "barber", "parlour",
                "gift", "donation", "charity",
            ],
            "business": [
                "office supplies", "client meeting", "business lunch",
                "conference", "coworking", "wework", "domain", "hosting",
                "server", "aws", "azure", "gcp", "software license",
                "freelance", "invoice", "business",
            ],
        }

    def categorize(self, title: str, description: str = "") -> str:
        """
        Categorize an expense based on its title and description.
        
        Args:
            title: The expense title (e.g., "Uber ride to airport")
            description: Optional detailed description
            
        Returns:
            Category string (e.g., "transport")
        """
        # Combine and normalize text
        text = f"{title} {description}".lower().strip()

        # Score each category
        scores: Dict[str, float] = {}
        for category, keywords in self.category_keywords.items():
            score = 0.0
            for keyword in keywords:
                # Use word boundary matching for accuracy
                pattern = re.compile(r'\b' + re.escape(keyword) + r'\b', re.IGNORECASE)
                matches = pattern.findall(text)
                if matches:
                    # Longer keywords = more specific = higher weight
                    weight = len(keyword.split()) * 1.5
                    score += len(matches) * weight

            if score > 0:
                scores[category] = score

        # Return highest scoring category, or "other" if no match
        if scores:
            return max(scores, key=scores.get)
        return "other"

    def get_confidence(self, title: str, description: str = "") -> dict:
        """
        Get categorization with confidence scores for all matching categories.
        Useful for debugging and future ML model training.
        """
        text = f"{title} {description}".lower().strip()
        scores: Dict[str, float] = {}

        for category, keywords in self.category_keywords.items():
            score = 0.0
            matched_keywords = []
            for keyword in keywords:
                pattern = re.compile(r'\b' + re.escape(keyword) + r'\b', re.IGNORECASE)
                matches = pattern.findall(text)
                if matches:
                    weight = len(keyword.split()) * 1.5
                    score += len(matches) * weight
                    matched_keywords.append(keyword)

            if score > 0:
                scores[category] = {
                    "score": score,
                    "matched_keywords": matched_keywords,
                }

        total_score = sum(s["score"] for s in scores.values()) if scores else 1
        result = {
            cat: {
                "confidence": round(data["score"] / total_score * 100, 1),
                "matched_keywords": data["matched_keywords"],
            }
            for cat, data in sorted(
                scores.items(),
                key=lambda x: x[1]["score"],
                reverse=True,
            )
        }

        predicted = max(scores, key=lambda k: scores[k]["score"]) if scores else "other"
        return {
            "predicted_category": predicted,
            "scores": result,
        }
