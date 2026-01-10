# Database Rules

## Stack
- PostgreSQL 15+
- pgvector for vector similarity search
- SQLAlchemy 2.0 async (asyncpg driver)
- Alembic for migrations

## Naming Conventions

### Tables
- Plural snake_case: `mcp_servers`, `agent_skills`, `tool_call_logs`

### Columns
- Singular snake_case: `server_id`, `created_at`, `is_active`
- Timestamps: `created_at`, `updated_at` (always include both)
- Foreign keys: `{referenced_table}_id` (e.g., `server_id`)
- Booleans: prefix with `is_` or `has_` (e.g., `is_enabled`, `has_config`)

### Indexes
- Format: `idx_{table}_{column(s)}`
- Example: `idx_mcp_servers_name`, `idx_tool_call_logs_server_id_created_at`

### Foreign Keys
- Format: `fk_{table}_{referenced_table}`
- Example: `fk_mcp_tools_mcp_servers`

### Constraints
- Primary key: `pk_{table}`
- Unique: `uq_{table}_{column(s)}`
- Check: `ck_{table}_{description}`

## pgvector Usage
- Embedding column: `Vector(1536)` for OpenAI text-embedding-3-small
- Index: HNSW for approximate nearest neighbor search
- Similarity: Cosine distance (`<=>` operator)

```python
from pgvector.sqlalchemy import Vector

class MCPTool(Base):
    embedding: Mapped[list[float] | None] = mapped_column(Vector(1536))
```

## Migrations (Alembic)
- One migration per logical change
- Always include `upgrade()` and `downgrade()`
- Test downgrade path before committing
- Name format: `{revision}_{description}.py`

```python
def upgrade() -> None:
    op.create_table(
        "mcp_servers",
        sa.Column("id", sa.UUID(), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

def downgrade() -> None:
    op.drop_table("mcp_servers")
```

## Async Patterns
```python
# Repository pattern
async def get_by_id(self, id: UUID) -> MCPServer | None:
    result = await self.session.execute(
        select(MCPServer).where(MCPServer.id == id)
    )
    return result.scalar_one_or_none()

# Bulk operations
async def create_many(self, items: list[MCPServer]) -> list[MCPServer]:
    self.session.add_all(items)
    await self.session.flush()
    return items
```

## Query Optimization
- Use `select()` with specific columns when full entity not needed
- Use `joinedload()` for eager loading relationships
- Avoid N+1 queries — batch fetch related entities
- Use `func.count()` subqueries instead of len() on collections

## Transactions
- Use `async with session.begin():` for explicit transactions
- Keep transactions short — don't hold locks during I/O
- Use `session.flush()` to get IDs without committing

## Reference
- Study Gate22's vector embedding strategy: `../gate22-main/backend/aci/`
- Study Obot's registry models: `../obot-main/pkg/models/`
