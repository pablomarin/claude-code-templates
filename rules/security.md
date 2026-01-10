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
    openai_api_key: str
    jwt_secret: str

    class Config:
        env_file = ".env"
```

### .gitignore Required
```
.env
.env.local
.env.*.local
*.pem
*.key
```

## Credential Encryption (at rest)
- Use AES-256-GCM for stored credentials
- See `services/encryption.py` for implementation
- API never returns actual credential values (masked only)

```python
# Pattern from our implementation
def mask_api_key(key: str) -> str:
    """Show first 4 + ... + last 4 chars."""
    if len(key) <= 12:
        return "****"
    return f"{key[:4]}...{key[-4:]}"
```

## Logging Security

### Never Log
- Passwords or API keys
- Full credit card numbers
- Social security numbers
- JWT tokens
- Session tokens
- URLs containing API keys

### Secret Masking Patterns
See `services/secret_masking.py` - patterns for:
- AWS keys (`AKIA...`)
- GitHub tokens (`ghp_...`, `gho_...`)
- OpenAI keys (`sk-...`)
- Stripe keys (`sk_live_...`, `pk_live_...`)
- Azure keys
- JWT tokens
- Generic API keys

```python
# Always sanitize before logging
from services.secret_masking import SecretMaskingService

masker = SecretMaskingService()
safe_log = masker.mask_secrets(potentially_sensitive_string)
logger.info(safe_log)
```

## Input Validation

### Sanitize All User Input
- Use Pydantic models for validation
- Validate URL formats before fetching
- Limit string lengths
- Escape special characters in queries

```python
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

# Bad - string interpolation
result = await session.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

## Authentication & Authorization

### JWT Best Practices
- Short expiration (15-60 minutes for access tokens)
- Use refresh tokens for extended sessions
- Validate token on every request
- Include minimal claims (user_id, roles)

### API Key Handling
- Hash API keys before storing (one-way)
- Use constant-time comparison for validation
- Rate limit by API key
- Log access without logging the key itself

## HTTPS
- Enforce HTTPS in production
- Use secure cookies (HttpOnly, Secure, SameSite)
- Validate SSL certificates on outbound requests

## Reference
- Lasso Gateway PII patterns: `../mcp-gateway-main/src/security/`
- Lasso secret masking: `../mcp-gateway-main/src/masking/`
