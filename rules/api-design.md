# API Design

## URL Structure
```
GET    /api/v1/users          # List
GET    /api/v1/users/{id}     # Get one
POST   /api/v1/users          # Create
PATCH  /api/v1/users/{id}     # Partial update
DELETE /api/v1/users/{id}     # Delete
```

Use plural nouns, kebab-case for multi-word (`/order-items`), always version (`/api/v1/`).

## Status Codes
| Code | When |
|------|------|
| 200 | Success (GET, PATCH, PUT) |
| 201 | Created (POST) — include `Location` header |
| 204 | Deleted (DELETE) — no body |
| 400 | Malformed request syntax |
| 401 | Missing/invalid authentication |
| 403 | Authenticated but not authorized |
| 404 | Resource not found |
| 409 | Conflict (duplicate, state conflict) |
| 422 | Valid syntax but semantic error (validation) |
| 429 | Rate limited — include `Retry-After` header |

## Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [{"field": "email", "message": "Invalid format"}],
    "request_id": "req_abc123"
  }
}
```

## Pagination Response
```json
{
  "items": [...],
  "total": 150,
  "page": 1,
  "page_size": 20
}
```

## Schema Separation
Create separate schemas for different operations:
```python
class UserCreate(BaseModel):   # POST body
    email: EmailStr
    password: str

class UserUpdate(BaseModel):   # PATCH body — all optional
    name: str | None = None

class UserResponse(BaseModel): # Response — no sensitive fields
    id: UUID
    email: str
    created_at: datetime
```

## Rules
1. ALWAYS version APIs (`/api/v1/`)
2. ALWAYS use consistent error format with `request_id`
3. ALWAYS validate input with Pydantic
4. ALWAYS return 201 + Location header for POST
5. NEVER expose internal errors to clients
6. NEVER return password or sensitive fields in responses
7. PREFER 422 for validation errors, 400 for malformed syntax
8. PREFER PATCH (partial update) over PUT (full replacement)
