# claude-md-audit

A Claude Code skill that audits `CLAUDE.md` and `MEMORY.md` files for maximum instruction budget efficiency — removing bloat, redundancies, and content the model already knows while preserving everything that matters.

![Claude Code skill](https://img.shields.io/badge/Claude_Code-skill-blue)

## What it does

Scans your instruction files and classifies every section with one of four verdicts:

| Verdict | Meaning |
|---------|---------|
| **KEEP** | Team conventions, compliance rules, internal URLs — Claude can't discover this from code |
| **REMOVE** | Generic best practices the model already knows ("write tests", "use async/await") |
| **TRIM** | Discoverable via `ls` or config files — cut the prose, keep the signal |
| **MOVE_NESTED** | Package-specific content that belongs in a subdirectory `CLAUDE.md` |
| **MOVE_HOOK** | Hard NEVER/ALWAYS rules that should be PreToolUse hooks instead |

Results presented as a table with before/after line counts and budget savings.

## Install

```bash
npx skills add claude-md-audit
```

Or clone manually:

```bash
git clone https://github.com/ccwriter369-beep/claude-skill-claude-md-audit \
  ~/.claude/skills/claude-md-audit
```

## Usage

```
/claude-md-audit
audit my CLAUDE.md
trim the instruction files
my CLAUDE.md feels stale
```

## When to use

- After a Claude model upgrade (built-in knowledge expands)
- When Claude Code seems to ignore instructions (budget pressure)
- When context windows fill too quickly
- Periodically as maintenance (every few months)
- When `CLAUDE.md` has grown past ~100 lines

## How it works

The skill uses a **context-sensitive verdicts** approach:

**High-curation files** (specific URLs, compliance keywords, intentional selection) → bias toward KEEP. Every line was probably deliberate.

**Low-curation files** (generic best practices, template copy-paste, repeated advice) → aggressively TRIM/REMOVE generic content while preserving team-specific knowledge.

**Compliance rule**: If the file mentions HIPAA, PCI, SOC2, or GDPR, seemingly generic patterns (soft-delete, audit logging, data retention) may be compliance-driven — keep them.

## License

MIT
