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

6. **Tooling Decisions with Team-Specific Context**
   - When a section references a config file by path AND explains a team decision about its usage
   - Example: "We use Tailwind CSS with custom theme in tailwind.config.ts. Design tokens in packages/ui/tokens/" (KEEP — shows team decision about token location)
   - Example: "Database: PostgreSQL 15" (KEEP as one line — version choice is team-specific)

### REMOVE — Model Already Knows

Delete entirely if model's built-in behavior covers it:
- Debugging methodology, security basics, code style
- Git workflow, testing basics, language patterns
- Generic REST/API design conventions

**Critical Exceptions:**
- Do NOT remove content that looks generic but contains team-specific choices (e.g., "Python: use black and ruff" is domain-specific tooling choice → MOVE_NESTED, not REMOVE)
- Do NOT remove "Project Structure" sections in bloated files with no team context → TRIM instead (filesystem is discoverable)

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

**MIXED SECTIONS RULE (NEW):**

When a section contains BOTH generic advice AND team-specific details:
- **Verdict: TRIM** (NOT KEEP or REMOVE)
- Keep only the specific parts (version numbers, file paths, team decisions)
- Remove generic "how to use it" advice that the model already knows
- Examples:
  - "Monitoring: Use structured logging. We use DataDog dashboard at https://app.datadoghq.com/our-team" → TRIM (keep URL, remove generic logging advice)
  - "Error Handling: Always catch errors. Critical errors go to #alerts Slack channel" → TRIM (keep Slack channel, remove generic error handling advice)
  - "Database: Use migrations. PostgreSQL 15" → TRIM to just "PostgreSQL 15"

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

**Domain-Specific Tooling:**
- Language-specific tooling choices (e.g., "Python: use black and ruff") are domain-specific, not generic
- If the project has Python code → MOVE_NESTED to packages/python/CLAUDE.md
- If the project has deployment conventions → MOVE_NESTED to deployment/CLAUDE.md (not REMOVE — they're team-specific)

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
4. **Tooling with version numbers** → KEEP the version as one line (e.g., "PostgreSQL 15" is a team decision)
5. **Sections in lean files** → Be conservative; if a lean file has specific file paths or team decisions, KEEP them

## Output Format

Present findings as a table:

| Section | Lines | Verdict | Reason |
|---------|-------|---------|--------|
| ... | ... | KEEP/REMOVE/TRIM/MOVE_NESTED/MOVE_HOOK | Brief reason |

Then implement all changes, showing before/after line counts and budget savings.
