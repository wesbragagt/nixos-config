---
name: notai
description: Rewrite messages so they sound direct, natural, and human instead of AI-generated. Use when asked to make text less AI, more natural, more concise, or suitable for Slack, email, or a status update.
argument-hint: "text to rewrite — optional"
---

# Not AI

Rewrite the message without changing its facts, meaning, or level of certainty.

## Core rules

- Lead with the result or the most important point.
- Use plain, specific language.
- Remove filler, repetition, corporate phrasing, and generic conclusions.
- Prefer short sentences and active voice.
- Keep one idea per bullet.
- Use concrete names, dates, identifiers, and technical terms when they matter.
- Explain the impact of a problem, not only the implementation detail.
- Separate the final state from problems caught during review.
- State risks and limitations directly.
- Do not add claims, context, emotion, or certainty that the source does not contain.
- Keep the original scope. Do not turn a short update into an essay.

## Avoid AI writing signals

Remove or reduce:

- "I hope this message finds you well"
- "Here is a comprehensive overview"
- "It is worth noting"
- "Moving forward"
- "In summary"
- "seamless", "robust", "enhanced", "leveraged", and similar vague adjectives
- Repeated headings that say the same thing
- Long introductions before the result
- Balanced-sounding filler such as "not only X, but also Y"
- Unnecessary apologies, disclaimers, and offers to help
- Excessive parenthetical explanations
- Perfectly symmetrical lists when the facts are not symmetrical

## Slack format

When the target is Slack:

1. Start with a short status line in bold.
2. Use at most three sections: `Fixed`, `Caught before apply`, and `Verified`.
3. Use compact bullets with one fact per bullet.
4. Put technical identifiers in backticks, such as `implentio.com`, `dig`, or `#3438`.
5. Put the outcome before the explanation when possible.
6. End with the relevant link, pull request, owner, or next action.
7. Do not add a greeting or sign-off unless the source includes one.

Preferred shape:

```text
*<short status>*

*Fixed:*
• <change> — <impact or reason>

*Caught before apply:*
• <issue> — <how it was caught or resolved>

*Verified:*
• <evidence and current state>

<PR, link, owner, or next action>
```

Use only the sections that contain useful information. Do not force the template.

## Other formats

- For email, use a short subject only when requested.
- For incident updates, use `Impact`, `Cause`, `Current state`, and `Next action` only when those facts exist.
- For commit or pull request text, state the change, reason, and verification.
- For prose, use short paragraphs instead of artificial headings.

## Final check

Before returning the rewrite, confirm:

- Every original fact remains.
- No new fact or implied guarantee was added.
- The first line tells the reader why the message matters.
- The message can be scanned quickly.
- The tone matches the target channel and audience.
