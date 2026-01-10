# API Design Rules

## REST Conventions

### URL Structure
- Use plural nouns for resources: `/api/v1/servers`, `/api/v1/skills`
- Nested resources for relationships: `/api/v1/servers/{id}/tools`
- Version APIs: `/api/v1/...`
- Use kebab-case for multi-word paths: `/api/v1/tool-calls`

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

## MCP Gateway Specific APIs

### Two-Function Interface (adapted from Gate22)
```
POST /api/v1/search
POST /api/v1/execute
```

### Registry API (adapted from Obot)
```
GET    /api/v1/servers
POST   /api/v1/servers
GET    /api/v1/servers/{id}
PUT    /api/v1/servers/{id}
DELETE /api/v1/servers/{id}
POST   /api/v1/servers/{id}/sync
```

### Skills API (Fresh implementation)
```
GET    /api/v1/skills
POST   /api/v1/skills
GET    /api/v1/skills/{id}
DELETE /api/v1/skills/{id}
POST   /api/v1/skills/generate  # SSE streaming
```

### Generation API (Fresh implementation)
```
POST   /api/v1/generate         # SSE streaming
GET    /api/v1/generate/{id}
POST   /api/v1/generate/{id}/approve
DELETE /api/v1/generate/{id}
```

## Request/Response Patterns

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
    "message": "Invalid server configuration",
    "details": [
      {"field": "url", "message": "URL is required for remote servers"}
    ]
  }
}
```

### SSE Streaming (for AI generation)
```
event: progress
data: {"phase": "analyzing", "percent": 25, "message": "Parsing API spec..."}

event: complete
data: {"server_id": "uuid", "tools_count": 15}

event: error
data: {"code": "GENERATION_FAILED", "message": "..."}
```

## FastAPI Implementation

### Router Structure
```python
from fastapi import APIRouter, Depends, HTTPException, status

router = APIRouter(prefix="/api/v1/servers", tags=["servers"])

@router.get("", response_model=ServerListResponse)
async def list_servers(
    skip: int = 0,
    limit: int = 20,
    session: AsyncSession = Depends(get_session),
) -> ServerListResponse:
    ...
```

### Dependency Injection
- Use `Depends()` for session, auth, services
- Create service factories as dependencies
- Keep route handlers thin — delegate to services

### Validation
- Use Pydantic models for request/response validation
- Define separate Create, Update, Response schemas
- Use `Field()` for constraints and documentation

```python
class ServerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    url: str | None = Field(None, pattern=r"^https?://")
    type: ServerType = Field(default=ServerType.REMOTE)
```

## Reference
- Gate22 bundle API: `../gate22-main/backend/aci/server/`
- Obot registry API: `../obot-main/pkg/api/`
- Context Forge REST-to-MCP: `../mcp-context-forge-main/src/api/`
