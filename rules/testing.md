# Testing Rules

## Framework
- Backend: `pytest` with `pytest-asyncio`
- Frontend: `vitest` with `jsdom`

## Test Structure

### Arrange-Act-Assert Pattern
```python
async def test_create_server():
    # Arrange
    server_data = ServerCreate(name="test", url="http://localhost:8000")
    repo = MCPServerRepository(session)
    
    # Act
    result = await repo.create(server_data)
    
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
│   ├── test_api_servers.py
│   └── test_api_search.py
├── e2e/            # Full system tests
│   └── test_generation_flow.py
└── conftest.py     # Shared fixtures
```

### Naming Convention
- Test files: `test_{module}.py`
- Test functions: `test_{method}_{scenario}_{expected}`
- Example: `test_create_server_with_invalid_url_raises_validation_error`

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
def sample_server() -> MCPServer:
    """Provide a sample server for tests."""
    return MCPServer(
        id=uuid4(),
        name="test-server",
        type=ServerType.REMOTE,
        url="http://localhost:8000",
    )
```

## Mocking

### When to Mock
- External APIs (OpenAI, Anthropic)
- File system operations
- Network requests
- Time-dependent operations

### When NOT to Mock
- Database operations in integration tests
- Internal service calls (test the real thing)
- Final validation (e2e tests with real systems)

```python
from unittest.mock import AsyncMock, patch

@patch("services.embeddings.OpenAI")
async def test_generate_embeddings(mock_openai):
    mock_openai.return_value.embeddings.create = AsyncMock(
        return_value={"data": [{"embedding": [0.1] * 1536}]}
    )
    
    service = EmbeddingsService()
    result = await service.embed("test")
    
    assert len(result) == 1536
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
cd src && uv run pytest

# Run with coverage
cd src && uv run pytest --cov=mcpgateway --cov-report=html

# Run specific test file
cd src && uv run pytest tests/unit/test_repositories.py

# Run tests matching pattern
cd src && uv run pytest -k "test_create"

# Run with verbose output
cd src && uv run pytest -v

# Frontend unit tests
cd frontend && pnpm test

# E2E tests (Playwright)
cd frontend && pnpm test:e2e
```

---

## End-to-End Testing (MANDATORY)

> **Every feature MUST have E2E tests before merging to main.**

### E2E Test Priority

1. **Claude Chrome Extension** (first choice)
   - Use browser automation via Claude Chrome extension
   - Navigate actual UI, click buttons, fill forms
   - Verify visual state and data persistence

2. **Playwright MCP Server** (fallback)
   - Use the `playwright` MCP server from Compound Engineering
   - Configured in `.claude/settings.json`
   - Write tests in `frontend/e2e/` or `tests/e2e/`

### E2E Test Structure

```
frontend/
├── e2e/
│   ├── servers.spec.ts        # MCP server management flows
│   ├── tools.spec.ts          # Tool search and execute flows
│   ├── generation.spec.ts     # AI generation flows
│   ├── settings.spec.ts       # Settings configuration flows
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
// frontend/e2e/servers.spec.ts
import { test, expect } from '@playwright/test';

test.describe('MCP Server Management', () => {
  test('should create a new MCP server', async ({ page }) => {
    // Navigate to servers page
    await page.goto('/servers');
    
    // Click "Add Server" button
    await page.click('[data-testid="add-server-btn"]');
    
    // Fill form
    await page.fill('[data-testid="server-name"]', 'Test Server');
    await page.fill('[data-testid="server-url"]', 'http://localhost:8080');
    
    // Submit
    await page.click('[data-testid="save-server-btn"]');
    
    // Verify server appears in list
    await expect(page.locator('[data-testid="server-list"]')).toContainText('Test Server');
    
    // Verify persistence - refresh and check
    await page.reload();
    await expect(page.locator('[data-testid="server-list"]')).toContainText('Test Server');
  });

  test('should show error for invalid URL', async ({ page }) => {
    await page.goto('/servers');
    await page.click('[data-testid="add-server-btn"]');
    await page.fill('[data-testid="server-name"]', 'Test');
    await page.fill('[data-testid="server-url"]', 'not-a-url');
    await page.click('[data-testid="save-server-btn"]');
    
    // Verify error message
    await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
  });
});
```

### E2E Test Example (Chrome Extension)

When using Claude Chrome extension for E2E:

```
1. Navigate to http://localhost:3000/servers
2. Click the "Add Server" button
3. Fill in "Test Server" for name and "http://localhost:8080" for URL
4. Click "Save"
5. Verify "Test Server" appears in the server list
6. Refresh the page
7. Verify "Test Server" still appears (data persisted)
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

## Port Competitor Tests
When adapting competitor features:
1. Find their test files
2. Port test cases to our structure
3. Add additional edge cases

```
Gate22 tests: ../gate22-main/backend/tests/
Obot tests: ../obot-main/pkg/*_test.go
Context Forge tests: ../mcp-context-forge-main/tests/
Lasso tests: ../mcp-gateway-main/tests/
```

## Critical Rules
- **Never merge to main without E2E tests passing**
- **Never delete test files**
- **Never commit with failing tests**
- **Never use mocks in e2e/final validation**
- **Always test error paths, not just happy paths**
- **Always verify data persistence in E2E tests** (create → refresh → verify)
