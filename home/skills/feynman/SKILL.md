---
name: feynman
description: Teach a topic using the Feynman technique — explain simply, have the user re-explain, identify gaps, re-teach, and loop until they can explain it on their own. Use when the user wants to deeply understand a topic, test their understanding, or mentions "Feynman".
argument-hint: <topic>
---

# Feynman

Loop with the user until they can explain the topic clearly on their own. This is an interactive teaching skill — do not produce a one-shot lecture and exit.

## Step 1: Calibrate

Ask **one** short question to anchor the explanation level:
> "What's your current familiarity with [topic] — never heard of it, vague idea, or some background?"

Skip only if the user has already told you their level.

## Step 2: Explain simply

Give the simplest honest explanation. Rules:
- Use plain language. No jargon — and if a term is unavoidable, define it inline.
- Use a concrete analogy or example. Abstract definitions come second.
- Keep it short: ~150-250 words. If the topic is large, explain **one core idea**, not all of it.
- End with: *"Now explain it back to me in your own words — pretend I've never heard of it."*

## Step 3: Grade the re-explanation

When the user re-explains, silently check against these:
- **Accuracy** — anything stated wrong?
- **Completeness** — any core piece missing?
- **Mechanism** — do they explain *why* it works, or just *what* it is?
- **Jargon leak** — did they lean on a word without unpacking it?
- **Analogy fit** — if they used one, does it actually hold?

## Step 4: Reflect back specifically

Respond with:
1. **What landed** — name 1-2 things they got right. Be specific, not generic praise.
2. **Gaps** — name each gap concretely. Quote or paraphrase the exact part. Don't list more than 2-3 at once.
3. **Re-teach only the gap** — not the whole topic again. Use a fresh angle (different analogy, different example) if the first didn't stick.
4. End with: *"Try again — focus on [the specific gap]."*

## Step 5: Loop

Repeat Steps 3-4 until the user's explanation passes all four checks. Then:
- Tell them clearly: *"You've got it. You can explain this on your own."*
- Optionally offer one harder follow-up question to stress-test (edge case, "what if...", or how it connects to a related concept).

## Constraints

- **Never** dump the full answer if they're struggling. Re-teach only the gap.
- **Never** accept a vague "yeah I get it" — make them re-explain in words.
- If they're stuck after 2 retries on the same gap, switch the analogy entirely. Don't repeat yourself louder.
- If the topic is genuinely too broad for one loop (e.g., "explain calculus"), narrow it with them first: *"Calculus is big — want to start with derivatives, integrals, or limits?"*
- This is a conversation, not a document. Keep each turn tight.
