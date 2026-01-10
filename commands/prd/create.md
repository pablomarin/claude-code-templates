# /prd:create {feature-name}

Generate a structured PRD from the refined understanding captured in `/prd:discuss`.

## Prerequisites

- Discussion file exists at `docs/prds/{feature-name}-discussion.md`
- Discussion status is "Complete" (user said "ready")
- If no discussion file exists, prompt user to run `/prd:discuss` first

## Instructions

### Step 1: Load Context

1. Read `docs/prds/{feature-name}-discussion.md`
2. Extract:
   - Refined user stories
   - Personas identified
   - Non-goals agreed
   - Key decisions made
   - Technical constraints
   - Success metrics

### Step 2: Generate PRD

Create `docs/prds/{feature-name}.md` using the template below.

### Step 3: Review Prompt

After creating PRD:
1. Summarize what was created (section count, story count)
2. Ask user to review
3. Offer to make adjustments
4. When approved, prompt to start technical design with `/superpowers:brainstorm`

## PRD Template

```markdown
# PRD: {Feature Name}

**Version:** 1.0
**Status:** Draft
**Author:** Claude + {User}
**Created:** {date}
**Last Updated:** {date}

---

## 1. Overview

{2-3 sentence summary of what we're building and why. Should answer: What problem does this solve? Who benefits? What's the high-level approach?}

## 2. Goals & Success Metrics

### Goals
- {Primary goal}
- {Secondary goal}

### Success Metrics
| Metric | Target | How Measured |
|--------|--------|--------------|
| {metric} | {target} | {measurement method} |

### Non-Goals (Explicitly Out of Scope)
- ❌ {What we're NOT building}
- ❌ {What's deferred to future phases}

## 3. User Personas

### {Persona 1 Name}
- **Role:** {role description}
- **Permissions:** {what they can do}
- **Goals:** {what they want to achieve}

### {Persona 2 Name}
- **Role:** {role description}
- **Permissions:** {what they can do}
- **Goals:** {what they want to achieve}

## 4. User Stories

### US-001: {Story Title}

**As a** {persona}
**I want** {capability}
**So that** {benefit}

**Scenario:**
```gherkin
Given {precondition}
When {action}
Then {expected result}
And {additional result}
```

**Acceptance Criteria:**
- [ ] {criterion 1 - specific and testable}
- [ ] {criterion 2 - specific and testable}
- [ ] {criterion 3 - specific and testable}

**Edge Cases:**
| Condition | Expected Behavior |
|-----------|-------------------|
| {edge case 1} | {behavior} |
| {edge case 2} | {behavior} |

**Priority:** {Must Have / Should Have / Nice to Have}

---

### US-002: {Story Title}
{Repeat structure for each story}

---

## 5. Technical Constraints

### Known Limitations
- {constraint 1}
- {constraint 2}

### Dependencies
- **Requires:** {feature/system that must exist first}
- **Blocked by:** {any blockers}

### Integration Points
- {External system 1}: {how we integrate}
- {External system 2}: {how we integrate}

## 6. Data Requirements

### New Data Models
- {Model name}: {brief description}

### Data Validation Rules
- {Field}: {validation rule}

### Data Migration
- {Any migration needed from existing data}

## 7. Security Considerations

- **Authentication:** {requirements}
- **Authorization:** {who can do what}
- **Data Protection:** {sensitive data handling}
- **Audit:** {what needs to be logged}

## 8. Open Questions

> Questions that need answers before or during implementation

- [ ] {Question 1}
- [ ] {Question 2}

## 9. References

- **Discussion Log:** `docs/prds/{feature-name}-discussion.md`
- **Related PRDs:** {links to related PRDs}
- **Competitor Reference:** {if synthesizing from competitors}

---

## Appendix A: Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | {date} | Claude + User | Initial PRD |

## Appendix B: Approval

- [ ] Product Owner approval
- [ ] Technical Lead approval
- [ ] Ready for technical design
```

## Validation Checklist

Before finalizing, verify PRD has:

- [ ] Clear overview (someone can understand in 30 seconds)
- [ ] At least 1 user story with Gherkin scenario
- [ ] Acceptance criteria for EVERY story (specific, testable)
- [ ] Edge cases documented
- [ ] Explicit non-goals
- [ ] Success metrics with targets
- [ ] Technical constraints listed
- [ ] Security considerations addressed
- [ ] No TBD or placeholder text

## Output

- Creates `docs/prds/{feature-name}.md`
- PRD is ready for technical design phase
- Prompt user to proceed with `/superpowers:brainstorm` when approved

## Error Handling

**If no discussion file exists:**
```
No discussion file found for "{feature-name}".

Before creating a PRD, we should refine the user stories together.
Run: /prd:discuss {feature-name}

Then provide your user stories, and I'll help identify gaps before we write the PRD.
```

**If discussion is incomplete:**
```
The discussion for "{feature-name}" appears incomplete (status: In Progress).

Would you like to:
1. Continue the discussion (recommended)
2. Create PRD anyway with current understanding

Reply with your choice.
```
