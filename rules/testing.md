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

| Mock                           | Don't Mock                    |
| ------------------------------ | ----------------------------- |
| External APIs (Stripe, OpenAI) | Your own code                 |
| Email/SMS services             | Database in integration tests |
| Network requests               | Business logic                |
| Time (`datetime.now`)          | Repository methods            |

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
await page.getByTestId("submit-btn").click();
await page.getByRole("button", { name: "Submit" }).click();

// WRONG: fragile CSS selectors
await page.locator(".btn-primary").click();
```

Verify persistence:

```typescript
await page.getByLabel("Name").fill("Test");
await page.getByRole("button", { name: "Save" }).click();
await page.reload();
await expect(page.getByText("Test")).toBeVisible(); // Still there?
```

## E2E Use Case Design

E2E tests are **user use cases** — think like a person using the product, not a developer testing code.

Each use case MUST include:

1. **Intent** — What the user wants to accomplish
   Example: "User creates a new project and invites a teammate"
2. **Steps** — Specific UI interactions as user actions
   Example: Navigate to /projects → Click "New Project" → Fill name → Click "Create"
3. **Verification** — What the user should see after
   Example: Project appears in list, success toast shows
4. **Persistence** — Reload and confirm the action stuck
   Example: Reload /projects → project still visible

### What E2E is NOT

- ❌ Testing a function returns the right value (unit test)
- ❌ Testing an API endpoint returns 200 (integration test)
- ❌ Testing a component renders correctly (component test)
- ❌ Clicking one button and checking one element (too shallow)

### When E2E is required

Any change to **user-facing behavior**: API changes, UI changes, new pages, flow changes, form changes, navigation changes, permission changes — anything a user would notice.

### When E2E can be skipped (N/A)

Purely internal changes with zero user-facing impact: migrations, internal scripts, CI config, dev tooling, behavior-preserving refactors.
Must write justification: `- [x] E2E use cases tested — N/A: [reason]`

## Rules

1. ALWAYS follow Arrange-Act-Assert pattern
2. ALWAYS test both success and error cases
3. ALWAYS use factories/fixtures over hard-coded data
4. ALWAYS design E2E as user use cases (Intent → Steps → Verification → Persistence)
5. NEVER mock your own code in unit tests
6. NEVER use fragile CSS selectors in E2E — use `data-testid` or roles
7. NEVER commit with failing tests
8. PREFER `pytest.mark.parametrize` for testing multiple inputs
