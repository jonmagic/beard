# Beard Agent Guide

These instructions apply to the whole repository unless a deeper `AGENTS.md` overrides them. The closest `AGENTS.md` wins.

## Mission

Build a local macOS CLI that samples per-app/process energy signals and suggests concrete actions to prolong battery life.

## Start Here

1. Read `README.md` and the nearest `AGENTS.md` before making changes.
2. Check `git status --short` before editing.
3. Preserve user edits. Never reset, checkout, or overwrite dirty files unless explicitly asked.
4. Prefer project skills in `.github/skills/` for reusable workflows and domain guidance.

## Non-negotiables

1. Do not estimate timelines unless the user explicitly asks.
2. Use red-green-refactor wherever practical.
3. Keep docs close to behavior and update them in the same slice.
4. Ask before destructive or irreversible changes, adding secrets, widening privileges, publishing, purchasing, or making external side effects.
5. Prefer quality over speed. Use critical review for changes with meaningful security, privacy, data-handling, architecture, production, or product-risk consequences.

## Development Harness

Tooling: Swift Package Manager

Commands:

1. Test: `swift test`
2. Build: `swift build`
3. Help smoke check: `swift run beard --help`
4. Version smoke check: `swift run beard --version`
5. Report smoke check: `swift run beard report --limit 5`
6. Package signed local release: `scripts/package-release`
7. Package notarized installer release: `scripts/package-notarized-pkg`
8. Install 15-minute relay updates: `scripts/install-launch-agent`
9. Uninstall relay updates: `scripts/uninstall-launch-agent`

There is no separate lint or formatter command wired in this repo yet.

## ZShot Visual Harness

Use ZShot for browser-backed captures when visual output, rendered HTML, page state, diagnostics, or agent-readable snapshots would improve confidence. On jonmagic's Mac, the bundled CLI is usually available at `~/Library/Application Support/ZShot/zshot`; discover capabilities with `zshot --agent-help`, `zshot --help`, and `zshot --help all`.

Recommended default checks:

1. Capture rendered HTML for low-friction smoke checks: `zshot -t html -f zshot-artifacts/<name>.html <url>`.
2. Use screenshots, PDF, HAR, WARC, Markdown, AXTree, trace, or pprof only when the local license supports the output type.
3. Keep generated ZShot artifacts out of commits unless they are intentional fixtures or documentation assets.
4. Do not send secrets, private app data, or sensitive URLs through third-party services for capture.

## Architecture and Boundaries

Beard is a native Swift Package Manager CLI. It uses absolute-path local macOS commands (`/usr/bin/pmset`, `/usr/bin/top`, `/bin/ps`) through `Process` argument arrays, never shell interpolation.

The CLI intentionally stays unprivileged. It uses `top` relative power and CPU counters rather than admin-only `powermetrics`, so reports must not claim exact per-app watts or watt-hours.

Output can include local process names and PIDs. Keep reports local unless jonmagic explicitly asks to save or share them.

The launchd relay runner no-ops on AC Power. On battery power, it sends Beard JSON output through the configured `llm` CLI and then enqueues a Tri-State Relay Service message. Treat that as an intentional user-approved external/model boundary, keep `llm --no-log`, and avoid adding raw report dumps to relay messages.

The relay runner writes only a capped local log at `~/Library/Logs/beard/battery-relay.log`; do not add unbounded persisted state for scheduled battery data.

The launchd job uses `.build/release/beard`; rebuild or rerun `scripts/install-launch-agent` after source changes so scheduled output matches the latest code.

`VERSION` and `Sources/beard/Version.swift` must stay aligned for releases. `scripts/package-release` builds, signs, verifies, and writes the local zip archive under `dist/`. `scripts/package-notarized-pkg` builds, signs, notarizes, staples, validates, and writes the Gatekeeper-friendly installer package under `dist/`.

## Agent Workflow

- Make focused, reviewable slices.
- Use direct tools for bounded search, reads, and small edits.
- Add or update project skills only when repeated workflows justify a routing-friendly skill.
- Use red-green-refactor where practical: write or identify the failing expectation first, make the smallest working change, then clean up while preserving behavior.
- Rubber-duck high-stakes or ambiguous work before treating the direction as settled, especially around security, privacy, data handling, external services, persistence, deployment, permissions, or broad architecture.
- If an agent miss happens, improve the durable harness with the smallest useful artifact: instructions, docs, scripts, tests, or guardrails.
- Leave the repo easier for the next agent: capture newly discovered commands, constraints, validation steps, and project-specific gotchas in the closest durable file.

## Task Exit Criteria

1. Closest available validation passes.
2. Behavior is verified automatically or manually.
3. Documentation is updated when commands, behavior, workflow, or constraints change.
4. Handoff names changed files and remaining risks.

## Ask First

Ask before:

- touching broad or unrelated areas of the repo
- introducing a new framework, background worker, MCP server, queue, or sub-agent layer
- changing persistence, permissions, authentication, authorization, billing, or deployment behavior
- committing or pushing if the user has not asked for it in this project
