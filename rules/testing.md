# Testing

## Structure
```
tests/
├── conftest.py      # Shared fixtures
├── unit/            # Isolated, fast, mock external
├── integration/     # Real database, real services
└── e2e/             # Full system, browser tests
```

## Naming
- Files: `test_{module}.py`
- Functions: `test_{action}_{scenario}_{expected}`

```python
def test_create_user_with_valid_data_returns_user(): ...
def test_create_user_with_duplicate_email_raises_conflict(): ...
```

## Arrange-Act-Assert Pattern
ALWAYS structure tests with clear AAA separation:

```python
async def test_create_user_with_valid_data(session):
    # Arrange
    repo = UserRepository(session)
    data = UserCreate(email="test@example.com", name="Test")
    
    # Act
    result = await repo.create(data)
    
    # Assert
    assert result.id is not None
    assert result.email == "test@example.com"
```

## Fixtures
Use factories over hard-coded data:

```python
@pytest.fixture
def make_user():
    def _make(email: str = None, **kwargs) -> User:
        return User(email=email or f"{uuid4()}@test.com", **kwargs)
    return _make

async def test_get_user(session, make_user):
    user = make_user(name="Test")
    session.add(user)
    # ...
```

## Mocking Rules
| Mock | Don't Mock |
|------|------------|
| External APIs (Stripe, OpenAI) | Your own code |
| Email/SMS services | Database in integration tests |
| Network requests | Business logic |
| Time (`datetime.now`) | Repository methods |

```python
# Mock external services
@patch("app.services.email.send")
async def test_signup_sends_welcome_email(mock_send, client):
    await client.post("/signup", json=data)
    mock_send.assert_called_once()
```

## E2E Tests (Playwright)
Use stable selectors:
```typescript
// CORRECT: data-testid or role
await page.getByTestId('submit-btn').click();
await page.getByRole('button', { name: 'Submit' }).click();

// WRONG: fragile CSS selectors
await page.locator('.btn-primary').click();
```

Verify persistence:
```typescript
await page.getByLabel('Name').fill('Test');
await page.getByRole('button', { name: 'Save' }).click();
await page.reload();
await expect(page.getByText('Test')).toBeVisible();  // Still there?
```

## Rules
1. ALWAYS follow Arrange-Act-Assert pattern
2. ALWAYS test both success and error cases
3. ALWAYS use factories/fixtures over hard-coded data
4. ALWAYS verify persistence in E2E (create → reload → verify)
5. NEVER mock your own code in unit tests
6. NEVER use fragile CSS selectors in E2E — use `data-testid` or roles
7. NEVER commit with failing tests
8. PREFER `pytest.mark.parametrize` for testing multiple inputs
