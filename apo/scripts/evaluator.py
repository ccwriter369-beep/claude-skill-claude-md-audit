#!/usr/bin/env python3
"""
APO Evaluator — scores an audit output against the answer key.

Scoring rubric (per section):
  - Verdict match:     +2 points (exact match)
  - Verdict near-miss: +1 point  (e.g., MOVE_HOOK vs MOVE_NESTED are both "move")
  - Verdict wrong:      0 points
  - Bonus: +1 if reason mentions the key concept from the answer

Total score normalized to 0-100.
"""

import json
import sys
import re
from pathlib import Path

# Verdict categories for near-miss scoring
VERDICT_GROUPS = {
    "KEEP": "keep",
    "REMOVE": "remove",
    "TRIM": "trim",
    "MOVE_NESTED": "move",
    "MOVE_HOOK": "move",
}

# Key concepts per case that should appear in reasoning
KEY_CONCEPTS = {
    "case-01-bloated-generic": {
        "Code Style": ["baked-in", "model already knows", "built-in"],
        "Security": ["OWASP", "baked-in", "model already knows"],
        "My Project Structure": ["discoverable", "filesystem", "read"],
        "Python Preferences": ["nested", "only relevant when", "Python files"],
    },
    "case-02-mixed-quality": {
        "Never Modify Legacy API": ["hook", "PCI", "compliance", "block"],
        "Secrets Management": ["team-specific", "AWS", "access pattern"],
        "Testing": ["discoverable", "package.json", "generic"],
    },
    "case-03-already-lean": {
        "Forbidden Actions": ["hook", "guaranteed", "enforcement"],
    },
    "case-04-subtle-traps": {
        "Data Model Conventions": ["HIPAA", "retention", "compliance"],
        "Code Quality": ["generic", "discoverable", "config"],
    },
    "case-05-hook-candidates": {
        "Absolute Rules": ["hook", "PreToolUse", "guaranteed"],
        "DO NOT TOUCH": ["hook", "block", "Edit", "Write"],
    },
}


def normalize_verdict(raw: str) -> str:
    """Normalize an audit verdict to our canonical form."""
    v = raw.upper().strip().replace(" ", "_").replace("→", "").replace("->", "")
    # Map common variations
    mappings = {
        "MOVE": "MOVE_NESTED",
        "MOVE_TO_NESTED": "MOVE_NESTED",
        "MOVE_TO_HOOK": "MOVE_HOOK",
        "HOOK": "MOVE_HOOK",
        "DELETE": "REMOVE",
        "DROP": "REMOVE",
    }
    return mappings.get(v, v)


def score_verdict(actual: str, expected: str) -> int:
    """Score a single verdict: 2=exact, 1=near-miss, 0=wrong."""
    a = normalize_verdict(actual)
    e = normalize_verdict(expected)
    if a == e:
        return 2
    if VERDICT_GROUPS.get(a) == VERDICT_GROUPS.get(e):
        return 1
    return 0


def score_reasoning(reason: str, case_id: str, section_name: str) -> int:
    """Bonus point if reasoning mentions key concepts."""
    concepts = KEY_CONCEPTS.get(case_id, {}).get(section_name, [])
    if not concepts:
        return 0
    reason_lower = reason.lower()
    return 1 if any(c.lower() in reason_lower for c in concepts) else 0


def parse_audit_output(text: str) -> list[dict]:
    """
    Parse a markdown table from audit output.
    Expected format: | Section | Lines | Verdict | Reason |
    """
    sections = []
    # Find table rows (lines starting with |)
    for line in text.split("\n"):
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.split("|")[1:-1]]
        if len(cells) < 3:
            continue
        # Skip header and separator rows
        if cells[0] in ("Section", "---", "") or cells[0].startswith("-"):
            continue
        if all(c.startswith("-") or c == "" for c in cells):
            continue

        section = {
            "name": cells[0],
            "verdict": cells[2] if len(cells) >= 3 else "",
            "reason": cells[3] if len(cells) >= 4 else "",
        }
        sections.append(section)
    return sections


def evaluate(audit_output: str, answer_path: str) -> dict:
    """Score an audit output against an answer key."""
    answer = json.loads(Path(answer_path).read_text())
    case_id = answer["case_id"]
    expected = {s["name"]: s for s in answer["sections"]}
    actual = parse_audit_output(audit_output)

    results = []
    total_possible = len(expected) * 3  # 2 for verdict + 1 for reasoning per section

    for exp_name, exp_data in expected.items():
        # Find matching section in actual output (fuzzy match)
        matched = None
        for a in actual:
            if exp_name.lower() in a["name"].lower() or a["name"].lower() in exp_name.lower():
                matched = a
                break

        if matched is None:
            results.append({
                "section": exp_name,
                "expected": exp_data["verdict"],
                "actual": "MISSING",
                "verdict_score": 0,
                "reasoning_score": 0,
            })
            continue

        v_score = score_verdict(matched["verdict"], exp_data["verdict"])
        r_score = score_reasoning(matched.get("reason", ""), case_id, exp_name)

        results.append({
            "section": exp_name,
            "expected": exp_data["verdict"],
            "actual": normalize_verdict(matched["verdict"]),
            "verdict_score": v_score,
            "reasoning_score": r_score,
        })

    total_score = sum(r["verdict_score"] + r["reasoning_score"] for r in results)
    normalized = round((total_score / total_possible) * 100, 1) if total_possible > 0 else 0

    return {
        "case_id": case_id,
        "score": normalized,
        "total_points": total_score,
        "max_points": total_possible,
        "sections": results,
    }


def main():
    if len(sys.argv) < 3:
        print("Usage: evaluator.py <audit-output-file> <answer-key-file>")
        print("  audit-output-file: text file with the markdown table from the audit")
        print("  answer-key-file:   JSON answer key")
        sys.exit(1)

    audit_text = Path(sys.argv[1]).read_text()
    result = evaluate(audit_text, sys.argv[2])

    print(json.dumps(result, indent=2))

    # Summary
    print(f"\n{'='*50}")
    print(f"Case: {result['case_id']}")
    print(f"Score: {result['score']}/100 ({result['total_points']}/{result['max_points']} points)")
    print(f"{'='*50}")
    for s in result["sections"]:
        match = "exact" if s["verdict_score"] == 2 else "near" if s["verdict_score"] == 1 else "MISS"
        bonus = "+reason" if s["reasoning_score"] else ""
        print(f"  {s['section']:30s} {s['expected']:15s} -> {s['actual']:15s} [{match}{bonus}]")


if __name__ == "__main__":
    main()
