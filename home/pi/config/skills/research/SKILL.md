---
name: research
description: "Research a topic or question using web search. Use when the user asks to research, investigate, explore, look into, or learn about any topic — e.g. 'research X', 'what do we know about Y', 'look into Z', 'deep dive on'."
argument-hint: <topic or question>
---

# Research

Research a topic using web search, then present findings.

## Step 1: Classify

Based on the user's question:

- **answer** — single-concept, factual, quick lookup
- **deep-research** — comparisons, how-to, multi-part, open-ended

## Step 2: Search

Use the exacli skill to gather information.

For **answer**:
```bash
exacli answer "<topic or question>" --text
```

For **deep-research**:
```bash
exacli research "<topic or question>" --poll
```

If `exacli research` returns an error (e.g. 404), fall back to:
```bash
exacli answer "<topic or question>" --text
```

For additional depth, supplement with:
```bash
exacli search "<specific subtopic>" --num-results 5 --text --toon
```

## Step 3: Present

For **answer**:
```markdown
### [Topic]
- [key point ×3-5]

**Sources**
- [Title](url)
```

For **deep-research**:
```markdown
### [Topic]
- [key point ×3-5]

**Examples**
[code snippets or real-world usage if found]

**Sources**
- [Title](url)
```

List all citations as markdown links. Flag gaps if sources are sparse.
