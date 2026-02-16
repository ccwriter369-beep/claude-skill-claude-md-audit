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

Systematically audit instruction files to maximize the instruction budget — the finite number of instructions a model can follow accurately before performance degrades.

## Core Principle

Every line in your root CLAUDE.md is loaded on every single prompt. One bad or wasteful line cascades: bad spec → bad research → bad plan → bad code. The goal is **minimum effective instructions** — only what the model can't figure out on its own.

## Audit Procedure

### Step 1: Inventory

Read all instruction files that load per-prompt:
1. Root `CLAUDE.md` (or `~/.claude/CLAUDE.md` for global)
2. Project-level `CLAUDE.md` files
3. `MEMORY.md` / auto-memory files
4. Any `<claude-mem-context>` blocks injected by plugins

Count total lines. Target: **under 60 lines combined** for always-loaded content.

### Step 2: Classify every section

For each section, assign one verdict:

| Verdict | Criteria | Action |
|---------|----------|--------|
| **KEEP** | User-specific preference the model can't infer. Non-obvious policy. Workflow convention. | Leave in root file |
| **REMOVE** | Best practice the model already knows. Obvious behavior. Generic advice. | Delete entirely |
| **MOVE → nested** | Domain-specific (Python, deployment, nginx). Only relevant when touching those files. | Create nested CLAUDE.md near relevant code |
| **MOVE → hook** | Hard constraint that must never be violated. "Never do X" rules. | Create PreToolUse/PostToolUse hook |
| **TRIM** | Correct info but too verbose. Lists of things that can be discovered by reading files. | Shorten to 1-2 lines max |

### Step 3: Apply the "model already knows" test

Remove anything where the model's built-in behavior is equal or better:
- Debugging methodology ("read the test first", "trace the code path")
- Security basics ("don't expose stack traces", "use encryption")
- Code style ("use const instead of var", "prefer async/await")
- Git workflow ("don't force push to main")
- Testing basics ("put test deps in dev dependencies")
- Language deprecation patterns (the model's training data is more current)

**Key insight**: With each model upgrade, more practices get baked in. After an upgrade, scan for lines that the newer model handles natively.

### Step 4: Convert hard constraints to hooks

Any instruction that says "NEVER do X" or "ALWAYS do Y" is a hook candidate. Hooks are 100% reliable; CLAUDE.md instructions can be forgotten mid-session.

Common conversions:
| Instruction | Hook type | Implementation |
|---|---|---|
| "Never use tool X for project Y" | `PreToolUse` with matcher | Block tool when working directory matches |
| "Never run dangerous command Z" | `PreToolUse` matcher on Bash | Block command pattern |
| "Always run tests before committing" | `PreToolUse` matcher on git commit | Check test status first |
| "Never modify file F" | `PreToolUse` matcher on Edit/Write | Block edits to specific paths |

Hook template:
```javascript
#!/usr/bin/env node
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('/dev/stdin', 'utf8'));
const toolName = input.tool_name || '';

// Check condition
if (shouldBlock(toolName, input)) {
  console.log(JSON.stringify({
    decision: 'block',
    reason: 'Explain why this was blocked and what to do instead.'
  }));
} else {
  console.log(JSON.stringify({ decision: 'approve' }));
}
```

Register in `~/.claude/settings.json` under `hooks.PreToolUse`.

### Step 5: Create nested CLAUDE.md files

Move domain-specific content to nested files near the code it governs:
- Python patterns → `CLAUDE.md` next to `.py` files or in project root
- Deployment rules → `CLAUDE.md` next to Dockerfiles/CI configs
- API conventions → `CLAUDE.md` in the API directory

These load lazily — only when Claude reads files in that directory.

### Step 6: Trim discoverable content

Remove anything Claude can find by reading the codebase:
- File path inventories ("plans are at ~/.claude/plans/")
- Tool lists for plugins ("orchestrator has 21 tools: set_context, get_context...")
- Skill/plugin enumerations ("6 published skills: ...")
- Configuration details discoverable from config files

Replace with a single pointer: "Orchestrator plugin at `~/.claude/plugins/claude-orchestrator/`"

### Step 7: Verify

After trimming:
1. Count lines — root CLAUDE.md should be **under 40 lines**, MEMORY.md **under 30 lines**
2. Validate settings.json is valid JSON
3. Test any new hooks with sample input
4. Verify no critical user preferences were lost

## Output Format

Present findings as a table:

| Section | Lines | Verdict | Reason |
|---------|-------|---------|--------|
| Infrastructure Map | 1-33 | TRIM | Paths are discoverable |
| Debugging CI | 34-42 | REMOVE | Model already knows |
| Python Patterns | 50-61 | MOVE → nested | Only relevant for Python work |
| "Never use X for Y" | 35-39 | MOVE → hook | Hard constraint, must not be forgotten |

Then implement all changes, showing before/after line counts and budget savings.

## When to Run This Audit

- After a model upgrade (remove what's now baked in)
- When CLAUDE.md exceeds 60 lines
- When Claude Code seems to ignore instructions (budget may be exhausted)
- When context windows compress too early in sessions
- Monthly, as general maintenance
