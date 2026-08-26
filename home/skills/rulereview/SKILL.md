---
name: rulereview
description: Adversarially review changes against the personal rules in ~/.claude/rules (coding, architecture, refactoring, commit, communication, dispatch). Each candidate violation is prosecuted, then defended, and only survivors are reported. Use when the user asks to check work against their rules, run a rule review, or invokes /rulereview.
argument-hint: "[optional target: diff (default), branch, PR number, or file paths]"
---

# Rule review

Review a change set against the user's own rules. Report only violations that survive a defense.

You are the prosecutor and the defender. Do not report a finding until the defense fails.

## 1. Load the rules

Read every file in `~/.claude/rules/`:

```bash
ls ~/.claude/rules/*.md
```

Read each file in full. Do not work from memory. The files change.

Also read the repository `CLAUDE.md` when one exists. A repository rule overrides a global rule on the same subject.

## 2. Resolve the target

Use `$ARGUMENTS` when present. Otherwise use the working-tree diff.

```bash
git diff                # unstaged
git diff --cached       # staged
git diff main...HEAD    # branch
```

Read each changed file in full. A diff hunk alone does not show the surrounding style, and several rules depend on the surrounding style.

Report `No changes to review` and stop when the diff is empty.

## 3. Gate each rule file for relevance

Not every rule applies to every change. Decide per rule file before you review:

| Rule file | Applies when |
| --- | --- |
| `coding.md` | always |
| `commit.md` | the change includes a commit message, PR body, or release note |
| `communication.md` | the change includes prose a human reads: docs, README, commit body, PR description, user-facing strings |
| `architecture.md` | the change adds or changes application code with layers, domain logic, or module boundaries |
| `refactoring.md` | the change moves, renames, or restructures existing code without changing behavior |
| `dispatch.md` | the change configures a loop, a monitor, a schedule, or an agent model |

Say which rule files you skipped and why. A skipped rule is a decision, not an omission.

Warning: do not apply `architecture.md` to configuration code. Ports and adapters, typed identifiers, and aggregates do not map to Nix modules, YAML, or shell scripts. Forcing them produces noise.

## 4. Prosecute

For each applicable rule file, review the change through that rule alone. Do not mix lenses. One pass per rule file.

For each candidate violation, record four things:

1. the rule, quoted from the rule file in the user's own words;
2. the exact `file:line`;
3. what the code does that the rule forbids;
4. the concrete cost — the bug, the wasted work, or the future edit this causes.

Be aggressive here. The goal of this pass is coverage, not precision. Step 5 removes the bad findings.

### What each rule looks like as a violation

**`coding.md`**
- Code the user did not ask for: a flag, an option, a hook, an abstraction with one caller.
- Error handling for a state the code cannot reach.
- A change to a line that the user's request does not require. Trace every changed line back to the request. A line that does not trace is a violation.
- An "improvement" to adjacent code, a comment, or formatting.
- A silent choice between two readings of the request.
- No stated success criteria for a multi-step task.

**`architecture.md`**
- A caller that must make several calls, or pass many arguments, for the common case.
- Domain code that imports infrastructure, or constructs its own dependencies.
- A port named for its technology instead of its domain concept.
- A raw string, integer, or map crossing a layer boundary.
- A wrapper whose interface is as complex as its implementation.
- A domain test that needs a database, network, or filesystem.

**`refactoring.md`**
- Restructured code with no test covering the behavior, before or after.
- A test that would still pass if the refactored code were deleted.
- A refactor started without the user's approval.

**`commit.md`**
- A `Co-Authored-By` trailer naming Claude or any AI.
- Any mention that an AI or an agent made the change.

**`communication.md`**
- Prose that opens with a preamble, or closes with "hope this helps".
- A step with two "and then" clauses.
- A list longer than five items with no ranking.
- A vague estimate where a concrete one belongs.
- An idiom or a figurative phrase.

**`dispatch.md`**
- A loop, a monitor, or a recurring agent that does not pin Sonnet.

## 5. Defend

Take each candidate from step 4. Argue against it. Ask, in order:

1. **Does the rule really say this?** Re-read the quoted line. Do not extend a rule past its words.
2. **Does the rule apply to this file?** Check the step 3 gate again for this specific file.
3. **Did the user ask for it?** Read the request again. A rule does not override an explicit instruction. A user who asks for a configuration flag gets a configuration flag.
4. **Does the surrounding code already do this?** `coding.md` says to match existing style. A change that follows the file's existing pattern is not a violation, even when the pattern is poor.
5. **Is the cost real?** Name the concrete failure. When you cannot name one, the finding is taste, not a violation.
6. **Would the fix break another rule?** Simplicity and deep modules pull against each other. So do "surface the tangent" and "suppress tangents". When two rules collide, report the collision. Do not pick a side silently.

Drop the finding when any answer defeats it. Keep the finding only when every answer fails.

Do not soften a dropped finding into a "nit". Drop it.

## 6. Report

Order the sections by rule severity, not by file.

```
## Verdict
PASS | VIOLATIONS FOUND

## Rules applied
<rule files reviewed> — <rule files skipped, with reason>

## Violations
- [file:line] <rule file> — <what the code does> — <the cost>
  Rule: "<quoted rule text>"
  Fix: <the smallest change that satisfies the rule>

## Rule collisions
- <rule A> and <rule B> disagree at [file:line]. <one line on each side.> Decide.

## Dropped
- <candidate> — <which defense killed it>
```

Keep `Dropped` short. One line each. It shows coverage without adding noise.

Report `PASS` and an empty `Violations` section when nothing survives step 5. An empty report is a real result. Do not manufacture a finding to justify the review.

## 7. Stop

Report only. Do not edit files.

Offer one next action: the single highest-cost violation, named with its file and line. When the user asks for fixes, apply them one rule at a time, and follow `refactoring.md` — ask before you restructure anything.
