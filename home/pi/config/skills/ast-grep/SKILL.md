---
name: ast-grep
description: "AST-based code search and rewrite using ast-grep (sg). Use for structural code search, pattern matching, or automated refactoring across files. Examples: find all console.log calls, rewrite foo() to bar(), refactor optional chaining patterns."
---

# ast-grep

## Prerequisites

Install if not present:
```bash
npm install -g @ast-grep/cli
```

Binary is `ast-grep` (aliased as `sg`). Verify: `ast-grep --version`.

## Rules

1. Use ast-grep for **structural** code search — it matches AST nodes, not text
2. Use `read`/`grep` for simple text search; use ast-grep when you need to match code structure
3. Always specify `--lang` (`-l`) when the file extension doesn't auto-detect
4. Use single quotes around patterns to prevent shell `$` interpolation
5. Test patterns with `--debug-query` if results look wrong
6. Use `-U` (update-all) only when confident; prefer `-i` (interactive) for rewrites

## Command Selection

| Goal | Command |
|------|---------|
| Search for a code pattern | `ast-grep -p 'PATTERN' -l LANG [PATHS]` |
| Search + rewrite in one pass | `ast-grep -p 'PATTERN' -r 'REPLACEMENT' -l LANG` |
| Interactive rewrite (confirm each) | `ast-grep -p 'PATTERN' -r 'REPLACEMENT' -l LANG -i` |
| Apply all rewrites | `ast-grep -p 'PATTERN' -r 'REPLACEMENT' -l LANG -U` |
| Scan with YAML rules | `ast-grep scan -r rules.yml [PATHS]` |
| Debug a pattern's AST | `ast-grep -p 'PATTERN' -l LANG --debug-query ast` |
| JSON output for scripting | `ast-grep -p 'PATTERN' -l LANG --json=stream` |

## Language Short Codes

Common values for `--lang` (`-l`):

| Language | Flag |
|----------|------|
| TypeScript | `-l ts` |
| TSX | `-l tsx` |
| JavaScript | `-l js` or `-l javascript` |
| Python | `-l py` or `-l python` |
| Java | `-l java` |
| Kotlin | `-l kt` or `-l kotlin` |
| Rust | `-l rs` or `-l rust` |
| Go | `-l go` |
| C/C++ | `-l c` / `-l cpp` |
| HTML | `-l html` |
| CSS | `-l css` |
| JSON | `-l json` |
| YAML | `-l yaml` |

Full list: https://ast-grep.github.io/reference/languages.html

## Pattern Syntax

Patterns are **valid code** with optional meta-variables. Think of patterns like code that matches code with the same structure.

### Meta Variables

| Syntax | What it matches | Example |
|--------|----------------|---------|
| `$NAME` | Any single AST node | `$FUNC($ARGS)` matches `foo(1)`, `bar(x)` |
| `$$$NAME` | Zero or more AST nodes | `console.log($$$ARGS)` matches `console.log()`, `console.log(a, b)` |
| `$_` | Anonymous wildcard (match anything) | `$_($_)` matches any single-arg function call |

**Valid names:** `$A`, `$MY_VAR`, `$VAR1`, `$_`, `$_123`
**Invalid names:** `$lowercase`, `$kebab-case`, `$` (bare)

### Pattern Examples

```bash
# Find all console.log calls
ast-grep -p 'console.log($$$ARGS)' -l js .

# Find function declarations with any name/params/body
ast-grep -p 'function $FUNC($$$PARAMS) { $$$BODY }' -l js .

# Find all try/catch blocks
ast-grep -p 'try { $$$A } catch($E) { $$$B }' -l ts .

# Find nested optional chaining candidates: $PROP && $PROP()
ast-grep -p '$PROP && $PROP()' -l ts src/

# Find all await expressions
ast-grep -p 'await $EXPR' -l ts .

# Find if statements with empty bodies
ast-grep -p 'if ($COND) {}' -l js .

# Find specific method calls on an object
ast-grep -p '$OBJ.addEventListener($$$ARGS)' -l ts .

# Find instanceof checks
ast-grep -p '$X instanceof $TYPE' -l java .

# Find all return statements
ast-grep -p 'return $VALUE' -l py .

# Find class declarations
ast-grep -p 'class $NAME { $$$BODY }' -l ts .

# Find arrow functions
ast-grep -p '($$$PARAMS) => $BODY' -l js .
```

## Rewrite Examples

```bash
# Replace console.log with console.debug
ast-grep -p 'console.log($$$ARGS)' -r 'console.debug($$$ARGS)' -l js -U .

# Rewrite optional chaining: obj.val && obj.val() → obj.val?.()
ast-grep -p '$PROP && $PROP()' -r '$PROP?.()' -l ts -U src/

# Swap foo() calls to bar()
ast-grep -p 'foo($$$ARGS)' -r 'bar($$$ARGS)' -l js -U .

# Convert lambda to def in Python
ast-grep -p '$B = lambda: $R' -r 'def $B():\n    return $R' -l py -U .

# Add ! to non-null assertions
ast-grep -p '$OBJ.$PROP' -r '$OBJ.$PROP!' -l ts -i src/
```

## Key Options

| Flag | Description |
|------|-------------|
| `-p 'PATTERN'` | AST pattern to match |
| `-r 'REWRITE'` | Replacement string |
| `-l LANG` | Language (auto-detected from file extension if omitted) |
| `-i` | Interactive mode (confirm each change) |
| `-U` | Update all (apply without confirmation) |
| `--json=stream` | JSON output (one JSON object per line) |
| `--debug-query ast` | Show pattern's AST (debugging patterns) |
| `-C N` | Show N lines of context around matches |
| `--globs '!*.d.ts'` | Include/exclude file patterns |
| `--no-ignore hidden` | Search hidden files |

## YAML Rules (for complex/reusable patterns)

For multi-step rules or shared configurations, use YAML rule files:

```yaml
# rename-func.yml
id: rename_foo_to_bar
language: TypeScript
rule:
  pattern: foo($$$ARGS)
fix: bar($$$ARGS)
```

```bash
ast-grep scan -r rename-func.yml src/
```

Advanced rules support `kind`, `regex`, `inside`, `has`, `not`, `all`, `any`, `matches`, and more.
See: https://ast-grep.github.io/reference/rule.html

### Multi-rule file (use `---` separator)

```yaml
id: remove_console_log
language: TypeScript
rule:
  pattern: console.log($$$ARGS)
fix: ''

---

id: remove_console_warn
language: TypeScript
rule:
  pattern: console.warn($$$ARGS)
fix: ''
```

## Common Patterns

```bash
# Find all TODO/FIXME/HACK comments (regex + kind)
ast-grep scan --inline-rules 'rule: { regex: "TODO|FIXME|HACK" }' .

# Find all async functions
ast-grep -p 'async function $NAME($$$ARGS) { $$$BODY }' -l ts .

# Find all exported functions
ast-grep -p 'export function $NAME($$$ARGS) { $$$BODY }' -l ts .

# Find all imports from a specific module
ast-grep -p 'import { $$$NAMES } from "$MODULE"' -l ts .

# Find all catch blocks that swallow errors
ast-grep -p 'catch ($E) { }' -l ts .

# Find all useState hooks
ast-grep -p 'useState($INIT)' -l tsx .

# Find all useEffect with empty deps
ast-grep -p 'useEffect($CB, [])' -l tsx .

# Search only specific directories
ast-grep -p 'eval($X)' -l js src/ lib/

# Output as JSON for scripting
ast-grep -p 'console.log($$$ARGS)' -l js --json=stream . | jq '.matches[].file'

# Show 3 lines of context
ast-grep -p 'throw $ERR' -l java -C 3 src/
```

## Debugging Patterns

If a pattern doesn't match what you expect:

```bash
# See how ast-grep parses your pattern
ast-grep -p '$A + $B' -l js --debug-query ast

# See the full CST (Concrete Syntax Tree)
ast-grep -p '$A + $B' -l js --debug-query cst

# Use the playground for interactive debugging
# https://ast-grep.github.io/playground.html
```

## When to Use ast-grep vs grep

| Use ast-grep | Use grep |
|-------------|----------|
| Match code structure (functions, classes, blocks) | Match plain text/strings |
| Find all function calls regardless of formatting | Find exact string literals |
| Rename with structural awareness | Search log files, config, markdown |
| Refactor patterns across a codebase | Quick one-off searches |
| Match nested expressions | Search non-code files |
