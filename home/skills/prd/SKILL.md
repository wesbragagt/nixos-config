---
name: prd
description: "Plan a feature by creating a PRD with the planner agent and a task breakdown with the task breakdown agent. Use when the user wants to plan a feature, write requirements, or break down work into tasks. Accepts a feature name and description, produces prd.md + tasks.yaml + detail files."
argument-hint: <feature-name> --description "<description>" [--context "<context>"] [--quick]
---

# PRD Planner

Plan a feature by creating a product requirements document and actionable task breakdown.

## Usage

The user provides a feature name and description. Parse these from their input:

- **feature-name**: kebab-case identifier (required)
- **description**: what needs to be done (required)
- **context**: optional additional requirements
- **--quick**: skip research phase

## Output Directory

```
./prds/<feature>/
```

Create the `prds/` directory in the current working directory if it does not already exist.

Files produced:
- `prd.md` — product requirements
- `tasks.yaml` — task list with dependencies
- `*.md` — one detail file per task (implementation specifics)

## Execution

**Delegation requirement:** do not draft the PRD or task breakdown directly. Use `planner_agent` for the PRD, then use `task_breakdown_agent` for the task breakdown.

### Phase 1: Research (skip if --quick)

Research best practices and patterns relevant to the feature. Use web search or codebase exploration as needed.

### Phase 2: Draft PRD with the planner agent

Use `planner_agent` with the feature name, description, optional context, and any research findings. Ask it to return only the markdown for `prd.md`.

After the delegated result returns, review it for fit, then write it to `./prds/<feature>/prd.md`.

The planner agent must follow this skeleton:

1. **Problem Statement** — what is broken or missing, and the user/business impact
2. **Goals** — outcomes we want, written as capabilities or properties
3. **Non-Goals** — explicit scope boundaries
4. **Acceptance Criteria** — functional, user-observable requirements (no code)
5. **Out of Scope** — what this PRD deliberately excludes

**PRD constraints:**
- Write at the product requirements level: WHAT and WHY, never HOW
- No code examples, class names, file paths, or implementation patterns
- Acceptance criteria describe user-observable outcomes ("users can do X"), not implementation steps
- If a technical approach section is needed, keep it to 2-3 sentences of high-level direction only
- Implementation specifics belong in task detail files, not in the PRD

### Phase 3: Create Tasks with the task breakdown agent

Use `task_breakdown_agent` with the final `prd.md` content and the target directory. Ask it to return:
- a `tasks.yaml` draft
- one detail file draft per task

After the delegated result returns, write `tasks.yaml` and each detail file into `./prds/<feature>/`.

Break the PRD into minimal, focused tasks. Each task gets a detail file for implementation specifics.

**Task YAML schema:**

```yaml
tasks:
  - key: task-name          # unique kebab-case identifier
    description: Brief description of the task
    details: ./task-name.md # path to detail file
    status: open            # open, progress, or done
    depends: []             # list of task keys this depends on
```

**Task constraints:**
- Use `status: open` (not `done: false`)
- Task descriptions are action-oriented ("Implement X", "Add Y")
- Implementation specifics (patterns, file structure, migration steps) go in the detail `.md` files
- Dependencies reference existing task keys only
- Keep scope minimal and focused

### Phase 4: Validate

Verify:
- `prd.md` contains no code blocks or file paths
- `tasks.yaml` has valid schema
- All tasks have `status: open`
- Dependencies reference existing task keys

Run:
```bash
uv run ~/.omp/agent/skills/tasks/tasks.py <output-dir>/tasks.yaml summary
```

Should show only `open` tasks.

## Task Management

After creation, manage tasks with:

```bash
uv run ~/.omp/agent/skills/tasks/tasks.py <path>/tasks.yaml summary
uv run ~/.omp/agent/skills/tasks/tasks.py <path>/tasks.yaml list --status open
uv run ~/.omp/agent/skills/tasks/tasks.py <path>/tasks.yaml ready
uv run ~/.omp/agent/skills/tasks/tasks.py <path>/tasks.yaml set <key> done
```

## Output Format

Present the result as:

```
✓ PRD created: prds/<feature>/
  - prd.md
  - tasks.yaml (X tasks)
  - {X} detail files

Dependency Graph:
create-store
└── create-hooks
    ├── build-ui
    └── write-tests

Next: /skill:code prds/<feature>/tasks.yaml
```
