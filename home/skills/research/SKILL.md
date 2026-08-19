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
exacli search "<topic or question>" --type deep-reasoning --output-schema '{"type":"text","description":"Return key findings with source citations"}'
```

The output schema returns the synthesized answer in `output.content`. It does not need polling.

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
