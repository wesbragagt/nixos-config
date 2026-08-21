---
name: ccflare-insights
description: Analyze local better-ccflare usage, agent efficiency, token spend, cache use, and request anomalies. Use when the user asks about ccflare usage, agent efficiency, token cost, cache behavior, or request anomalies.
argument-hint: "[context] [range: 1h|6h|24h|7d|30d; default 7d]"
---

# better-ccflare Insights

Give advisory-only, evidence-based advice from the local better-ccflare Insights API.

Do not change proxy settings, headers, agent front matter, preferences, accounts, models, retention, or request records.

## Parse the request

Accept this syntax only:

```text
ccflare-insights [context] [1h|6h|24h|7d|30d]
```

- Default `RANGE` to `7d`.
- Accept each token at most once.
- `context` opts in to payload-derived context analysis.
- Reject all other input. Print the accepted syntax and stop.
- Set `CONTEXT=false` unless the user included the exact `context` token in this request.

Set the endpoint and time window:

```bash
BASE_URL=https://ccflare.localhost
case "$RANGE" in
  1h|6h|24h|7d|30d) ;;
  *) printf '%s\n' 'Accepted syntax: ccflare-insights [context] [1h|6h|24h|7d|30d]' >&2; exit 2 ;;
esac
case "$RANGE" in
  1h) WINDOW_SECONDS=3600 ;;
  6h) WINDOW_SECONDS=21600 ;;
  24h) WINDOW_SECONDS=86400 ;;
  7d) WINDOW_SECONDS=604800 ;;
  30d) WINDOW_SECONDS=2592000 ;;
esac
WINDOW_START=$(date -u -d "-$WINDOW_SECONDS seconds" +%Y-%m-%dT%H:%M:%SZ)
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
```

## Check service health

Run this command first. Do not send credentials.

```bash
curl --insecure --fail --silent --show-error "$BASE_URL/health" >"$TMPDIR/health.json"
```

If curl fails, report its exact connection error and stop. If `.status` is not `"ok"`, report the returned health state and stop. Do not use another host or port.

## Collect safe data

Use only read-only `GET` requests. Save response bodies in `$TMPDIR`; never print raw JSON.

```bash
curl --insecure --fail --silent --show-error "$BASE_URL/api/requests?limit=1000" >"$TMPDIR/requests.json"
curl --insecure --fail --silent --show-error "$BASE_URL/api/analytics?range=$RANGE" >"$TMPDIR/analytics.json"
```

Then collect these independent Insight endpoints. Continue if either one is unavailable. Record its curl error as endpoint unavailability, not as a request failure metric.

```bash
curl --insecure --fail --silent --show-error "$BASE_URL/api/insights/cache?range=$RANGE" >"$TMPDIR/cache.json"
curl --insecure --fail --silent --show-error "$BASE_URL/api/insights/anomalies?range=$RANGE" >"$TMPDIR/anomalies.json"
```

Never call `POST`, `PATCH`, `DELETE`, `/api/stats/reset`, `/api/requests/detail`, or any endpoint not listed here.

Only when `CONTEXT=true`, explain before the request that stored request payloads can produce contributor labels or short content previews. Then collect:

```bash
curl --insecure --fail --silent --show-error "$BASE_URL/api/insights/context?range=$RANGE" >"$TMPDIR/context.json"
```

Do not call the context endpoint without that explicit opt-in.

## Analyze request history

The request endpoint is a recent capped sample. It has no documented server-side range filter or pagination. It can miss proxy traffic.

Find the array in its response before processing. Use the timestamp field supplied by each request record. Filter the retained records locally to timestamps at or after `WINDOW_START` and before the current UTC time. Do this filtering before every agent grouping.

Report all of these values from the filtered records:

- retained-sample count and in-range count;
- attributed count and percentage;
- count by `agentAttributionSource`;
- count by `agentUsed`, with null or missing values grouped as `Unattributed`;
- for each group: request count; total, input, output, cache-read, and cache-creation tokens; `costUsd`; model distribution; mean latency; p95 latency; mean non-null `tokensPerSecond`; failover count; HTTP failure count; stream outcomes; and cancellation count.

Use field names present in the response. Treat absent numeric values as unknown, not zero. Do not calculate a mean from null values. Calculate p95 from the sorted numeric latency observations by nearest-rank: `ceil(0.95 * n)`, minimum rank one.

Classify streaming `complete` and `recovered` as completed. Show all other returned stream outcomes by name. Count cancellations only from explicit cancellation fields or a returned cancellation outcome. Count HTTP failures only from explicit HTTP status or failure fields. Do not treat unavailable endpoint calls as HTTP failures.

Keep `header_agent`, `prompt_agent`, and `session_header` separate when they occur. A header- or prompt-derived `agentUsed` value is the report label. A session-header value is not a configured agent identity. Replace each distinct session-header value with a stable per-report label such as `Session agent 1`; never print the underlying value. Render null as `Unattributed`.

Never print prompts, response bodies, error text, request IDs, session IDs, account identifiers, project names, hashes, contributor labels, or raw JSON. Use generic labels or user-approved names for all identifiers.

## Apply coverage rules

Put coverage and uncertainty beside every finding.

- Mark the sample incomplete if it contains 1,000 records or its oldest retained timestamp is newer than `WINDOW_START`.
- State that rankings are unavailable when the sample is incomplete.
- State that comparisons are unavailable when either compared group has fewer than 10 in-range requests.
- State that missing `agentUsed` data means attribution is incomplete.
- Do not infer a configured agent name from `agentUsed`; this is required for `session_header` values.
- When attribution is below 90%, recommend a stable, low-cardinality `x-better-ccflare-agent-id` header. State that `x-anthropic-agent-id` is the legacy fallback. Do not recommend task text, prompt content, high-cardinality values, or session identifiers.

## Analyze shared endpoints

Use aggregate endpoints only within their documented dimensions.

From analytics, report window totals, token breakdown, model performance, and model cost. Do not derive per-agent values from analytics.

From cache Insights, report:

- global cache hit rate;
- cache-read, cache-creation, and uncached tokens;
- savings only when `pricingKnown` is true;
- unknown-priced models;
- low-hit rows from returned `byModel`, `byAccount`, or `byProject` dimensions.

Cache data is shared, not per-agent. Never attribute cache savings or a cache hit rate to an `agentUsed` group. Redact account and project identifiers with generic labels.

From anomaly Insights, report detector metadata, detector total counts, truncation state, and aggregate severity details only. Associate a runaway-loop event with an agent only when its returned `agentUsed` is non-null. Report other anomaly types only at account, project, model, or global scope, with identifiers redacted. Do not expose per-request anomaly details.

When `CONTEXT=true`, the context request is mandatory. Do not state or imply that it was not called. In `Shared proxy insights`, include an explicit `Context analysis (opted in)` item with only its `meta`, composition totals, token totals, payload coverage, and counts. If this endpoint is unavailable, state `Context analysis (opted in): unavailable` with a generic endpoint-unavailable notice.
Report only `meta`, composition totals, token totals, payload coverage, and counts. Do not print `topContributors` labels, hashes, per-request entries, growth-curve request IDs, prompts, responses, or stored error text. State that context estimates use an approximate four-characters-per-token heuristic. State that stored payload coverage can be partial.
For each returned runaway-loop event with non-null `agentUsed`, use its safe report label in the aggregate anomaly statement. Do not omit the association.

## Report format

Use exactly these sections and no raw data appendix:

```text
Scope & coverage
Agent usage
Shared proxy insights
Findings
Suggestions
Data limits
```

Keep the report concise. Give every finding its source, range, sample size, and coverage state. Mark unavailable endpoints as unavailable and omit suggestions that depend on them.
Do not give a conditional or speculative suggestion. In particular, include an attribution suggestion only when measured attribution is below 90%.
In `Agent usage`, print one complete metric row for every observed safe group, including groups with fewer than 10 requests. Each row must name every required request metric. Render a missing metric as `unknown`; do not shorten, omit, or replace the row with a summary. The 10-request rule prohibits comparisons only. It does not remove reporting requirements.

Rank suggestions by expected impact. Include a suggestion only for a measured condition. Use only these suggestion classes:

1. improve attribution coverage;
2. reduce error, truncation, or failover rate;
3. investigate a detector finding;
4. select a lower-cost adequate model after a stable 10-request comparison;
5. reduce input/context or output volume;
6. improve cache reuse;
7. split or constrain a confirmed runaway loop.

For every suggestion, state the metric evidence, affected safe label or model, expected benefit, and one concrete next action. If sample volume is insufficient or an endpoint is unavailable, state that no recommendation is supported.
