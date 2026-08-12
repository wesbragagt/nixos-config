---
name: browser
description: This skill should be used when the user needs to automate browser interactions, test UI workflows, verify page elements, take screenshots, upload files to forms, or interact with web applications during development and debugging. Use this skill for testing PDF upload dialogs, form interactions, dropdown selections, and visual verification of web pages.
version: 1.0.0
---

# Agent Browser Skill

Automate browser interactions for UI testing, debugging, and development iteration using the agent-browser automation tool.

## Overview

This skill enables interactive browser automation directly from the agent, allowing you to:
- Launch browsers and navigate to URLs
- Inspect and interact with page elements
- Verify UI state and extract information
- Test workflows like form submissions and file uploads
- Take screenshots for visual verification

## When This Skill Applies

This skill activates when you need to:
- **Test UI components** - Verify buttons, forms, dropdowns work correctly
- **Inspect page structure** - Examine DOM elements and their properties
- **Automate workflows** - Click, fill, and submit forms programmatically
- **Upload files** - Test file inputs and upload flows
- **Verify visual state** - Take screenshots at different stages
- **Debug page issues** - Check element visibility, attributes, content

## Agent-Browser CLI Reference

```
agent-browser - fast browser automation CLI for AI agents

Usage: agent-browser <command> [args] [options]

Core Commands:
  open <url>                 Navigate to URL
  click <sel>                Click element (or @ref)
  dblclick <sel>             Double-click element
  type <sel> <text>          Type into element
  fill <sel> <text>          Clear and fill
  press <key>                Press key (Enter, Tab, Control+a)
  hover <sel>                Hover element
  focus <sel>                Focus element
  check <sel>                Check checkbox
  uncheck <sel>              Uncheck checkbox
  select <sel> <val...>      Select dropdown option
  drag <src> <dst>           Drag and drop
  upload <sel> <files...>    Upload files
  scroll <dir> [px]          Scroll (up/down/left/right)
  scrollintoview <sel>       Scroll element into view
  wait <sel|ms>              Wait for element or time
  screenshot [path]          Take screenshot
  pdf <path>                 Save as PDF
  snapshot                   Accessibility tree with refs (for AI)
  eval <js>                  Run JavaScript
  connect <port>             Connect to browser via CDP
  close                      Close browser

Navigation:
  back                       Go back
  forward                    Go forward
  reload                     Reload page

Get Info:  agent-browser get <what> [selector]
  text, html, value, attr <name>, title, url, count, box, styles

Check State:  agent-browser is <what> <selector>
  visible, enabled, checked

Find Elements:  agent-browser find <locator> <value> <action> [text]
  role, text, label, placeholder, alt, title, testid, first, last, nth

Mouse:  agent-browser mouse <action> [args]
  move <x> <y>, down [btn], up [btn], wheel <dy> [dx]

Browser Settings:  agent-browser set <setting> [value]
  viewport <w> <h>, device <name>, geo <lat> <lng>
  offline [on|off], headers <json>, credentials <user> <pass>
  media [dark|light] [reduced-motion]

Network:  agent-browser network <action>
  route <url> [--abort|--body <json>]
  unroute [url]
  requests [--clear] [--filter <pattern>]

Storage:
  cookies [get|set|clear]    Manage cookies
  storage <local|session>    Manage web storage

Tabs:
  tab [new|list|close|<n>]   Manage tabs

Debug:
  trace start|stop [path]    Record trace
  record start <path> [url]  Start video recording
  record stop                Stop and save video
  console [--clear]          View console logs
  errors [--clear]           View page errors
  highlight <sel>            Highlight element

Sessions:
  session                    Show current session name
  session list               List active sessions

Snapshot Options:
  -i, --interactive          Only interactive elements
  -c, --compact              Remove empty structural elements
  -d, --depth <n>            Limit tree depth
  -s, --selector <sel>       Scope to CSS selector

Options:
  --session <name>           Isolated session
  --headers <json>           HTTP headers for auth
  --executable-path <path>   Custom browser executable
  --json                     JSON output
  --full, -f                 Full page screenshot
  --headed                   Show browser window
  --debug                    Debug output

Examples:
  agent-browser open example.com
  agent-browser snapshot -i              # Interactive elements
  agent-browser click @e2                # Click by ref
  agent-browser fill @e3 "test@example.com"
  agent-browser screenshot --full
```

## Quick Examples

**Open a page and take screenshot:**
```bash
agent-browser open http://localhost:3000/instructions
agent-browser screenshot
```

**Click an element:**
```bash
agent-browser click "button[data-testid='submit']"
```

**Fill an input field:**
```bash
agent-browser fill "input[name='email']" "user@example.com"
```

**Select from dropdown:**
```bash
agent-browser select "select[name='biller']" "XPO Logistics"
```

**Take a snapshot (for AI):**
```bash
agent-browser snapshot --interactive
```

**Wait for element:**
```bash
agent-browser wait "div.success-message"
```

**Upload a file:**
```bash
agent-browser upload "input[type='file']" "~/Downloads/invoice.pdf"
```

## Common Workflows

### Testing a Form Workflow

```bash
# 1. Navigate to the page
agent-browser open http://localhost:3000/form

# 2. Click button
agent-browser click "button:has-text('Submit')"

# 3. Fill form fields
agent-browser fill "input[name='name']" "Test Name"
agent-browser fill "textarea[name='desc']" "Description text"

# 4. Select dropdown
agent-browser select "select[name='option']" "Option Value"

# 5. Submit form
agent-browser click "button[type='submit']"

# 6. Verify success
agent-browser wait ".success-toast"
agent-browser screenshot
```

### Debugging Page State

```bash
# Open page with issues
agent-browser open http://localhost:3000/page

# Snapshot to understand structure
agent-browser snapshot -i

# Take screenshots
agent-browser screenshot

# Check element state
agent-browser is visible "button[type='submit']"
```

### Complete Feature Test

```bash
# Phase 1: Setup
agent-browser open http://localhost:3000/feature

# Phase 2: Verify UI loaded
agent-browser snapshot -i
agent-browser screenshot

# Phase 3: Test interaction
agent-browser click "button:has-text('Action')"
agent-browser screenshot

# Phase 4: Verify result
agent-browser wait ".result-element" --timeout 30000
agent-browser screenshot
agent-browser get text ".result-element"
```

## Tips & Best Practices

1. **Always start with `open`** - Initialize the browser session before other commands
2. **Use specific selectors** - Prefer `data-testid` attributes over generic selectors
3. **Check screenshots between steps** - Verify page state after interactions
4. **Increase timeout for slow operations** - Some operations may need 30-60 seconds
5. **Use snapshot to understand page structure** - Before clicking/filling, inspect the element
6. **Handle async operations** - Use `wait` for dynamically loaded content
7. **Use text matching for buttons** - `button:has-text('Submit')` is often more reliable

## Troubleshooting

**Element not found:**
- Check the selector syntax
- Use `snapshot` to understand the page structure
- Try text matching instead of specific selectors

**Click/fill not working:**
- Ensure element is visible and clickable
- Check if element requires scrolling into view
- Verify element is not disabled or hidden

**Timeout waiting for element:**
- Increase the timeout value
- Check console for JavaScript errors
- Use `screenshot` to see current page state

**File upload fails:**
- Verify file path exists (use absolute or ~/ paths)
- Check file input accepts the file type
- Ensure upload input is visible and accessible
