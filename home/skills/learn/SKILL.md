---
name: learn
description: Build a focused 20-hour learning plan for a topic, structured as 10 two-hour sessions following the Pareto principle (20% that drives 80% of results). Use when the user wants to learn a topic fast, build a study plan, or create a structured curriculum.
argument-hint: <topic>
---

# Learn

Build a 20-hour plan to learn a topic fast, focused on the 20% that drives 80% of results. Output 10 two-hour sessions, each ending with a 15-minute review.

## Step 1: Clarify the topic (if needed)

If the topic is ambiguous (e.g., "ML" → supervised? deep learning? deployment?), ask **one** clarifying question before proceeding. Otherwise skip.

## Step 2: Research the 20%

Delegate to the `researcher` subagent to identify:
- The core concepts that experts agree drive most outcomes in this topic
- The best resources (books, courses, docs, videos, repos) — prefer canonical/authoritative sources
- Common beginner traps to skip

Use `subagent_type: "researcher"`, `model: "haiku"`.

Prompt:
```
text: What are the 20% of concepts in [TOPIC] that drive 80% of practical results? List the highest-signal resources (books, courses, official docs, key papers/repos) a motivated learner should use to master those concepts in ~20 hours. Flag common time-wasters to skip.
mode: deep-research
```

## Step 3: Build the plan

Synthesize the research into 10 sessions. Each session:

- **2 hours total**: ~105 min learning + ~15 min review
- **One clear learning objective** per session — a concrete capability, not a vague theme
- **Progression**: foundations → core mechanics → applied practice → integration
- **Concrete resources**: name the specific chapter, video, doc page, or exercise — not "read about X"
- **Hands-on bias**: at least half the sessions include building, coding, or solving problems
- **Review block (last 15 min)**: recall without notes, summarize in own words, list 1-2 questions to revisit

## Step 4: Present

Output format:

```markdown
# 20-Hour Plan: [Topic]

**Focus:** [one-sentence framing of the 20% being targeted]
**Prerequisites:** [what learner should already know, or "none"]

---

## Session 1 — [Title] (2h)
**Objective:** [concrete capability after this session]
**Learn (105 min):**
- [Resource + specific section/chapter/exercise]
- [Resource + specific section/chapter/exercise]
**Review (15 min):**
- [Recall prompt or summary task specific to this session]

## Session 2 — [Title] (2h)
...

[continue through Session 10]

---

## Capstone check
After Session 10, you should be able to: [3-5 bullet outcomes]

## Sources
- [Title](url)
- [Title](url)
```

## Constraints

- Do not pad sessions with filler. If the topic genuinely fits in fewer hours, say so and propose a shorter plan instead.
- Every resource must be named specifically (title + section). No "find a tutorial on X."
- The review block is non-negotiable — it's where retention happens.
