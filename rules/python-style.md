# Python Style Rules

## General
- PEP 8 compliant, enforced via `ruff`
- 4 spaces for indentation (never tabs)
- Line length: 88 characters (ruff default)

## Naming Conventions
- `snake_case` for functions and variables
- `PascalCase` for classes
- `UPPER_CASE` for constants
- Private: prefix with `_` (e.g., `_internal_method`)

## Type Hints (Mandatory)
- All function signatures must have type hints (parameters and return values)
- Never use `Any` unless absolutely necessary
- Use `T | None` for nullable types (Python 3.10+ syntax)
- Run `mypy --strict` and resolve all errors

```python
# Good
def get_user(user_id: int) -> User | None:
    ...

# Bad
def get_user(user_id):
    ...
```

## Import Order
Organize imports in this order, separated by blank lines:
1. Standard library
2. Third-party packages
3. Local imports

Let `ruff` auto-sort via isort rules.

## Docstrings (Mandatory for Public APIs)
```python
def calculate_total(items: list[dict], tax_rate: float = 0.0) -> float:
    """Calculate the total cost of items including tax.

    Args:
        items: List of item dictionaries with 'price' keys.
        tax_rate: Tax rate as decimal (e.g., 0.08 for 8%).

    Returns:
        Total cost including tax.

    Raises:
        ValueError: If items is empty or tax_rate is negative.
    """
```

## Functions
- Single responsibility — one function, one job
- ≤5 parameters — if more needed, use a config object or dataclass
- Return early to reduce nesting
- Never use mutable defaults

```python
# Bad
def process(items: list = []):
    ...

# Good
def process(items: list | None = None):
    items = items or []
    ...
```

## Classes
- Keep `__init__` simple — no complex logic
- Use `dataclasses` for simple data containers
- Prefer composition over inheritance
- Use `@property` for computed attributes

## Async/Await
- Use `async def` for I/O-bound operations
- Always `await` async calls (don't block with sync code)
- Use `asyncio.gather()` for concurrent operations
- Use async database drivers (asyncpg, aiosqlite)

## Error Handling
```python
# Good - specific exceptions
try:
    result = await fetch_data(url)
except httpx.TimeoutException:
    logger.warning(f"Timeout fetching {url}")
    return None
except httpx.HTTPStatusError as e:
    logger.error(f"HTTP error: {e.response.status_code}")
    raise

# Bad - bare except
try:
    result = await fetch_data(url)
except:
    pass
```

## Comments
- Add explanatory comments for complex logic
- Keep comments up-to-date with code changes
- Delete commented-out code — don't commit it
- Use TODO/FIXME sparingly and include ticket numbers

## Quality Commands
```bash
# Format
ruff format .

# Lint
ruff check .

# Type check
mypy --strict src/

# All checks
ruff format . && ruff check . && mypy --strict src/
```
