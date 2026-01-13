# Database

## Naming
- Tables: plural snake_case (`users`, `order_items`)
- Foreign keys: `{singular}_id` (`user_id`)
- Timestamps: always add `created_at`, `updated_at`

## Model Pattern (SQLAlchemy 2.0)
```python
class User(Base):
    __tablename__ = "users"
    
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(server_default=func.now(), onupdate=func.now())
    
    # Relationship with eager loading default
    orders: Mapped[list["Order"]] = relationship(back_populates="user", lazy="selectin")

class Order(Base):
    __tablename__ = "orders"
    
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)  # ALWAYS index FKs
```

## Prevent N+1 Queries
```python
# WRONG: triggers N queries
users = (await session.execute(select(User))).scalars().all()
for u in users: print(u.orders)  # Each access = 1 query

# CORRECT: eager load
from sqlalchemy.orm import selectinload
users = await session.execute(select(User).options(selectinload(User.orders)))
```

## Use Database Aggregations
```python
# WRONG: loads all rows into memory
count = len((await session.execute(select(User))).scalars().all())

# CORRECT: database count
count = (await session.execute(select(func.count()).select_from(User))).scalar_one()
```

## Transactions
```python
async with session.begin():
    # All operations here are atomic
    session.add(order)
    session.add(payment)
    # Auto-commits on exit, auto-rollbacks on exception
```

## Rules
1. ALWAYS add `created_at` and `updated_at` columns
2. ALWAYS index foreign key columns
3. ALWAYS use eager loading (`selectinload`/`joinedload`) to prevent N+1
4. ALWAYS use parameterized queries (ORMs do this automatically)
5. NEVER use `len()` on query results — use `func.count()`
6. NEVER build SQL with string concatenation
7. PREFER UUID primary keys for distributed systems
8. PREFER storing money as integers (cents)
