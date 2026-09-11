---
name: tasks
description: Break down a feature into tasks using the to-spec skill
argument-hint: <spec-path-or-description> [--name <feature-name>]
---

Break down a feature into actionable tasks with dependencies using the `to-spec` skill.

## Usage

/tasks <spec-path-or-description> [--name <feature-name>]

## Parameters

- `spec-path-or-description`: Either a file path to an existing `spec.md` (or legacy `prd.md`), or a description string (required)
- `--name`: Optional feature name (auto-generated from first 4 words if not provided)

## Examples

/tasks .specs/authentication/spec.md
/tasks "Build user authentication with OAuth2 and JWT"
/tasks ./features/search.md --name search-feature
/tasks "Add real-time notifications with websockets" --name realtime-notif

## Implementation

1. Parse input:
   - If input is a file path that exists: read contents as the spec
   - Otherwise: use input string as feature description

2. Generate feature name if not provided:
   - Use first 4 words, lowercase, hyphenated
   - Example: "Build user authentication system" → "build-user-auth-system"

3. Invoke the `to-spec` skill with:
   - feature-name: <name or generated>
   - description: <description from input or spec summary>
   - context: <full spec content if from file>

4. The `to-spec` skill produces:
   - `spec.md` with problem, scope, requirements, and acceptance criteria
   - `tasks.yaml` with dependency-ordered tasks
   - one standalone task packet per task

## Task YAML Spec

```yaml
tasks:
  - key: task-name          # Unique kebab-case identifier
    description: Brief description of the task
    details: ./task-name.md # Path to detail file with implementation notes
    status: open            # open, progress, or done
    depends: []             # List of task keys this depends on
```

## Output

```
✓ Tasks created: .specs/{feature-name}/
  - spec.md
  - tasks.yaml (X tasks)
  - {X} task packets

Tasks:
  1. task-name-1 (no deps)
  2. task-name-2 (depends: task-name-1)
  ...
```

Use the `tasks` skill for managing tasks.yaml files (view, update status, verify completion).
