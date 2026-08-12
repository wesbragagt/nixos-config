---
name: code
description: "Execute tasks from a tasks.yaml by implementing them with dependency resolution and status tracking. Use when given a tasks.yaml path to work through ready tasks."
argument-hint: <path-to-tasks-yaml> [--task <task-key>]
---

# Task Executor

Execute tasks from a `tasks.yaml` file with automatic dependency resolution and status tracking.

## Usage

The user provides a path to a `tasks.yaml` file. Optionally they can specify `--task <key>` to execute a single task.

## Execution

### 1. Load and validate

```bash
uv run ~/.pi/agent/skills/tasks/tasks.py <path-to-tasks.yaml> summary
```

Report task counts: total, done, in-progress, open.

### 2. If --task specified

Jump directly to step 5 for that task.

### 3. Find ready tasks

Ready tasks have `status == "open"` and all keys in `depends` have `status == "done"`.

```bash
uv run ~/.pi/agent/skills/tasks/tasks.py <path> ready
```

### 4. If no ready tasks

- All done → report completion and stop
- Circular deps or all blocked → report which tasks are blocking and stop
- Tasks in progress → report waiting state

### 5. Determine execution strategy

**Run sequentially** when tasks:
- May modify the same file(s)
- Share configuration or state files
- Have overlapping file paths
- When in doubt → sequential

**Batch** (up to 3) when tasks touch completely separate files/domains.

### 6. For each ready task

#### a. Mark in progress

```bash
uv run ~/.pi/agent/skills/tasks/tasks.py <path> set <task-key> progress
```

#### b. Gather context

- Read the PRD file in the same directory (`prd.md`)
- Read the task's detail file if `details` path is set
- Read detail files from completed dependent tasks
- Scan codebase for relevant existing patterns

#### c. Implement the task

Act as a **senior software engineer** specializing in the detected language/framework.

Follow the task's detail file for implementation specifics. If no detail file exists, use only the task description and PRD context.

**Constraints:**
- Follow existing codebase conventions
- Ensure compatibility with completed dependent tasks
- Write production-ready code
- No new external dependencies without explicit approval

**Verification after implementation:**
1. Code compiles/runs without errors
2. Existing tests still pass
3. Implementation matches task details

#### d. On success, mark done

```bash
uv run ~/.pi/agent/skills/tasks/tasks.py <path> set <task-key> done
```

### 7. Loop

After completing a batch, go back to step 3 to find the next ready tasks.

### 8. Final verification

When all tasks report done:

```bash
uv run ~/.pi/agent/skills/tasks/tasks.py <path> verify
```

## Task Management Reference

| Operation | Command |
|-----------|---------|
| Summary | `uv run ~/.pi/agent/skills/tasks/tasks.py <path> summary` |
| List all | `uv run ~/.pi/agent/skills/tasks/tasks.py <path> list` |
| View ready | `uv run ~/.pi/agent/skills/tasks/tasks.py <path> ready` |
| View in progress | `uv run ~/.pi/agent/skills/tasks/tasks.py <path> list --status progress` |
| Mark in progress | `uv run ~/.pi/agent/skills/tasks/tasks.py <path> set KEY progress` |
| Mark done | `uv run ~/.pi/agent/skills/tasks/tasks.py <path> set KEY done` |
| Verify all done | `uv run ~/.pi/agent/skills/tasks/tasks.py <path> verify` |

## Error Handling

- **Task fails**: Leave status as `"progress"`, report the error, allow user to retry
- **No ready tasks but not all done**: Report which tasks are blocking and why
- **Missing dependency**: Report which upstream tasks need to complete first
- **Missing detail file**: Proceed using only the task description and PRD context

## Output Format

```
✓ Loaded tasks.yaml (X tasks)
  - Done: Y
  - In Progress: Z
  - Open: W

▶ Ready: task-name-1 (no deps)
▶ Ready: task-name-2 (no deps)

[Implementing...]

✓ task-name-1 complete
  Modified: src/foo.ts, src/bar.ts

✓ task-name-2 complete
  Created: src/baz.ts

▶ Ready: task-name-3 (depends: task-name-1, task-name-2 ✓)

[...]

✓ All tasks complete!
```
