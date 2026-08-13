---
name: tasks
description: "Break down a PRD into a tasks.yaml with dependencies using the task breakdown agent, creating or refining the PRD with the planner agent when needed. Use when given a PRD file path or feature description that needs to be decomposed into actionable, ordered tasks. Produces prd.md + tasks.yaml + per-task detail files."
---

# Task Breakdown

Break down a PRD into actionable tasks with dependencies.

## Usage

The user provides either:
1. A **file path** to an existing PRD markdown file
2. A **description string** for a new feature

Optional: `--name <feature-name>` to override the auto-generated feature name.

If no name is provided, generate one from the first 4 words of the description, lowercase and hyphenated.

Example: "Build user authentication system" → `build-user-auth-system`

## Output Directory

```
./prds/<feature-name>/
```

Create the `prds/` directory in the current working directory if it does not already exist.

## Task YAML Spec

```yaml
tasks:
  - key: task-name          # unique kebab-case identifier
    description: Brief description of the task
    details: ./task-name.md # path to detail file with implementation notes
    status: open            # open, progress, or done
    depends: []             # list of task keys this depends on
```

## Execution

**Delegation requirement:** if a PRD needs to be created or refined, use `planner_agent`. Use `task_breakdown_agent` to produce `tasks.yaml` and the task detail files.

### Phase 1: Research

Research best practices and patterns relevant to the feature. Use web search or codebase exploration.

### Phase 2: Refine PRD

If the input is a description (not an existing PRD file), use `planner_agent` to create the `prd.md` draft following the PRD structure below, then write that result to `./prds/<feature-name>/prd.md`:

1. **Problem Statement** — what is broken or missing
2. **Goals** — outcomes we want
3. **Non-Goals** — explicit scope boundaries
4. **Acceptance Criteria** — user-observable requirements
5. **Out of Scope** — what this excludes

**PRD constraints:**
- WHAT and WHY only, never HOW
- No code examples, class names, file paths, or implementation patterns
- Acceptance criteria describe user-observable outcomes

If the input is an existing PRD file, refine it with `planner_agent` only if needed.

### Phase 3: Create Tasks

Use `task_breakdown_agent` with the final PRD content and target directory. Write the returned `tasks.yaml` and each detail file into `./prds/<feature-name>/`.

Break the PRD into tasks following the YAML schema above. For each task:

1. Add an entry to `tasks.yaml` with `status: open`
2. Create a detail file (`./task-name.md`) with implementation specifics
3. Set `depends` based on actual ordering requirements

**Task constraints:**
- Descriptions are action-oriented ("Implement X", "Add Y")
- Implementation specifics (patterns, file structure, migration steps) go in detail files
- Keep scope minimal and focused
- Dependencies reference existing task keys only

### Phase 4: Validate

```bash
uv run ~/.pi/agent/skills/tasks/tasks.py <output-dir>/tasks.yaml summary
```

Should show only `open` tasks.

## Task Management

```bash
# Summary of task statuses
uv run ~/.pi/agent/skills/tasks/tasks.py <path>/tasks.yaml summary

# List tasks (optionally filter by status)
uv run ~/.pi/agent/skills/tasks/tasks.py <path>/tasks.yaml list
uv run ~/.pi/agent/skills/tasks/tasks.py <path>/tasks.yaml list --status open

# View a single task
uv run ~/.pi/agent/skills/tasks/tasks.py <path>/tasks.yaml get <key>

# Update task status
uv run ~/.pi/agent/skills/tasks/tasks.py <path>/tasks.yaml set <key> progress
uv run ~/.pi/agent/skills/tasks/tasks.py <path>/tasks.yaml set <key> done

# Show tasks whose dependencies are all done
uv run ~/.pi/agent/skills/tasks/tasks.py <path>/tasks.yaml ready

# Verify all tasks are done (exit 0) or list incomplete (exit 1)
uv run ~/.pi/agent/skills/tasks/tasks.py <path>/tasks.yaml verify
```

## Output Format

```
✓ Tasks created: prds/<feature-name>/
  - prd.md
  - tasks.yaml (X tasks)
  - {X} detail files

Tasks:
  1. task-name-1 (no deps)
  2. task-name-2 (depends: task-name-1)
  ...

Next: /skill:code prds/<feature-name>/tasks.yaml
```
