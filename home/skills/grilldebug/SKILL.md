---
name: grilldebug
description: Relentlessly interrogate a bug until its root cause is cornered — grillme-style, but for debugging. Explore the code, drive a one-question-at-a-time interview in plan mode down each branch of the failure tree, then run a complete systematic diagnosis yourself. Use when the user wants to be grilled toward a root cause, mentions "grilldebug", or has a stubborn bug that needs methodical RCA rather than a guess.
argument-hint: "<problem description>"
---

# grilldebug

Corner the root cause. Do not guess, do not fix — interrogate until the failure has nowhere left to hide, then run the systematic diagnosis yourself. Do all of this as the main agent; do not delegate to a subagent.

## Intake

Take the problem description the user supplied as arguments (`$ARGUMENTS`) as the starting point — this is their direction on what to debug. If no description was given, ask the user for one before doing anything else: what's broken, what they expected, and what they saw instead. Everything below builds on that description; treat it as the root of the failure tree, not a fixed conclusion.

The discipline: move from reactive pattern-matching to systematic hypothesis-testing. Every question narrows the problem space. Every answer either kills a branch of the failure tree or opens the next one.

## Step 1: Explore first

Before asking anything, arrive informed. Do lightweight exploration so your questions target only what the code can't answer:

- Read every file named in the error or description
- Follow the stack trace end to end — read each file it touches
- Check recent history if relevant (`git log --oneline -15`, `git diff`)
- Find related files: config, tests, imports, callers of the failing function

**If a question can be answered by exploring the codebase, explore instead of asking.** The user's time is for what only they know: environment, timing, what changed, what they observed.

## Step 2: Grill in plan mode — one branch at a time

Enter plan mode. Then interrogate the bug **relentlessly, one question at a time**, walking down each branch of the failure tree and resolving dependencies between answers as you go. This is an interview, not a questionnaire — each question is chosen based on the previous answer.

Ask pointed prose questions (not multiple-choice menus). Drive toward these until each is nailed down or explicitly ruled out:

- **Reproduce reliably** — exact inputs, state, and sequence that trigger it. Is it deterministic? If not, what varies between a pass and a fail?
- **Timeline** — when did it start? What changed before then (deploy, config push, dependency bump, data change, external event)?
- **Symptom vs. cause** — is the visible error the origin, or a downstream effect of corrupted state / bad data from upstream?
- **Scope** — everywhere or one environment/user/tenant/record? What's different about the cases that fail?
- **Frequency & conditions** — always, intermittently, under load, at boundaries (empty, first, last, concurrent)?
- **Hypothesis probing** — as a theory forms, ask the one question whose answer would confirm or falsify it. State the prediction: "if X is the cause, you'd also see Y — do you?"

Keep going until you can commit to a single best-supported hypothesis, or until only hands-on code investigation can settle it. Resolve one branch before opening the next. Do not batch-dump questions; do not move on while an answer is vague.

## Step 3: Run the diagnosis yourself

Exit plan mode, then investigate directly as the main agent — do **not** spawn a subagent. Do not write any code yet; produce analysis and recommendations only. Work these phases in order:

### Phase 1: Root Cause Investigation
- Re-read the full error and stack trace carefully
- Trace execution from entry point to the failure
- Read every file in the trace or description
- Identify the exact line and condition where the failure originates

### Phase 2: Pattern Analysis
- Classify the bug: race condition, null reference, off-by-one, auth timing, state mutation, type mismatch, async boundary, missing guard, upstream data corruption, etc.
- Look for the same pattern elsewhere that may also be affected

### Phase 3: Hypothesis Testing
- Commit to ONE specific, falsifiable hypothesis (start from the interview's leading hypothesis; overturn it only with evidence)
- State the evidence for it and what would disprove it
- Do not hedge across multiple causes — pick the best-supported one

### Phase 4: Fix Recommendation (only after Phase 3)
- Describe precisely what must change and why it addresses the root cause, not the symptom
- Recommend the regression test type (unit / integration / e2e) with a one-line rationale

## Step 4: Present the diagnosis

Report in this structure:

```
**Root cause:** [one-line summary]

**Root Cause**
What's failing and why. Distinguish immediate cause from underlying cause if they differ.

**Evidence**
What confirms this from the code, trace, or behavior.

**Fix**
Which file, which function, what logic changes and how — prose, no code.

**Regression Test**
Which type (unit / integration / e2e) and why, then what it should verify.
```

Then confirm the fix approach with the user before any code is written — this skill diagnoses; it does not implement.
