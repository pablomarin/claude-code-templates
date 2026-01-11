# API Design Rules

## REST Conventions

### URL Structure
- Use plural nouns for resources: `/api/v1/users`, `/api/v1/orders`
- Nested resources for relationships: `/api/v1/users/{id}/orders`
- Version APIs: `/api/v1/...`
- Use kebab-case for multi-word paths: `/api/v1/order-items`

### HTTP Methods
| Method | Purpose | Response |
|--------|---------|----------|
| GET | Read resource(s) | 200 + data |
| POST | Create resource | 201 + created resource |
| PUT | Full update | 200 + updated resource |
| PATCH | Partial update | 200 + updated resource |
| DELETE | Remove resource | 204 (no content) |

### Status Codes
| Code | When |
|------|------|
| 200 | Success (GET, PUT, PATCH) |
| 201 | Created (POST) |
| 204 | No content (DELETE) |
| 400 | Bad request (validation error) |
| 401 | Unauthorized (no/invalid auth) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not found |
| 409 | Conflict (duplicate, state conflict) |
| 422 | Unprocessable entity (semantic error) |
| 500 | Internal server error |

## Request/Response Patterns

### Single Resource Response
```json
{
  "id": "uuid",
  "name": "Example",
  "created_at": "2025-01-10T12:00:00Z",
  "updated_at": "2025-01-10T12:00:00Z"
}
```

### List Response (Pagination)
```json
{
  "items": [...],
  "total": 100,
  "page": 1,
  "page_size": 20,
  "has_next": true
}
```

### Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": [
      {"field": "email", "message": "Invalid email format"}
    ]
  }
}
```

### SSE Streaming (for long-running operations)
```
event: progress
data: {"phase": "processing", "percent": 25, "message": "Processing..."}

event: complete
data: {"result_id": "uuid", "status": "success"}

event: error
data: {"code": "PROCESSING_FAILED", "message": "..."}
```

## FastAPI Implementation

### Router Structure
```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/api/v1/users", tags=["users"])

@router.get("", response_model=UserListResponse)
async def list_users(
    skip: int = 0,
    limit: int = 20,
    session: AsyncSession = Depends(get_session),
) -> UserListResponse:
    repo = UserRepository(session)
    users = await repo.list(skip=skip, limit=limit)
    total = await repo.count()
    return UserListResponse(
        items=users,
        total=total,
        page=skip // limit + 1,
        page_size=limit,
        has_next=skip + limit < total,
    )

@router.get("/{id}", response_model=UserResponse)
async def get_user(
    id: UUID,
    session: AsyncSession = Depends(get_session),
) -> UserResponse:
    repo = UserRepository(session)
    user = await repo.get_by_id(id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    data: UserCreate,
    session: AsyncSession = Depends(get_session),
) -> UserResponse:
    repo = UserRepository(session)
    user = await repo.create(User(**data.model_dump()))
    await session.commit()
    return user

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    id: UUID,
    session: AsyncSession = Depends(get_session),
) -> None:
    repo = UserRepository(session)
    user = await repo.get_by_id(id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await repo.delete(user)
    await session.commit()
```

### Dependency Injection
- Use `Depends()` for session, auth, services
- Create service factories as dependencies
- Keep route handlers thin — delegate to services

```python
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    session: AsyncSession = Depends(get_session),
) -> User:
    user = await verify_token(token, session)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user

@router.get("/me")
async def get_me(user: User = Depends(get_current_user)) -> UserResponse:
    return user
```

### Validation with Pydantic
- Use Pydantic models for request/response validation
- Define separate Create, Update, Response schemas
- Use `Field()` for constraints and documentation

```python
from pydantic import BaseModel, Field, EmailStr

class UserCreate(BaseModel):
    email: EmailStr
    name: str = Field(..., min_length=1, max_length=255)
    
class UserUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    
class UserResponse(BaseModel):
    id: UUID
    email: str
    name: str
    created_at: datetime
    
    model_config = {"from_attributes": True}
```

## Query Parameters

### Filtering
```
GET /api/v1/orders?status=pending&user_id=uuid
```

### Sorting
```
GET /api/v1/orders?sort_by=created_at&sort_order=desc
```

### Pagination
```
GET /api/v1/orders?page=1&page_size=20
# or offset-based
GET /api/v1/orders?skip=0&limit=20
```

### Search
```
GET /api/v1/users?search=john
```

## Critical Rules
- **Always version your API** (`/api/v1/...`)
- **Use consistent response formats** across all endpoints
- **Return appropriate status codes** — don't always use 200
- **Validate all input** — never trust client data
- **Document with OpenAPI** — FastAPI does this automatically
- **Use async for I/O operations** — database, external APIs
