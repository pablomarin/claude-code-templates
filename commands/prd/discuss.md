# /prd:discuss {feature-name}

Interactive refinement of user stories before PRD creation. Acts as a skeptical PM who surfaces gaps, ambiguities, and missing requirements.

## Purpose

User stories are often incomplete. This command ensures we understand requirements deeply BEFORE writing a PRD, preventing costly rework downstream.

## Instructions

### Phase 0: Research

**Before analyzing user stories, research the problem space:**
1. Use WebSearch to find industry best practices for this type of feature
2. Use WebFetch to read relevant documentation if specific technologies are mentioned
3. Look for competitor implementations or established patterns

This research informs better questions and identifies requirements the user may not have considered.

### Phase 1: Initial Analysis

1. Read user stories from:
   - User's message (inline)
   - Attached file
   - Existing file at `docs/prds/{feature-name}-stories.md`

2. Create discussion file at `docs/prds/{feature-name}-discussion.md` with header:
   ```markdown
   # PRD Discussion: {Feature Name}
   
   **Status:** In Progress
   **Started:** {date}
   **Participants:** User, Claude
   
   ## Original User Stories
   {paste user's original input}
   
   ## Discussion Log
   ```

### Phase 2: Targeted Questioning

Analyze the stories and ask **5-10 pointed questions** covering:

#### Personas & Access
- Who are ALL the users of this feature? (Don't assume just one persona)
- What permissions/roles are required?
- Are there read-only vs. edit personas?

#### Scope Boundaries
- What's explicitly IN scope for MVP?
- What's explicitly OUT of scope (non-goals)?
- If we could only ship 2 of N stories, which 2?

#### Happy Path Gaps
- What are the specific inputs/outputs?
- What does "success" look like concretely?
- Are there quantitative requirements? ("fast" = how fast?)

#### Error Cases & Edge Cases
- What happens when X fails?
- What if user has no permissions?
- What if data is malformed/missing?
- What are the boundary conditions?

#### Dependencies & Constraints
- Does this require other features to exist first?
- Are there technical constraints (API limits, database schema)?
- Are there business constraints (compliance, legal)?

#### Success Metrics
- How will we know this feature is working?
- What do we measure?
- What's the acceptance threshold?

### Phase 3: Iterative Refinement

1. Wait for user answers
2. Based on answers, ask follow-up questions
3. Update discussion file with Q&A log
4. Continue until user says "ready" or "done" or "let's write the PRD"

### Phase 4: Completion

When user indicates readiness:

1. Update discussion file status to "Complete"
2. Add summary section:
   ```markdown
   ## Refined Understanding
   
   ### Personas
   - {persona 1}: {description}
   
   ### User Stories (Refined)
   - US-001: {refined story}
   
   ### Non-Goals
   - {explicit exclusion}
   
   ### Key Decisions
   - {decision from discussion}
   
   ### Open Questions (Remaining)
   - [ ] {any unresolved questions}
   ```

3. Prompt user to run `/prd:create {feature-name}`

## Question Style Guide

**DO ask:**
- Specific, targeted questions based on the actual stories
- "What happens if..." scenarios
- "Who else might..." persona expansions
- "You mentioned X - does that mean Y or Z?"

**DON'T ask:**
- Generic checklist questions unrelated to the stories
- Too many questions at once (max 10)
- Questions the user clearly already answered
- Leading questions that assume an answer

## Example Interaction

```
User: /prd:discuss mcp-import

Here are my user stories:
- As an admin, I want to import MCP servers from a URL
- As an admin, I want to see import progress

Claude: I've logged these stories to docs/prds/mcp-import-discussion.md.

Before we write a PRD, let me understand these better:

**Personas:**
1. Is "admin" the only role that can import? What about project owners 
   or super-admins?

**Story 1 - Import from URL:**
2. What URL formats should we support?
   - GitHub raw URLs (raw.githubusercontent.com)
   - npm package references (@org/package)
   - Direct JSON/YAML config files
   - OpenAPI/Swagger specs
   
3. What happens if the URL is unreachable or returns 404?

4. What if the URL points to a valid file but invalid MCP config?

5. Should we support authenticated URLs (private GitHub repos)?

**Story 2 - Progress:**
6. Real-time updates (SSE/WebSocket) or polling?

7. What stages should progress show? For example:
   - Fetching → Parsing → Validating → Creating tools → Done

**Scope:**
8. Single URL import only, or should we support bulk (multiple URLs)?

9. Are we importing just the server definition, or also credentials/API keys?

10. Should imported servers auto-start, or require manual activation?
```

## Output

- Creates/updates `docs/prds/{feature-name}-discussion.md`
- Conversation continues until user is ready
- Ends with prompt to run `/prd:create {feature-name}`
