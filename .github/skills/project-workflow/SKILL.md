---
name: project-workflow
description: Guides repeated Beard project workflow. Use when working in this repo, starting implementation slices, updating the project harness, or following project-specific validation and handoff steps.
---

# Beard Project Workflow

Use this skill for repeated project work that benefits from focused guidance beyond `AGENTS.md`.

## Workflow

1. Read `AGENTS.md` and any relevant local docs.
2. Check `git status --short`.
3. Identify the smallest useful slice.
4. Use red-green-refactor where practical: failing expectation, smallest working change, cleanup.
5. Make the change with nearby documentation updates.
6. Rubber-duck high-stakes or ambiguous work before treating the direction as settled.
7. Run the closest available validation.
8. Improve the harness if the work reveals a durable command, constraint, validation step, or agent gotcha.
9. Hand off changed files, validation, and remaining risks.

## Beard CLI Checks

1. Parser changes need fixture-style `swift test` coverage.
2. CLI behavior changes should run `swift run beard --help` and a focused `swift run beard report --limit 5` smoke check.
3. Do not represent relative power as watts, watt-hours, or exact battery drain.
4. Keep command execution local, unprivileged, and shell-free unless jonmagic explicitly approves a privileged diagnostic.
5. Do not add Beard-owned launchd jobs, background schedulers, or automatic spoken-update scripts. Keep recurring coaching in the user's local agent or scheduler.
6. Release changes should keep `VERSION`, `Sources/beard/Version.swift`, `CHANGELOG.md`, docs, and the signed `scripts/package-release` / notarized `scripts/package-notarized-pkg` outputs aligned.

## Quality Loop

1. Prefer quality over speed for consequential changes.
2. Use critical review before adding new third-party services, persistence, deployment, credential handling, permission changes, or broad architecture.
3. If an agent miss happens, update `AGENTS.md`, this skill, docs, scripts, tests, or guardrails with the smallest durable improvement.

## ZShot Visual Checks

Use ZShot when browser rendering, visual state, or captured page artifacts would improve confidence. Default command path on jonmagic's Mac: `~/Library/Application Support/ZShot/zshot`.

1. Start with `zshot --agent-help` when unsure.
2. Prefer HTML/MHTML smoke captures when license support for screenshots or PDFs is unavailable.
3. Put temporary outputs under `zshot-artifacts/` or another ignored path.
4. Do not capture secrets or sensitive private pages unless the user explicitly approves the local-only artifact.

## Do Not Use For

- Generic questions that `AGENTS.md` already answers.
- One-off notes that should live in README or docs instead of a skill.
