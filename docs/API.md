# API Documentation

## Base URL

- **Development**: `http://localhost:8000/api/v1`
- **Production**: `http://<ec2-public-ip>/api/v1`
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

## Endpoints

### Health & Monitoring

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Liveness probe — returns service status |
| GET | `/ready` | Readiness probe — checks DB connectivity |
| GET | `/metrics` | Prometheus metrics endpoint |
| GET | `/docs` | Swagger interactive API docs |

### Expenses

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/expenses/` | List all expenses (paginated) |
| POST | `/api/v1/expenses/` | Create a new expense |
| GET | `/api/v1/expenses/{id}` | Get expense by ID |
| PUT | `/api/v1/expenses/{id}` | Update an expense |
| DELETE | `/api/v1/expenses/{id}` | Delete an expense |
| GET | `/api/v1/expenses/analytics/summary` | Get spending analytics |

### Categories

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/categories/` | List all categories |
| GET | `/api/v1/categories/stats` | Category spending stats |

## Request/Response Examples

### Create Expense
```bash
curl -X POST http://localhost:8000/api/v1/expenses/ \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Uber ride to office",
    "amount": 250.00,
    "date": "2026-05-28",
    "description": "Morning commute via Uber"
  }'
```

**Response** (201 Created):
```json
{
  "id": 1,
  "title": "Uber ride to office",
  "amount": 250.0,
  "category": "transport",
  "date": "2026-05-28",
  "description": "Morning commute via Uber",
  "created_at": "2026-05-28T08:00:00",
  "updated_at": "2026-05-28T08:00:00"
}
```
> Note: `category` was auto-assigned by the AI categorizer since none was provided.

### List Expenses
```bash
curl "http://localhost:8000/api/v1/expenses/?skip=0&limit=10&category=food&sort_by=date&sort_order=desc"
```

### Get Analytics
```bash
curl http://localhost:8000/api/v1/expenses/analytics/summary
```

**Response**:
```json
{
  "total_expenses": 15420.50,
  "total_count": 42,
  "average_expense": 367.15,
  "highest_expense": { "id": 5, "title": "Flight to Mumbai", "amount": 4500.00, "..." : "..." },
  "category_breakdown": [
    { "category": "food", "total_amount": 5200.00, "count": 15, "percentage": 33.72 },
    { "category": "transport", "total_amount": 3800.00, "count": 10, "percentage": 24.64 }
  ]
}
```

## Query Parameters (GET /expenses/)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `skip` | int | 0 | Number of records to skip (pagination) |
| `limit` | int | 20 | Max records to return (1-100) |
| `category` | string | null | Filter by category |
| `sort_by` | string | "date" | Sort field: date, amount, title |
| `sort_order` | string | "desc" | Sort order: asc, desc |

## Available Categories

`food`, `transport`, `housing`, `utilities`, `healthcare`, `entertainment`, `shopping`, `education`, `travel`, `subscriptions`, `groceries`, `personal`, `business`, `other`

## Error Responses

```json
// 404 Not Found
{ "detail": "Expense not found" }

// 422 Validation Error
{
  "detail": [
    {
      "loc": ["body", "amount"],
      "msg": "Input should be greater than 0",
      "type": "greater_than"
    }
  ]
}
```
