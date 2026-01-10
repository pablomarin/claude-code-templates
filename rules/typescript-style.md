# TypeScript Style Rules

## General
- TypeScript strict mode enabled
- ESLint + Prettier for formatting
- 2 spaces for indentation
- Line length: 100 characters (Prettier default)

## Naming Conventions
- `camelCase` for variables and functions
- `PascalCase` for classes, interfaces, types, and React components
- `UPPER_CASE` for constants
- `I` prefix NOT used for interfaces (use descriptive names)
- Private: prefix with `_` or use `#` for true private

## Type Annotations (Mandatory)
- All function parameters and return types must be typed
- Avoid `any` - use `unknown` if type is truly unknown
- Use `T | null` for nullable types (not `T | undefined` unless intentional)
- Prefer interfaces for object shapes, types for unions/intersections

```typescript
// Good
function getUser(userId: string): User | null {
  ...
}

// Bad
function getUser(userId) {
  ...
}
```

## Import Order
Organize imports in this order, separated by blank lines:
1. React/framework imports
2. Third-party packages
3. Absolute imports (from `@/`)
4. Relative imports

Let ESLint auto-sort via import rules.

## React Conventions

### Component Structure
```typescript
// 1. Imports
import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';

// 2. Types
interface Props {
  title: string;
  onSubmit: (data: FormData) => void;
}

// 3. Component
export function MyComponent({ title, onSubmit }: Props) {
  // 3a. Hooks first
  const [state, setState] = useState<string>('');
  
  // 3b. Derived values
  const isValid = state.length > 0;
  
  // 3c. Effects
  useEffect(() => {
    // ...
  }, []);
  
  // 3d. Handlers
  const handleClick = () => {
    // ...
  };
  
  // 3e. Render
  return (
    <div>
      <h1>{title}</h1>
      <Button onClick={handleClick}>Submit</Button>
    </div>
  );
}
```

### Hooks
- Custom hooks start with `use` prefix
- Extract complex logic to custom hooks
- Use `useCallback` for functions passed to children
- Use `useMemo` for expensive computations

### Props
- Destructure props in function signature
- Use default values for optional props
- Document complex props with JSDoc comments

## Functions
- Single responsibility — one function, one job
- ≤5 parameters — use options object for more
- Return early to reduce nesting
- Use `async/await` over `.then()` chains

```typescript
// Good - early return
async function fetchUser(id: string): Promise<User | null> {
  if (!id) return null;
  
  const response = await api.get(`/users/${id}`);
  if (!response.ok) return null;
  
  return response.data;
}

// Bad - nested
async function fetchUser(id: string): Promise<User | null> {
  if (id) {
    const response = await api.get(`/users/${id}`);
    if (response.ok) {
      return response.data;
    }
  }
  return null;
}
```

## Error Handling
- Use typed error classes
- Catch specific errors, not generic `Error`
- Always handle promise rejections
- Use Result types for expected failures

```typescript
// Good
try {
  await saveUser(user);
} catch (error) {
  if (error instanceof ValidationError) {
    showToast(error.message);
  } else if (error instanceof NetworkError) {
    showToast('Network error. Please try again.');
  } else {
    throw error; // Unexpected error, rethrow
  }
}
```

## Comments
- Use JSDoc for public APIs
- Add explanatory comments for complex logic
- Keep comments up-to-date with code
- Delete commented-out code — don't commit it

```typescript
/**
 * Calculates the total price including tax.
 * @param items - List of items with prices
 * @param taxRate - Tax rate as decimal (e.g., 0.08 for 8%)
 * @returns Total price including tax
 */
function calculateTotal(items: Item[], taxRate: number): number {
  // ...
}
```

## File Organization
```
src/
├── components/        # React components
│   ├── ui/           # Reusable UI components
│   └── features/     # Feature-specific components
├── hooks/            # Custom hooks
├── lib/              # Utility functions
├── types/            # TypeScript types
├── services/         # API services
└── app/              # Next.js app router
```

## Testing
- Test file next to source: `Component.tsx` → `Component.test.tsx`
- Use `describe` blocks to group related tests
- Test behavior, not implementation
- Mock external dependencies, not internal logic
