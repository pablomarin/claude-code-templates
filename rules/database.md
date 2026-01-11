# Database Rules

## Stack
- PostgreSQL 15+ (recommended)
- SQLAlchemy 2.0 async (asyncpg driver)
- Alembic for migrations
- Optional: pgvector for vector similarity search

## Naming Conventions

### Tables
- Plural snake_case: `users`, `orders`, `order_items`

### Columns
- Singular snake_case: `user_id`, `created_at`, `is_active`
- Timestamps: `created_at`, `updated_at` (always include both)
- Foreign keys: `{referenced_table_singular}_id` (e.g., `user_id`, `order_id`)
- Booleans: prefix with `is_` or `has_` (e.g., `is_enabled`, `has_verified`)

### Indexes
- Format: `idx_{table}_{column(s)}`
- Example: `idx_users_email`, `idx_orders_user_id_created_at`

### Foreign Keys
- Format: `fk_{table}_{referenced_table}`
- Example: `fk_orders_users`

### Constraints
- Primary key: `pk_{table}`
- Unique: `uq_{table}_{column(s)}`
- Check: `ck_{table}_{description}`

## Model Pattern (SQLAlchemy 2.0)

```python
from datetime import datetime
from uuid import UUID, uuid4
from sqlalchemy import String, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column, DeclarativeBase

class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
```

## Migrations (Alembic)

### Best Practices
- One migration per logical change
- Always include `upgrade()` and `downgrade()`
- Test downgrade path before committing
- Name format: `{revision}_{description}.py`

```python
def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.UUID(), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("idx_users_email", "users", ["email"])

def downgrade() -> None:
    op.drop_index("idx_users_email")
    op.drop_table("users")
```

### Commands
```bash
# Create migration
alembic revision --autogenerate -m "add users table"

# Run migrations
alembic upgrade head

# Rollback one
alembic downgrade -1

# Show current
alembic current
```

## Repository Pattern

```python
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

class UserRepository:
    def __init__(self, session: AsyncSession):
        self.session = session
    
    async def get_by_id(self, id: UUID) -> User | None:
        result = await self.session.execute(
            select(User).where(User.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_email(self, email: str) -> User | None:
        result = await self.session.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    async def create(self, user: User) -> User:
        self.session.add(user)
        await self.session.flush()
        return user
    
    async def list(self, skip: int = 0, limit: int = 20) -> list[User]:
        result = await self.session.execute(
            select(User).offset(skip).limit(limit)
        )
        return list(result.scalars().all())
```

## Query Optimization
- Use `select()` with specific columns when full entity not needed
- Use `joinedload()` for eager loading relationships
- Avoid N+1 queries — batch fetch related entities
- Use `func.count()` subqueries instead of `len()` on collections

```python
# Good - eager load relationships
from sqlalchemy.orm import joinedload

result = await session.execute(
    select(Order)
    .options(joinedload(Order.items))
    .where(Order.user_id == user_id)
)

# Good - count without loading all
from sqlalchemy import func

result = await session.execute(
    select(func.count()).select_from(Order).where(Order.user_id == user_id)
)
count = result.scalar()
```

## Transactions
- Use `async with session.begin():` for explicit transactions
- Keep transactions short — don't hold locks during external I/O
- Use `session.flush()` to get IDs without committing

```python
async with session.begin():
    user = User(email="test@example.com", name="Test")
    session.add(user)
    await session.flush()  # user.id is now available
    
    profile = Profile(user_id=user.id, bio="Hello")
    session.add(profile)
    # Commits on exit
```

## pgvector (Optional)

For vector similarity search:

```python
from pgvector.sqlalchemy import Vector

class Document(Base):
    __tablename__ = "documents"
    
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    content: Mapped[str] = mapped_column()
    embedding: Mapped[list[float] | None] = mapped_column(Vector(1536))

# Similarity search
from sqlalchemy import select

result = await session.execute(
    select(Document)
    .order_by(Document.embedding.cosine_distance(query_embedding))
    .limit(10)
)
```

## Critical Rules
- **Never use raw SQL with string interpolation** — always use parameterized queries
- **Always include created_at/updated_at** on entities
- **Test migrations up AND down** before committing
- **Index foreign keys** and frequently queried columns
- **Use UUID for primary keys** in distributed systems
