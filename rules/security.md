# Security

## Secrets
NEVER commit secrets to version control. Use environment variables.

```python
# Load from environment
import os
DATABASE_URL = os.environ["DATABASE_URL"]
JWT_SECRET = os.environ["JWT_SECRET"]

# Or use pydantic-settings
class Settings(BaseSettings):
    database_url: str
    jwt_secret: str
    model_config = SettingsConfigDict(env_file=".env")
```

## JWT Security (Critical)

**ALWAYS whitelist algorithms explicitly. NEVER trust the token's `alg` header.**

```python
# CORRECT: Explicit algorithm whitelist
payload = jwt.decode(
    token,
    secret,
    algorithms=["HS256"],  # Whitelist!
    options={"require": ["exp", "sub"]}
)

# WRONG: Trusts token header (allows algorithm substitution attack)
payload = jwt.decode(token, secret)
```

**Minimum secret length**: 64 characters for HS256. Generate with:
```bash
openssl rand -base64 48
```

## Password Hashing
```python
from passlib.context import CryptContext
pwd = CryptContext(schemes=["bcrypt"], bcrypt__rounds=12)

hashed = pwd.hash(password)           # Store this
valid = pwd.verify(password, hashed)  # Check this
```

NEVER store plain text passwords. NEVER use MD5/SHA1 for passwords.

## SQL Injection
ALWAYS use parameterized queries. ORMs handle this automatically.

```python
# CORRECT (SQLAlchemy)
session.execute(select(User).where(User.email == email))

# CORRECT (raw SQL with parameters)
session.execute(text("SELECT * FROM users WHERE email = :email"), {"email": email})

# WRONG: String concatenation = SQL injection
session.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

## Input Validation
ALWAYS validate with Pydantic before processing:
```python
class WebhookCreate(BaseModel):
    url: HttpUrl
    
    @field_validator("url")
    def https_only(cls, v):
        if v.scheme != "https":
            raise ValueError("HTTPS required")
        return v
```

## Logging
NEVER log sensitive data:
```python
# WRONG
logger.info(f"User login with token: {token}")
logger.debug(f"Request: {request.json()}")  # May contain passwords

# CORRECT
logger.info(f"User {user_id} logged in")
```

## Cookies
```python
response.set_cookie(
    key="session",
    value=token,
    httponly=True,   # No JavaScript access
    secure=True,     # HTTPS only
    samesite="lax",  # CSRF protection
)
```

## Rules
1. NEVER commit secrets to git — use environment variables
2. NEVER trust JWT `alg` header — always whitelist algorithms
3. NEVER store passwords in plain text — use bcrypt
4. NEVER log tokens, passwords, or API keys
5. NEVER use string concatenation for SQL
6. ALWAYS validate all external input with Pydantic
7. ALWAYS use HTTPS in production
8. ALWAYS set `httponly`, `secure`, `samesite` on auth cookies
