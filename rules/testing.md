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

## E2E Interface Capability Matrix

The E2E scope depends on the project's user interfaces (declared in `CLAUDE.md` under `## E2E Configuration`):

| Project Type  | Interfaces Tested     | Tools                 | Playwright Required?       |
| ------------- | --------------------- | --------------------- | -------------------------- |
| **fullstack** | API + UI              | HTTP + Playwright MCP | Yes                        |
| **api**       | API only              | HTTP (curl/httpie)    | No                         |
| **cli**       | CLI only              | Subprocess + stdout   | No                         |
| **hybrid**    | Declared per use case | Mixed                 | Only if UI use cases exist |

**Fullstack ordering:** API-first, UI-second. API failure means contract/state is broken (stop immediately). API pass + UI failure means the presentation layer is broken (different diagnosis).

## ARRANGE vs VERIFY — The "No Cheating" Boundary

E2E tests simulate a real user who has no access to internal systems. This principle applies strictly to the VERIFY phase, not the ARRANGE phase.

**ARRANGE (test setup) — allowed methods:**

| Method                             | Example                                         |
| ---------------------------------- | ----------------------------------------------- |
| Public API endpoints               | `POST /api/v1/users` to create a test account   |
| Public signup/login flows          | Register + authenticate via documented flows    |
| CLI commands                       | `myapp create-account --email test@example.com` |
| UI flows                           | Fill signup form and submit via Playwright      |
| Documented seed/bootstrap commands | `make seed-dev`, `manage.py loaddata`           |

**ARRANGE — forbidden:**

- Direct database queries
- Internal/undocumented endpoints
- Modifying files on disk to inject state
- Reading source code to find shortcuts

**VERIFY (assertions) — no cheating, period:**

- API: check response status, body, headers
- UI: check what's visible on screen (use `data-testid` and roles, not CSS selectors)
- CLI: check stdout/stderr and exit codes
- Persistence: reload/re-request through the same interface

**The principle:** _Setup through any user-accessible interface. Verify through the interface being tested._

## Use Case Lifecycle

```
Phase 3.2b: Design use cases          → plan file (draft)
Phase 5.4:  Execute feature use cases → verify-e2e agent, markdown report
Phase 5.4b: Execute regression suite  → verify-e2e agent, tests/e2e/use-cases/
Phase 6.2b: Graduate passing cases    → tests/e2e/use-cases/[feature].md
```

Use cases live in the plan file during development, then graduate to `tests/e2e/use-cases/` as permanent regression tests after they pass.

**Simple-fix exception** (`/fix-bug` path with 1-2 file fixes that skip Phase 3): use cases are staged at `docs/plans/<bug-name>-use-cases.md` in Phase 5.4 Step 0, then graduated in Phase 6.2b like complex fixes. Staging prevents 5.4b regression mode from picking up unverified use cases.

## Failure Classification

The verify-e2e agent produces a structured markdown report with four classification types:

| Classification | Meaning                                              | Blocks ship?          |
| -------------- | ---------------------------------------------------- | --------------------- |
| **PASS**       | Works as specified                                   | No                    |
| **FAIL_BUG**   | Real product defect — user would hit this            | **Yes**               |
| **FAIL_STALE** | Use case references changed interface — needs update | No (maintenance flag) |
| **FAIL_INFRA** | Server down, timeout, flaky selector                 | Retry once, then warn |

## Rules

1. ALWAYS follow Arrange-Act-Assert pattern
2. ALWAYS test both success and error cases
3. ALWAYS use factories/fixtures over hard-coded data
4. ALWAYS design E2E as user use cases (Intent → Steps → Verification → Persistence)
5. NEVER mock your own code in unit tests
6. NEVER use fragile CSS selectors in E2E — use `data-testid` or roles
7. NEVER commit with failing tests
8. PREFER `pytest.mark.parametrize` for testing multiple inputs
