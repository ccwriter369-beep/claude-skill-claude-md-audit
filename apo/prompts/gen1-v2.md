---
name: claude-md-audit
description: |
  Audit and trim CLAUDE.md and MEMORY.md files for maximum instruction budget efficiency.
  Identifies bloat, baked-in knowledge the model already has, content that should be nested
  CLAUDE.md files, and hard constraints that should be hooks instead.

  Use when: CLAUDE.md files feel stale, after model upgrades, when Claude Code seems to
  ignore instructions, when context windows fill too quickly, or periodically as maintenance.
---

# CLAUDE.md Audit Skill

Systematically audit instruction files to maximize the instruction budget.

## Classification Rules

### KEEP — Root-Level Project Instructions

Root CLAUDE.md should contain **strategic context that cannot be discovered by reading code**:

1. **Team Conventions & Cultural Knowledge**
   - Code review standards, approval workflows
   - Naming conventions specific to this team (not industry-standard)
   - Internal service names, URLs, API endpoints (if NOT in config files)

2. **Compliance-Driven Rules**
   - **CRITICAL**: If the file mentions HIPAA, PCI, SOC2, GDPR, re-evaluate ALL rules
   - Seemingly generic patterns (soft-delete, audit logging, data retention) are often compliance-driven
   - If a rule exists BECAUSE of compliance → MUST be KEEP

3. **External Integration Context**
   - Third-party API endpoints, rate limits, authentication flows
   - Webhook endpoints, partner service URLs

4. **Non-Obvious Architectural Constraints**
   - Cross-service communication patterns with specific URLs/ports
   - Architecture patterns used across microservices

5. **Monorepo Structure & Organization**
   - Which packages own which domains
   - Where to add new features (package selection guide)

### REMOVE — Model Already Knows

Delete entirely if model's built-in behavior covers it:
- Debugging methodology, security basics, code style
- Git workflow, testing basics, language patterns
- Generic REST/API design conventions

### TRIM — Strictly Discoverable Information

Only TRIM if the content passes the **Discoverability Litmus Test**:

**Ask: "Could the model find the EXACT information (URLs, names, values) by reading standard config files or code?"**

- SAFE to trim: "Run npm test" (in package.json), "We use ESLint" (.eslintrc exists)
- UNSAFE to trim (KEEP instead): Internal URLs, team conventions, compliance-driven rules, organizational knowledge

**Red Flags for Over-Trimming:**
- Content references internal URLs/domains not in config files
- Content describes team processes or human workflows
- Content explains "why" (rationale, history, trade-offs)
- Content contains compliance keywords (HIPAA, PCI, audit, retention)

### MOVE_NESTED — Package-Specific Content

**WARNING: DO NOT OVER-NEST**
- If content helps someone decide WHICH package to work in → KEEP in root
- If content describes how ALL packages should work → KEEP in root
- Only move if it's ONLY relevant when already inside that package's directory

Move only if ALL of these apply:
1. Content is technical implementation detail for ONE package
2. Reader is already working inside that package
3. Does NOT help with cross-package navigation or package selection
4. No URLs or credentials
5. Not compliance-driven

### MOVE_HOOK — Hard Constraints and File Protection

Any instruction that says "NEVER do X", "ALWAYS do Y", or "DO NOT TOUCH":
- Hard NEVER/ALWAYS rules → PreToolUse hooks
- Auto-generated file paths → PreToolUse block on Edit/Write
- File protection rules → PreToolUse block on specific paths

## Compliance Context Propagation Rule

If CLAUDE.md mentions compliance frameworks (HIPAA, PCI, SOC2, GDPR):
1. Re-evaluate ALL data handling rules — they may LOOK generic but are compliance-driven
2. If a rule exists BECAUSE of compliance → KEEP (not TRIM, not MOVE)
3. If unsure whether compliance-driven → err on side of KEEP

## Edge Cases

1. **KEEP vs TRIM doubt** → KEEP (better to keep team knowledge than lose it)
2. **KEEP vs MOVE_NESTED doubt** → KEEP (over-nesting fragments knowledge)
3. **Compliance-adjacent content** → if it COULD be compliance-driven → KEEP

## Output Format

Present findings as a table:

| Section | Lines | Verdict | Reason |
|---------|-------|---------|--------|
| ... | ... | KEEP/REMOVE/TRIM/MOVE_NESTED/MOVE_HOOK | Brief reason |

Then implement all changes, showing before/after line counts and budget savings.
