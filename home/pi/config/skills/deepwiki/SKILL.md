---
name: deepwiki
description: "Ask questions about specific GitHub code repositories using DeepWiki via `uvx ask-deepwiki`. Use when the user asks about a repo's code, architecture, configuration, modules, APIs, examples, or behavior and provides a GitHub repository in `owner/repo` form."
argument-hint: <github-owner/repo> <question>
---

# DeepWiki

Use DeepWiki to answer questions about a specific code repository on GitHub.

## Command

```bash
uvx ask-deepwiki ask <owner/repo> "<question>"
```

Example:

```bash
uvx ask-deepwiki ask panfactum/stack "Is there support for configuring in the kube_pg_cluster to use on-demand nodes for primary and keep replicas on spot nodes?"
```

## Workflow

1. Identify the GitHub repository in `owner/repo` form.
   - If the user provides a GitHub URL, convert it to `owner/repo`.
   - If the user does not provide a repository, ask for it.
   - If the repo is ambiguous, ask for clarification rather than guessing.
2. Put the full user question in one shell-quoted argument.
3. Run:
   ```bash
   uvx ask-deepwiki ask <owner/repo> "<question>"
   ```
4. Summarize the answer concisely.
5. Include any file paths, symbols, modules, or configuration names returned by DeepWiki.
6. If DeepWiki says the information is missing or inconclusive, state that clearly and suggest checking the repository source directly.

## Quoting

Use double quotes for ordinary questions. If the question contains double quotes, use a here-doc to avoid broken shell quoting:

```bash
uvx ask-deepwiki ask <owner/repo> "$(cat <<'EOF'
<question>
EOF
)"
```

## When Not To Use

- General web research without a target repository: use the research/exacli workflow instead.
- Local codebase questions where the repo is already checked out and accessible: inspect files directly first.
- Secrets, credentials, or private data questions: do not send sensitive content to DeepWiki.
