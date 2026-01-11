# Testing Rules

## Framework
- Backend: `pytest` with `pytest-asyncio`
- Frontend: `vitest` with `jsdom`
- E2E: Playwright

## Test Structure

### Arrange-Act-Assert Pattern
```python
async def test_create_user():
    # Arrange
    user_data = UserCreate(name="test", email="test@example.com")
    repo = UserRepository(session)
    
    # Act
    result = await repo.create(user_data)
    
    # Assert
    assert result.id is not None
    assert result.name == "test"
```

### File Organization
```
tests/
├── unit/           # Isolated unit tests
│   ├── test_models.py
│   ├── test_repositories.py
│   └── test_services.py
├── integration/    # Tests with real DB
│   ├── test_api_users.py
│   └── test_api_resources.py
├── e2e/            # Full system tests
│   └── test_user_flows.py
└── conftest.py     # Shared fixtures
```

### Naming Convention
- Test files: `test_{module}.py`
- Test functions: `test_{method}_{scenario}_{expected}`
- Example: `test_create_user_with_invalid_email_raises_validation_error`

## Fixtures (conftest.py)

```python
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

@pytest.fixture
async def session() -> AsyncGenerator[AsyncSession, None]:
    """Provide a clean database session for each test."""
    async with async_session() as session:
        yield session
        await session.rollback()

@pytest.fixture
def sample_user() -> User:
    """Provide a sample user for tests."""
    return User(
        id=uuid4(),
        name="test-user",
        email="test@example.com",
    )
```

## Mocking

### When to Mock
- External APIs (OpenAI, Stripe, etc.)
- File system operations
- Network requests
- Time-dependent operations

### When NOT to Mock
- Database operations in integration tests
- Internal service calls (test the real thing)
- Final validation (e2e tests with real systems)

```python
from unittest.mock import AsyncMock, patch

@patch("services.email.EmailClient")
async def test_send_notification(mock_email):
    mock_email.return_value.send = AsyncMock(return_value=True)
    
    service = NotificationService()
    result = await service.notify("test@example.com", "Hello")
    
    assert result is True
    mock_email.return_value.send.assert_called_once()
```

## TDD Workflow (Mandatory)

1. **Write test first** - Define expected behavior
2. **Run test** - Confirm it fails
3. **Implement** - Write minimal code to pass
4. **Refactor** - Clean up while tests pass
5. **Commit** - Tests must pass before commit

## Test Commands

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/unit/test_repositories.py

# Run tests matching pattern
pytest -k "test_create"

# Run with verbose output
pytest -v

# Frontend unit tests
cd frontend && pnpm test

# E2E tests (Playwright)
cd frontend && pnpm test:e2e
```

---

## End-to-End Testing (MANDATORY)

> **Every feature MUST have E2E tests before merging to main.**

### E2E Test Structure

```
frontend/
├── e2e/
│   ├── auth.spec.ts           # Authentication flows
│   ├── dashboard.spec.ts      # Dashboard features
│   ├── settings.spec.ts       # Settings configuration
│   └── fixtures/
│       └── test-data.json     # Shared test data
```

### What E2E Tests Must Cover

For EACH feature, E2E tests must verify:

- [ ] **Happy path** - Complete user flow works
- [ ] **Error handling** - Error messages display correctly
- [ ] **Data persistence** - Create → refresh → data still there
- [ ] **UI state** - Loading states, disabled buttons, etc.
- [ ] **Cross-component** - Data flows between UI components

### E2E Test Example (Playwright)

```typescript
// frontend/e2e/users.spec.ts
import { test, expect } from '@playwright/test';

test.describe('User Management', () => {
  test('should create a new user', async ({ page }) => {
    // Navigate to users page
    await page.goto('/users');
    
    // Click "Add User" button
    await page.click('[data-testid="add-user-btn"]');
    
    // Fill form
    await page.fill('[data-testid="user-name"]', 'Test User');
    await page.fill('[data-testid="user-email"]', 'test@example.com');
    
    // Submit
    await page.click('[data-testid="save-user-btn"]');
    
    // Verify user appears in list
    await expect(page.locator('[data-testid="user-list"]')).toContainText('Test User');
    
    // Verify persistence - refresh and check
    await page.reload();
    await expect(page.locator('[data-testid="user-list"]')).toContainText('Test User');
  });

  test('should show error for invalid email', async ({ page }) => {
    await page.goto('/users');
    await page.click('[data-testid="add-user-btn"]');
    await page.fill('[data-testid="user-name"]', 'Test');
    await page.fill('[data-testid="user-email"]', 'not-an-email');
    await page.click('[data-testid="save-user-btn"]');
    
    // Verify error message
    await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
  });
});
```

### Playwright Configuration

```typescript
// frontend/playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'pnpm dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

### When to Write E2E Tests

| Scenario | E2E Required? |
|----------|---------------|
| New feature with UI | **Yes** |
| Bug fix affecting UI | **Yes** |
| API-only change | No (integration test sufficient) |
| Refactor with no behavior change | No (existing tests cover) |
| Security-sensitive feature | **Yes** (test auth flows) |

---

## Coverage Requirements
- Minimum: 80% line coverage
- Critical paths (auth, payments, security): 95%+
- New code: Must include tests

## Critical Rules
- **Never merge to main without tests passing**
- **Never delete test files**
- **Never commit with failing tests**
- **Never use mocks in e2e/final validation**
- **Always test error paths, not just happy paths**
- **Always verify data persistence in E2E tests** (create → refresh → verify)
