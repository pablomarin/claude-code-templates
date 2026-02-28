---
paths:
  - "**/*.{ts,tsx}"
---

# TypeScript Style

## Tooling
Use `eslint` (@typescript-eslint/strict), `prettier`. Enable `strict: true` in tsconfig.

## Type Annotations
ALWAYS add explicit return types to functions.

```typescript
function get(id: string): User | null { ... }      // Correct
async function fetch(): Promise<User[]> { ... }    // Correct
function get(id: string) { ... }                   // WRONG: missing return type
```

## Never Use `any`
```typescript
// Use unknown + type guard
function isUser(x: unknown): x is User {
  return typeof x === 'object' && x !== null && 'id' in x;
}

// Use generics for flexible typing
function first<T>(arr: T[]): T | undefined { ... }
```

## Imports
Use type-only imports:
```typescript
import type { User } from '@/types';
import { createUser } from '@/services';
```

## Patterns

**Early returns**:
```typescript
function process(x: Order | null): Result {
  if (!x) return { error: 'missing' };
  if (!x.valid) return { error: 'invalid' };
  return execute(x);
}
```

**Options object for 3+ parameters**:
```typescript
function create(opts: { name: string; email: string; role?: string }): User
```

**Typed errors**:
```typescript
class ValidationError extends Error {
  constructor(message: string, public field: string) { super(message); }
}
```

## Rules
1. ALWAYS enable `strict: true`
2. ALWAYS add explicit return types
3. ALWAYS use type-only imports for types
4. NEVER use `any` — use `unknown` + type guards
5. NEVER use `// @ts-ignore` — fix the type error
6. PREFER early returns over nested conditionals
