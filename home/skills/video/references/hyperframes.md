# HyperFrames reference

HyperFrames renders video from HTML.

Use it for video compositions, animation, captions, overlays, preview, render,
publish, and diagnostics.

## Start from project state

Use the first matching state.

1. If the user asks for a specific operation, do only that operation.
2. If the user asks for a specific edit, make that edit and rerun affected checks.
3. If `BRIEF.md` exists, read it and follow its workflow and flow.
4. If `hyperframes.json` or `STORYBOARD.md` exists, resume from project files.
5. For fresh creation, capture intent and write `BRIEF.md` before building.

## Keep the CLI current

Before the first render-affecting command in an existing project, run:

```bash
npx hyperframes@latest upgrade --project . --check
```

If it reports an old pin, run:

```bash
npx hyperframes@latest upgrade --project .
npx hyperframes check
```

If check fails, revert the pin change and report the reason.

## Build order

1. Confirm brief and route.
2. Resolve design truth: `frame.md`, `design.md`, or `DESIGN.md`.
3. Plan the viewer arc, scenes, rhythm, and duration.
4. Resolve required media and audio.
5. Build scenes with deterministic, seek-safe timelines.
6. Assemble captions, transitions, media, and audio.
7. Run validation.
8. Preview before render.
9. Render only after approval, unless the user explicitly asked for autonomous render.

## Composition contract

- Timed elements use `class="clip"`.
- The root and relevant ancestors have explicit size.
- The composition registers one paused, seek-safe timeline on `window.__timelines`.
- Do not use render-time network fetches.
- Do not use clocks or unseeded randomness.
