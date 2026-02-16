#!/usr/bin/env bash
#
# APO Runner — Automatic Prompt Optimization for claude-md-audit
#
# Implements the evolutionary loop:
#   1. Run current prompt variant against all test cases
#   2. Score with evaluator
#   3. Feed scores + failures to Claude to propose improved prompt
#   4. Repeat for N generations
#
# Usage: ./apo-runner.sh [generations] [variants-per-gen]
# Default: 3 generations, 2 variants each

set -euo pipefail

APO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$APO_DIR/scripts"
CASES_DIR="$APO_DIR/test-cases"
PROMPTS_DIR="$APO_DIR/prompts"
RESULTS_DIR="$APO_DIR/results"

GENERATIONS=${1:-3}
VARIANTS=${2:-2}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$RESULTS_DIR/run-$TIMESTAMP"

mkdir -p "$RUN_DIR"

echo "================================================================"
echo "  APO Runner — claude-md-audit optimization"
echo "  Generations: $GENERATIONS | Variants per gen: $VARIANTS"
echo "  Run directory: $RUN_DIR"
echo "================================================================"

# ─── Seed prompt (generation 0) ──────────────────────────────────────
SEED_PROMPT="$PROMPTS_DIR/gen-0-seed.md"
if [[ ! -f "$SEED_PROMPT" ]]; then
    echo "[Gen 0] Extracting seed prompt from current SKILL.md..."
    cp "$APO_DIR/../SKILL.md" "$SEED_PROMPT"
fi

# ─── Helper: run audit with a prompt variant ─────────────────────────
run_audit() {
    local prompt_file="$1"
    local case_file="$2"
    local output_file="$3"

    local case_content
    case_content=$(cat "$case_file")
    local prompt_content
    prompt_content=$(cat "$prompt_file")

    # Write combined prompt to temp file, pass as argument to claude -p
    local tmp_prompt
    tmp_prompt=$(mktemp /tmp/apo-audit-XXXXXX.txt)

    cat > "$tmp_prompt" <<PROMPT_EOF
You are running a CLAUDE.md audit using the following skill instructions:

<skill-instructions>
$prompt_content
</skill-instructions>

Audit the following CLAUDE.md file. Output ONLY the findings table in this exact format:

| Section | Lines | Verdict | Reason |
|---------|-------|---------|--------|
| ... | ... | KEEP/REMOVE/TRIM/MOVE_NESTED/MOVE_HOOK | Brief reason |

<file-to-audit>
$case_content
</file-to-audit>

Output the table and nothing else. Use exactly these verdict values: KEEP, REMOVE, TRIM, MOVE_NESTED, MOVE_HOOK.
PROMPT_EOF

    claude -p "$(cat "$tmp_prompt")" --output-format text > "$output_file" 2>/dev/null || true
    rm -f "$tmp_prompt"
}

# ─── Helper: score all cases for a prompt ────────────────────────────
score_prompt() {
    local prompt_file="$1"
    local gen_dir="$2"
    local total=0
    local count=0

    for case_file in "$CASES_DIR"/case-*.md; do
        local case_name
        case_name=$(basename "$case_file" .md)
        local answer_file="$CASES_DIR/${case_name}-answer.json"

        if [[ ! -f "$answer_file" ]]; then
            continue
        fi

        local output_file="$gen_dir/${case_name}-output.txt"
        echo "    Testing: $case_name..."

        run_audit "$prompt_file" "$case_file" "$output_file"

        # Score it
        local score_json
        score_json=$(python3 "$SCRIPTS_DIR/evaluator.py" "$output_file" "$answer_file" 2>/dev/null | head -1)
        local score
        score=$(echo "$score_json" | python3 -c "import sys,json; print(json.load(sys.stdin)['score'])" 2>/dev/null || echo "0")

        echo "      Score: $score/100"
        echo "$score" > "$gen_dir/${case_name}-score.txt"
        echo "$score_json" > "$gen_dir/${case_name}-eval.json"

        total=$(python3 -c "print($total + $score)")
        count=$((count + 1))
    done

    if [[ $count -gt 0 ]]; then
        local avg
        avg=$(python3 -c "print(round($total / $count, 1))")
        echo "$avg"
    else
        echo "0"
    fi
}

# ─── Helper: generate improved prompt variant ────────────────────────
generate_variant() {
    local current_prompt="$1"
    local failures_summary="$2"
    local variant_num="$3"
    local output_file="$4"

    local current_content
    current_content=$(cat "$current_prompt")

    local tmp_prompt
    tmp_prompt=$(mktemp /tmp/apo-mutate-XXXXXX.txt)

    cat > "$tmp_prompt" <<MUTATE_EOF
You are an Automatic Prompt Optimizer. Your job is to improve a skill prompt based on evaluation failures.

## Current Prompt (being optimized)
<current-prompt>
$current_content
</current-prompt>

## Evaluation Failures
These are cases where the prompt produced incorrect verdicts:
<failures>
$failures_summary
</failures>

## Your Task
Generate an IMPROVED version of the skill prompt that would fix these failures.

Rules:
1. Keep the overall structure (YAML frontmatter + audit procedure)
2. Make targeted changes to improve verdict accuracy
3. Add clarifying criteria where verdicts were wrong
4. This is variant $variant_num — try a DIFFERENT improvement strategy than other variants
5. Output ONLY the improved SKILL.md content, nothing else

Focus on the specific failure patterns. If the prompt fails to detect HIPAA-driven rules as KEEP,
add criteria for compliance-context awareness. If it over-removes team-specific content, add
criteria for distinguishing team conventions from generic advice.

Output the complete improved SKILL.md:
MUTATE_EOF

    claude -p "$(cat "$tmp_prompt")" --output-format text > "$output_file" 2>/dev/null || true
    rm -f "$tmp_prompt"
}

# ─── Collect failures from a generation ──────────────────────────────
collect_failures() {
    local gen_dir="$1"
    local failures=""
    local found_evals=false

    for eval_file in "$gen_dir"/*-eval.json; do
        [[ -f "$eval_file" ]] || continue
        found_evals=true

        local case_id
        case_id=$(python3 -c "import json; print(json.load(open('$eval_file'))['case_id'])" 2>/dev/null || echo "unknown")

        local misses
        misses=$(python3 -c "
import json
data = json.load(open('$eval_file'))
for s in data.get('sections', []):
    if s['verdict_score'] < 2:
        print(f\"  - {s['section']}: expected {s['expected']}, got {s['actual']}\")
" 2>/dev/null || echo "")

        if [[ -n "$misses" ]]; then
            failures+="Case $case_id:
$misses
"
        fi
    done

    # If no eval files were found, return a sentinel
    if [[ "$found_evals" == false ]]; then
        echo "NO_EVALS_FOUND"
        return
    fi

    echo "$failures"
}

# ─── Main loop ───────────────────────────────────────────────────────
BEST_PROMPT="$SEED_PROMPT"
BEST_SCORE=0

echo ""
echo "[Gen 0] Scoring seed prompt..."
GEN_DIR="$RUN_DIR/gen-0"
mkdir -p "$GEN_DIR"
BEST_SCORE=$(score_prompt "$SEED_PROMPT" "$GEN_DIR")
echo ""
echo "  >> Seed score: $BEST_SCORE/100"
echo "$BEST_SCORE" > "$GEN_DIR/avg-score.txt"
cp "$SEED_PROMPT" "$GEN_DIR/prompt.md"

for gen in $(seq 1 "$GENERATIONS"); do
    echo ""
    echo "================================================================"
    echo "[Gen $gen] Generating $VARIANTS variants..."
    echo "================================================================"

    FAILURES=$(collect_failures "$RUN_DIR/gen-$((gen-1))")

    if [[ "$FAILURES" == "NO_EVALS_FOUND" ]]; then
        echo "  ERROR: No evaluation files from previous generation. Check audit output."
        break
    fi

    if [[ -z "$FAILURES" ]]; then
        echo "  No failures to optimize — perfect score! Stopping early."
        break
    fi

    echo "  Failures to address:"
    echo "$FAILURES" | sed 's/^/    /'

    for v in $(seq 1 "$VARIANTS"); do
        echo ""
        echo "  [Gen $gen, Variant $v] Generating..."
        VARIANT_DIR="$RUN_DIR/gen-${gen}-v${v}"
        mkdir -p "$VARIANT_DIR"

        VARIANT_PROMPT="$VARIANT_DIR/prompt.md"
        generate_variant "$BEST_PROMPT" "$FAILURES" "$v" "$VARIANT_PROMPT"

        echo "  [Gen $gen, Variant $v] Scoring..."
        VARIANT_SCORE=$(score_prompt "$VARIANT_PROMPT" "$VARIANT_DIR")
        echo ""
        echo "  >> Variant $v score: $VARIANT_SCORE/100 (best so far: $BEST_SCORE)"
        echo "$VARIANT_SCORE" > "$VARIANT_DIR/avg-score.txt"

        # Keep the best
        if python3 -c "exit(0 if $VARIANT_SCORE > $BEST_SCORE else 1)" 2>/dev/null; then
            echo "  *** New best! ***"
            BEST_SCORE="$VARIANT_SCORE"
            BEST_PROMPT="$VARIANT_PROMPT"
        fi
    done
done

# ─── Final report ────────────────────────────────────────────────────
echo ""
echo "================================================================"
echo "  APO COMPLETE"
echo "================================================================"
echo "  Best score: $BEST_SCORE/100"
echo "  Best prompt: $BEST_PROMPT"
echo ""

cp "$BEST_PROMPT" "$PROMPTS_DIR/best-prompt.md"
echo "  Best prompt saved to: $PROMPTS_DIR/best-prompt.md"

echo ""
echo "  Changes from seed:"
diff --unified=3 "$SEED_PROMPT" "$BEST_PROMPT" || true

echo ""
echo "  Full results in: $RUN_DIR"
echo "================================================================"
