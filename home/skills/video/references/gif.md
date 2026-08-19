# Demo GIF reference

Use this for README-ready app demos and screen recordings.

## Plan

1. Find how to run the app.
2. Start the app in the background.
3. Confirm it responds with `curl`.
4. Read source for stable routes, selectors, and shortcuts.
5. Plan 3 to 6 beats.
6. Keep total runtime between 10 and 25 seconds.

## Record

Use a throwaway workspace outside the app repo:

```bash
mkdir -p /tmp/gif-demo && cd /tmp/gif-demo && npm init -y && npm i playwright-core
```

Use `playwright-core` with the system Chromium executable.

On NixOS, do not rely on downloaded Playwright browsers.

Use these defaults:

- `deviceScaleFactor: 2`
- dark mode when the app supports it
- caption overlay for each beat
- natural typing delays
- cleanup in `finally`

## Convert

Use full ffmpeg:

```bash
ffmpeg -i recording.webm \
  -vf "fps=10,split[s0][s1];[s0]palettegen=max_colors=256[p];[s1][p]paletteuse" \
  demo.gif -y
```

Keep the GIF under 10 MB when possible.

## Verify

Extract and inspect key frames with the Read tool.

Check that:

- the feature is visible;
- captions are readable;
- no private data is visible;
- the final GIF opens correctly.

Embed the GIF near the top of the README.
