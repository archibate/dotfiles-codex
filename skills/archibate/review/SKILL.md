---
name: review
description: >
  Review code for bugs, AI slop patterns, or documentation issues, then fix
  them interactively. This skill should be used after completing a major code
  modification or large multi-file edits — or when the user says "review",
  "review changes", "any bugs?", "review AI slop", "clean up AI code",
  "review docs", "code review".
---

# Review

Infer intent, scope, and review mode from what the user said. No formal arguments.

- **Agent**: `code-review` for bugs (default), `ai-slop-review` for AI slop, `doc-review` for documentation, all three for "full review"
- **Scope**: specific files if mentioned, `git diff` if uncommitted changes exist, else project directory

## Steps

### 1. Launch Review

Determine scope and invoke the appropriate agent(s). Tell the agent the target
(file paths or `"git diff"`). For "full review", launch all three agents in
parallel.

### 2. Create Issue List

Assign each finding a short codename (1-2 letter prefix + number) and
`TaskCreate` each. Emit a terse receipt — one bulleted line per codename,
in the order the agents returned them. Format: `- **codename** — issue title`
(no severity yet; severity lands in step 5's table after verification).
Example:

> - **P1** — Silent exception swallow
> - **P2** — Early-return swallows JSON parse errors
> - **P3** — Duplicate list comprehension
> - **P4** — Duplicated arg handling

### 3. Verify Findings

Before the list is treated as actionable, locate each reported finding in the
actual code and sanity-check it. Agents can hallucinate, misread, or describe
real issues inaccurately — pruning these up front keeps the quick-wins batch
and the fix cycle honest.

For each codename:
1. Read the cited `file:line` (or grep for the symbol if no location is given)
2. Confirm the described behavior matches what the code actually does — not
   what the agent inferred
3. Classify:
   - ✅ **confirmed** — real and accurately described; keep as-is
   - ⚠️ **partial** — real issue but description is off; `TaskUpdate` with the
     corrected description
   - ❌ **false positive** — agent misread or fabricated; `TaskUpdate` to
     `deleted` with a one-line reason (e.g., "agent assumed X but
     `path.py:42` actually does Y")

Keep this a lightweight pass — just enough to trust the list. Deep call-site
tracing and related-logic checks stay in step 6's per-issue investigation.

Before moving on, give the user a terse verification report — tally plus
per-codename outcomes. Confirmed codenames collapse into one line; ⚠️/❌
entries get one-line reasons. Example:

> 6 confirmed (P1, P3–P5, P7–P8) · 1 partial · 2 false positives
> - ⚠️ P6 — agent said X, actually Y (description updated)
> - ❌ P2 — agent misread the early-return at `util.py:12`
> - ❌ P9 — agent fabricated the call site

The updated list with file locations renders in step 5.

### 4. Quick Wins

Among verified issues, mark those that are mechanical, behavior-preserving,
nits, and need no design decisions by appending `*` to their severity cell
(e.g., 🔴 → 🔴*). Step 5's render will surface them for batch-fix.

### 5. Render Final Table

Now that verification (step 3) has pruned false positives and quick-win
marking (step 4) has starred mechanical fixes, render the single
authoritative summary table the user picks from. Severity encoding:
🔴 high / 🟡 moderate / 🟢 low — with `*` appended to the severity cell for
quick-wins.

| Codename | Severity | File:Line       | Issue                           |
|----------|----------|-----------------|---------------------------------|
| P1       | 🔴       | parser.py:42    | Silent exception swallow        |
| P3       | 🔴*      | util.py:88      | Duplicate list comprehension    |
| P4       | 🟡       | cli.py:12       | Duplicated arg handling         |
| P7       | 🟢       | docs.md:3       | Missing docstring               |

`*quick-win: can be batch-fixed without behavior changes`

Keep `Detail` and `Suggested Fix` inside each `TaskCreate` body — the table
is for scanning and picking only. Then offer to batch-fix all quick-wins
before entering the interactive cycle.

### 6. Pick-Discuss-Fix Cycle

After rendering the final table (step 5), and after each resolved issue,
recommend **exactly 3 next issues**. Format:
`**codename** [severity] — issue title` (a brief recall of *what* the issue
is, not the fix direction). If fewer than 3 remain, show all remaining.

Then wait for the user to reply with a bare codename (e.g., "P1"). Process:

1. **Investigate** — mark task `in_progress`; read the cited `file:line`,
   trace call sites, check related logic. For doc issues, verify the claim
   against the referenced code/behavior (not just the prose). If the agent's
   report turns out wrong, note it in the recommendation below.

2. **Explain + recommend** — pick Shape A (recommend fix) or Shape B
   (recommend skip), emit it, wait for the user.

   **Shape A — recommending fix:**

   **P1** [🔴] — Silent exception swallow

   🔍 **Reason**: <one sentence, under 10 words>
   🛠️ **Fix plan**: <one sentence>
   ⚠️ **Risk**: <what the fix could break, one sentence>
   <optional ```diff block``` when the change is small>

   User replies `fix` (continue to stage 3) or `skip` (mark task
   `deleted`, jump to "recommend next 3").

   **Shape B — recommending skip:**

   **P1** [🔴] — Silent exception swallow

   🔍 **Reason**: <one sentence, under 10 words>
   ⏸️ **Skip**: <one clause why>

   User replies `skip` to confirm (mark task `deleted`, jump to
   "recommend next 3") or `fix anyway` to override (continue to stage 3).

   Phrase reason/fix/risk at *concept level*, not code level: state the
   observability gap and the behavior change, not the variables or call
   sites. The diff carries the concrete detail.

   ❌ Avoid: "`parse_response()` at `api.py:42` swallows `JSONDecodeError`
   via bare `except:`; add an explicit `ValueError` raise so callers see
   malformed input."
   ✅ Good: "Parse errors silently swallowed. Re-raise so callers can
   handle."

3. **Fix** — execute the edits. If testable, run a quick check (import,
   minimal script, unit test; for doc fixes, re-read the referenced code to
   verify). If the test reveals the fix is wrong, revise before continuing.
   Mark task `completed`.

4. **Report** — emit the fix close-out:

   `✅ **P1** Fixed — <one short sentence>`

   Append at most one short sentence per applicable caveat:
   - `📝 Plan delta: <one sentence>` — executed change deviated from plan.
   - `🧪 Untested: <one sentence>` — display-only / pure refactor / no harness.
   - `🔄 Downstream: <one sentence>` — re-run / rebuild / migration needed.
   - `🆕 Surfaced: **codename** [severity] — <title>` — one line per new codename.

   No prose rationale, no insights block, no narrative beyond the sentences above.

Then recommend the next 3.

**Rules:**
- After each resolved issue, show only the next 3 — do not dump the full list.
- If the user adjusts the fix plan during stage 2, revise stage 3 accordingly.
- If investigation or the fix surfaces a *distinct* issue outside the
  current codename's scope, `TaskCreate` it with the next prefix number.
  Do not expand the current fix; it lands in the next `recommend 3`
  block and as `🆕 Surfaced` in stage 4's report.

### 7. Wrap Up

When all issues are resolved or skipped:

1. **Sanity check first** — run `git diff --stat` and skim each changed file.
   Look for: line-number drift in comments/docs, stale references to removed
   symbols, inconsistencies between related edits (spec ≡ code, comment ≡
   implementation). If anything is found, file it via `TaskCreate` with the
   next codename and re-enter step 6's pick-discuss-fix cycle. Wrap-up
   resumes only after the new queue is drained.

2. Show a final tally table — same column order as step 5, with `File:Line`
   dropped, `Resolution` appended, and a `Note` column summarising what was
   actually done (for `✅ fixed`) or why it was deferred (for `⏸️ skipped`).
   Resolution maps 1:1 to task state: ✅ fixed (task `completed`) or
   ⏸️ skipped (task `deleted`). Keep each `Note` to one line; it describes
   the *actual* change, which may differ from the agent's suggested fix.
   Example:

   | Codename | Severity | Issue                        | Resolution | Note                                      |
   |----------|----------|------------------------------|------------|-------------------------------------------|
   | P1       | 🔴       | Silent exception swallow     | ✅ fixed   | Replaced bare `except:` with `ValueError` |
   | P3       | 🔴*      | Duplicate list comprehension | ✅ fixed   | Extracted to `_filter_active()` helper    |
   | P4       | 🟡       | Duplicated arg handling      | ⏸️ skipped | User deferred — planned for a later PR    |
   | P7       | 🟢       | Missing docstring            | ✅ fixed   | Added 2-line docstring                    |

3. Summarize downstream actions required (re-runs, rebuilds, tests, migrations, etc.)
4. Offer to commit if there are changes
