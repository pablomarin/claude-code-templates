# Security Rules

## Secrets Management

### Never Store in Code
- API keys
- Passwords
- Database credentials
- JWT secrets
- Encryption keys

### Use Environment Variables
```python
# Good
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    secret_key: str
    api_key: str

    model_config = {"env_file": ".env"}

settings = Settings()
```

### .gitignore Required
```
.env
.env.local
.env.*.local
*.pem
*.key
secrets/
```

## Credential Encryption (at rest)

When storing credentials in the database:
- Use AES-256-GCM for encryption
- Store encryption key in environment variable
- Never return actual values via API (masked only)

```python
def mask_secret(value: str) -> str:
    """Show first 4 + ... + last 4 chars."""
    if len(value) <= 12:
        return "****"
    return f"{value[:4]}...{value[-4:]}"
```

## Logging Security

### Never Log
- Passwords or API keys
- Full credit card numbers
- Social security numbers
- JWT tokens
- Session tokens
- URLs containing API keys or tokens

### Safe Logging Pattern
```python
import logging

logger = logging.getLogger(__name__)

# Bad
logger.info(f"User logged in with token: {token}")

# Good
logger.info(f"User {user_id} logged in successfully")
```

### Secret Patterns to Mask
If logging potentially sensitive strings, mask these patterns:
- AWS keys (`AKIA...`)
- GitHub tokens (`ghp_...`, `gho_...`)
- OpenAI keys (`sk-...`)
- Stripe keys (`sk_live_...`, `pk_live_...`)
- Generic API keys (long alphanumeric strings)
- JWT tokens (`eyJ...`)

## Input Validation

### Sanitize All User Input
- Use Pydantic models for validation
- Validate URL formats before fetching
- Limit string lengths
- Escape special characters in queries

```python
from pydantic import BaseModel, Field, HttpUrl

class ServerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    url: HttpUrl | None = None  # Pydantic validates URL format
```

### SQL Injection Prevention
- Always use parameterized queries (SQLAlchemy handles this)
- Never construct SQL strings manually
- Use ORM methods, not raw SQL

```python
# Good - parameterized
result = await session.execute(
    select(User).where(User.email == email)
)

# Bad - string interpolation (NEVER DO THIS)
result = await session.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

### XSS Prevention
- Escape HTML in user-generated content
- Use Content-Security-Policy headers
- Sanitize before rendering in frontend

## Authentication & Authorization

### JWT Best Practices
- Short expiration (15-60 minutes for access tokens)
- Use refresh tokens for extended sessions
- Validate token on every request
- Include minimal claims (user_id, roles)

```python
from datetime import datetime, timedelta
import jwt

def create_access_token(user_id: str, expires_delta: timedelta = timedelta(minutes=30)) -> str:
    expire = datetime.utcnow() + expires_delta
    payload = {
        "sub": user_id,
        "exp": expire,
        "type": "access"
    }
    return jwt.encode(payload, settings.secret_key, algorithm="HS256")
```

### API Key Handling
- Hash API keys before storing (one-way)
- Use constant-time comparison for validation
- Rate limit by API key
- Log access without logging the key itself

```python
import hashlib
import secrets

def generate_api_key() -> tuple[str, str]:
    """Returns (plain_key, hashed_key)."""
    plain = secrets.token_urlsafe(32)
    hashed = hashlib.sha256(plain.encode()).hexdigest()
    return plain, hashed

def verify_api_key(plain: str, hashed: str) -> bool:
    """Constant-time comparison."""
    return secrets.compare_digest(
        hashlib.sha256(plain.encode()).hexdigest(),
        hashed
    )
```

### Password Hashing
```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

## HTTPS & Cookies
- Enforce HTTPS in production
- Use secure cookies:
  - `HttpOnly` - prevents JavaScript access
  - `Secure` - only sent over HTTPS
  - `SameSite=Lax` or `Strict` - prevents CSRF
- Validate SSL certificates on outbound requests

```python
# FastAPI cookie example
from fastapi import Response

response.set_cookie(
    key="session",
    value=session_token,
    httponly=True,
    secure=True,  # HTTPS only
    samesite="lax",
    max_age=3600,
)
```

## Rate Limiting
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.get("/api/v1/resource")
@limiter.limit("100/minute")
async def get_resource(request: Request):
    ...
```

## Critical Rules
- **Never commit secrets** to version control
- **Always hash passwords** — never store plain text
- **Validate all input** — assume everything is malicious
- **Use HTTPS** in production — no exceptions
- **Log securely** — never log sensitive data
- **Rotate secrets** periodically — API keys, JWT secrets
