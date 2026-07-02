# Dispatch Rules

## Loops and Monitors Use Sonnet

When dispatching work via loops (`/loop`, `ScheduleWakeup`) or monitors (the `Monitor` tool), always use the Sonnet model.

- Pass the Sonnet model explicitly when the dispatch mechanism accepts a model override.
- This applies to the recurring/polling iterations themselves and to any agents they spawn.
- Reserve more capable models for interactive, one-off work — recurring loop and monitor iterations should default to Sonnet.
