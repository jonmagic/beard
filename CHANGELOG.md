# Changelog

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
