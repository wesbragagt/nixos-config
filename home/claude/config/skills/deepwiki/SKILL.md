---
name: deepwiki
description: Ask questions about specific GitHub code repositories using DeepWiki. Use when the user asks about a repo's code, architecture, configuration, modules, APIs, examples, or behavior and provides a GitHub repository in owner/repo form or as a GitHub URL.
argument-hint: <owner/repo-or-github-url> <question>
allowed-tools: Bash(uvx ask-deepwiki ask:*)
---

# DeepWiki

Ask DeepWiki questions about a specific GitHub code repository.

Arguments: $ARGUMENTS

## Usage

```
/deepwiki <owner/repo-or-github-url> <question>
```

## Examples

```
/deepwiki panfactum/stack Is there support for configuring in the kube_pg_cluster to use on-demand nodes for primary and keep replicas on spot nodes?
/deepwiki https://github.com/panfactum/stack How is kube_pg_cluster configured?
```

## Workflow

1. Parse `$ARGUMENTS` into:
   - Repository: GitHub `owner/repo` or GitHub URL
   - Question: everything else
2. Normalize GitHub URLs to `owner/repo`.
3. If the repository is missing or ambiguous, ask the user for the exact GitHub repository.
4. If the question is missing, ask the user what they want to know about the repository.
5. Run DeepWiki:

```bash
uvx ask-deepwiki ask <owner/repo> "<question>"
```

6. Summarize the answer concisely.
7. Include relevant file paths, symbols, modules, configuration names, and caveats returned by DeepWiki.
8. If DeepWiki is inconclusive, say so clearly and recommend inspecting the repository source directly.

## Quoting

Use shell-safe quoting for the question. For questions containing double quotes or multiple lines, use a here-doc:

```bash
uvx ask-deepwiki ask <owner/repo> "$(cat <<'EOF'
<question>
EOF
)"
```

## When Not To Use

- General web research without a target GitHub repository: use research/exacli instead.
- Local codebase questions where the repository is already checked out and accessible: inspect files directly first.
- Questions containing secrets, credentials, private keys, or other sensitive content: do not send sensitive data to DeepWiki.
