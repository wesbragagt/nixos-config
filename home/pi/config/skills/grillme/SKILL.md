---
name: grillme
description: "Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when the user wants to stress-test a plan, get grilled on their design, or mentions 'grill me'."
---

# Grillme

Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".

## Instructions

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

If a question can be answered by exploring the codebase, explore the codebase instead of asking me.

Rules:
- Work through the plan step-by-step, branching into sub-decisions
- If a question can be answered by reading the codebase, DO THAT FIRST before asking the user
- For each answer, follow up: "why?", "what if X?", "how does this affect step N?"
- Resolve one branch fully before moving to the next
- Do NOT make any changes to the codebase
- When all branches are resolved or the user says to stop, summarize the key decisions made and suggest next steps
