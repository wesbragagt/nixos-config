---
name: log-improve
description: Review and improve backend application logging by reducing noise, correcting log levels, improving structured context, and preserving important business milestones.
argument-hint: "[scope: path, module, service, or PR — defaults to current working area]"
disable-model-invocation: true
---

# Improve Application Logging

Review and improve logging in the requested scope:

**Scope:** `$ARGUMENTS`

If no scope is provided, inspect the relevant codebase or current working area.

## Goal

Reduce log noise while preserving the logs needed to:

* debug production issues
* understand workflow progress
* investigate failures
* track important business milestones
* correlate work across requests, jobs, messages, and entities

Do not change application behavior.

## Orient First

Before editing anything, learn how this project logs:

* Identify the logging library and idiom (e.g. `slog`, `logrus`, `zap`, `winston`, `pino`, `console.*`, `logging`, `log4j`, `serilog`, framework loggers).
* Learn its level vocabulary. Map the principles below onto whatever levels the project actually uses — do not impose `ERROR/WARN/INFO/DEBUG/TRACE` if the project uses a different set.
* Learn its structured-field style and existing event/field naming conventions.
* Find the logging calls with a targeted search across the scope, e.g. grep for the logger name, `log.`, `logger.`, `console.`, `slog.`, or the project's wrapper — then read the surrounding workflow before touching any call.

## Principles

### Log meaningful events

Keep logs for:

* request, job, and message boundaries
* important workflow transitions
* business milestones
* external dependency failures
* database failures
* retries and degraded behavior
* final failures

Remove or downgrade logs that only narrate:

* function entry or exit
* normal branch execution
* per-row or per-item progress
* empty polling loops
* routine health checks
* repetitive successful operations

Prefer fewer, richer logs over many small logs.

### Use levels correctly

* `ERROR`: unexpected failures, retries exhausted, failed jobs, outages, invariant violations, or data-loss risk
* `WARN`: unexpected but recoverable states, degraded behavior, retries, partial failures, or meaningful slowness
* `INFO`: important lifecycle events, workflow boundaries, and business milestones
* `DEBUG`: implementation details useful for targeted debugging
* `TRACE`: highly verbose internals, when supported

Do not log expected behavior as errors.

### Avoid duplicate error logging

Do not log and rethrow the same failure at multiple layers.

Prefer logging the final failure at the operational boundary, such as:

* request handler
* job runner
* queue consumer
* CLI command
* scheduled task

Lower layers should add context without repeatedly emitting the same error.

### Prefer structured logs

Use stable event names and structured context.

Examples:

* `job_started`
* `job_completed`
* `job_failed`
* `message_processing_failed`
* `external_api_call_failed`
* `database_query_slow`

Preserve useful identifiers when available:

* `requestId`
* `traceId`
* `correlationId`
* `jobId`
* `brandId`
* `ingestionId`
* `invoiceNumber`
* `runId`
* `durationMs`
* `rowCount`
* `statusCode`
* `retryAttempt`

Follow the project's existing logging conventions and field naming style.

### Do not use logs as metrics

Avoid high-frequency logs for counts, throughput, latency, queue depth, or routine success.

Prefer metrics when available. Otherwise, emit a single summary log at the relevant workflow boundary.

### Protect sensitive data

Never add logging for:

* passwords
* tokens
* API keys
* authorization headers
* secrets
* payment data
* unnecessary PII
* full payloads or files containing sensitive data

Use safe identifiers, counts, and summaries instead.

## Business Milestone Gate

Do not assume a domain-specific log is noise.

Before removing or downgrading a log, determine whether it may represent an important business or operational milestone.

Be especially careful with:

* customer-visible progress
* billing and invoices
* reconciliation
* payments
* orders and shipments
* ingestion and data processing
* reporting and data quality
* feature flag decisions
* migrations and canary paths
* background job transitions
* auditability
* operator-facing production checkpoints

When clearly important, preserve and improve the log.

When clearly implementation noise, change it.

**When genuinely unsure, stop and ask for clarification before changing that log.**

Group related ambiguities into one concise question whenever possible.

Use this format:

> I found a log that may be either implementation noise or an important business milestone.
>
> **Location:** `<file/function>`
> **Current log:** `<level> <message>`
> **Why it may be noise:** `<reason>`
> **Why it may be important:** `<reason>`
> **Recommendation:** `<keep, remove, downgrade, upgrade, sample, or restructure>`
>
> Should this be treated as an important milestone?

Continue with unambiguous cleanup while awaiting clarification only when the workflow allows it. Do not modify the ambiguous log until its purpose is clear.

## Workflow

1. Orient (see above): inspect the scope, the logging library, and existing conventions.
2. Find logging calls and understand the surrounding workflow before editing.
3. Identify:

   * noisy `INFO` logs
   * expected behavior logged as `WARN` or `ERROR`
   * duplicate exception logs
   * per-row, per-item, and per-loop logs
   * inconsistent event names
   * missing correlation context
   * sensitive data exposure
4. Separate obvious cleanup from ambiguous business milestones.
5. Ask concise clarification questions only for genuinely ambiguous milestones.
6. Make targeted changes.
7. Run relevant formatting, type checks, and tests.
8. Review the diff to verify no application behavior changed.

## Constraints

* Do not change business logic, retry behavior, or error-handling semantics.
* Do not change API responses, queries, or workflow order.
* Do not silently suppress failures or remove the only visibility into failed background work.
* Do not invent new logging infrastructure unless necessary.
* Do not perform broad unrelated refactors.
* Do not blindly convert every message to a new event naming convention.
* Preserve useful context while reducing volume.

## Final Report

Summarize:

### Changed

* logs removed or downgraded
* levels corrected
* duplicate errors eliminated
* structured context improved
* sensitive or excessive payload logging removed

### Preserved

* important business milestones intentionally kept

### Clarified

* business milestone decisions confirmed by the user

### Follow-up

* worthwhile metrics, sampling, correlation, or logging infrastructure improvements not included in this cleanup

Keep the report concise and reference specific files.
