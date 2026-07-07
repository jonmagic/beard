# Changelog

## 1.1.0 - Category-based suggestions

- Replaced hard-coded app-specific suggestion logic with category rules.
- Added built-in categories for browsers, containers/VMs, developer tools, chat/calls, media, sync/storage, security tooling, device management, display, and thermal management.
- Added category metadata to JSON reports so agents can provide richer coaching.
- Added `--rules PATH`, `BEARD_RULES_PATH`, and `~/.config/beard/rules.json` support for custom rule overlays.
- Added `rules/beard-rules.json` as the editable starting point for custom rules.

## 1.0.3 - New-user coaching docs

- Linked Simon Willison's `llm` project from the always-on coaching docs.
- Explained `say` as the built-in macOS speech path and `relay` as the Tri-State Relay Service option for richer spoken updates.
- Tightened the agent prompt so new users can understand the moving parts.

## 1.0.2 - Install and agent-coach docs

- Made double-clicking the notarized pkg the primary install path.
- Removed the repository self-link from the README.
- Reframed always-on coaching as instructions for a local AI agent.

## 1.0.1 - Installed binary docs

- Updated the README and user guide to make installed `beard` commands the primary user path.
- Kept `swift run beard` examples scoped to source-development workflows.
- Removed Beard-owned LaunchAgent automation and replaced it with a local-agent prompt.

## 1.0.0 - Initial release

- Shipped the native Swift `beard` CLI for local macOS battery impact reports.
- Added text and JSON reports with battery state, Low Power Mode, display sleep, top app/process impact, and safe recommendations.
- Added unprivileged sampling through Apple command-line tools: `pmset`, `top`, and `ps`.
- Added a first-pass 15-minute LaunchAgent experiment for local spoken coaching through Simon Willison's `llm` CLI and Tri-State Relay Service.
- Added ISC licensing, user documentation, and signed/notarized macOS arm64 release artifact workflows.
