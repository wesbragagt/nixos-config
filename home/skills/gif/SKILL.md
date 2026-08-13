---
name: gif
description: Record a polished demo GIF of an app's functionality by scripting a browser session with Playwright, converting to an optimized GIF, and embedding it in the README. Use when the user wants a demo GIF/video/screen recording of an app or feature for a README or docs.
argument-hint: "[feature(s) to demo, e.g. 'live reload and search']"
---

# gif — record a demo GIF of an app

Produce a README-ready GIF that demos app functionality: script a headless
browser session with narration captions, record it as video, convert to an
optimized GIF, verify it frame-by-frame, and embed it.

**Why GIF, not video:** GitHub only inline-plays videos uploaded as
attachments through its web editor (`user-attachments` URLs). A video file
committed to the repo renders as a click-through link. GIFs committed to the
repo render inline. Always deliver a GIF unless told otherwise.

## Step 1: Understand the app and plan the beats

- Find how to run the app (`package.json` scripts, README, Procfile) and
  start it in the background. Confirm it responds with `curl` before
  recording.
- Read enough source to script interactions reliably: URL paths, element
  selectors, keyboard shortcuts. Grep for the feature's client code rather
  than guessing selectors.
- Plan the demo as 3–6 "beats", each with a caption and an action:
  show → announce what's about to happen → do it → show the result.
  Keep total runtime 10–25 seconds. If demoing multiple features, chain
  them in one recording.

## Step 2: Record with Playwright

Set up a throwaway workspace (never inside the app repo):

```bash
mkdir -p /tmp/gif-demo && cd /tmp/gif-demo && npm init -y && npm i playwright-core
```

Copy `record.template.mjs` from this skill's directory as a starting point
and adapt it. Non-negotiables baked into the template:

- **`playwright-core` + the system Chromium executable** (`which chromium`).
  On NixOS, Playwright's downloaded browsers won't run; the system browser
  always does. Video recording uses the ffmpeg in `~/.cache/ms-playwright/`
  — if absent, `npx playwright install ffmpeg`.
- **`deviceScaleFactor: 2`** — text is noticeably crisper in the output.
- **`colorScheme: 'dark'`** if the app supports it — light-mode recordings
  read as harsh and washed out in READMEs.
- **Caption overlay** injected via `page.evaluate` narrates each beat so the
  GIF is self-explanatory without audio.
- **Restore all state in `finally`** — if the demo edits files on disk,
  keep the original content and write it back even on failure.

Gotchas that will bite you:

- Never call `caption()` (or any `page.evaluate`) while a navigation is in
  flight — "Execution context was destroyed". After pressing Enter on a
  link/result, `await page.waitForURL(/expected/, { waitUntil: 'networkidle' })`
  first.
- Search palettes and lists often auto-select the first result; pressing
  ArrowDown before Enter selects the *second*. Verify with a trial run.
- Use `pressSequentially(text, { delay: 150-200 })` for typing so it reads
  naturally at GIF frame rates.

## Step 3: Convert to GIF

Playwright outputs webm. Its bundled ffmpeg has no mp4/gif muxers — use a
full ffmpeg (`nix run nixpkgs#ffmpeg --`, or system ffmpeg):

```bash
ffmpeg -i recording.webm \
  -vf "fps=10,split[s0][s1];[s0]palettegen=max_colors=256[p];[s1][p]paletteuse" \
  demo.gif -y
```

Keep full resolution and 256 colors — downscaling or `max_colors=128` with
bayer dithering makes text blurry. At 1280×720/10fps expect ~200KB per
second of runtime; stay under ~10MB or GitHub won't render it.

## Step 4: Verify before shipping

Extract 2–3 frames at the key beats and **look at them with the Read tool**:

```bash
ffmpeg -ss <seconds> -i recording.webm -frames:v 1 /tmp/frame.png -y
```

Check: the demoed change is actually visible, captions are readable and not
covered, dark mode applied, nothing embarrassing in frame (dev toolbars,
personal data). Also Read the final GIF itself — it renders its first frame.
Re-record until right; never ship an unverified GIF.

## Step 5: Embed and clean up

- Put the GIF in the repo's screenshot/asset location if one exists (e.g.
  `.github/`), else create `.github/`.
- Embed as an image near the top of the README:
  `![<what the demo shows>](.github/demo.gif)`
- Kill the dev server, confirm `git status` shows only the GIF + README
  (recording must not leave app files modified), and offer to commit.
