---
name: refine
description: Refine a PRD based on user notes scattered throughout the plan
argument-hint: <prd-path>
---

Refine an existing PRD by incorporating user notes into a revised plan.

## Usage

```
/refine [prd-path]
```

## Parameters

- `prd-path`: Path to the PRD directory to refine (optional)

If no path is given, infer the PRD from the current session:
1. Check the conversation for tool calls or file writes referencing `prd/` paths
2. Search `prd/*/prd.md` for the most recently modified PRD
3. If no PRD is found, ask the user which one to refine

## How It Works

1. Read all files in the PRD directory: `prd.md`, `tasks.yaml`, and all `*.md` detail files
2. Extract every user annotation that starts with `note:` (case-insensitive, can appear anywhere in any file)
3. Synthesize the notes into a refined plan that addresses each one
4. Overwrite the existing PRD files with the refined versions

## Refinement Process

### Phase 1: Gather Notes

- Read every file in `{prd-path}/` recursively
- Extract all lines/blocks prefixed with `note:` — these are user feedback, corrections, or new requirements
- Deduplicate and group related notes

### Phase 2: Analyze Impact

For each note, determine:
- Which section of the PRD it affects (problem statement, goals, acceptance criteria, tasks)
- Whether it's a correction (contradicts existing content), an addition (new requirement), or a clarification
- Which tasks are impacted

### Phase 3: Rewrite

- Rewrite `prd.md` incorporating all notes — the refined version should not contain any `note:` prefixes
- Update `tasks.yaml` — add new tasks, remove obsolete ones, adjust dependencies
- Update detail files — revise task details to reflect the refined plan
- If a note introduces a fundamentally new concern, create new detail files for it

### Phase 4: Validate

- `prd.md` contains no `note:` prefixes
- `tasks.yaml` has valid schema (all tasks have status: open, dependencies reference existing keys)
- No detail file references a deleted task

## Constraints

- Preserve the existing PRD structure and conventions
- If a note contradicts an existing requirement, the note wins — the user is refining their intent
- Don't add scope beyond what the notes address — this is refinement, not expansion
- Keep tasks minimal and focused, same as the original `/prd` process

## Output Format

```
✓ Refined: prd/{feature-name}/
  - prd.md (updated)
  - tasks.yaml ({n} tasks, {changed} changed, {added} added, {removed} removed)
  - {n} detail files updated

Notes incorporated:
  1. {summary of note 1}
  2. {summary of note 2}
  ...
```
