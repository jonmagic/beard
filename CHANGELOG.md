# Changelog

## 1.0.0 - Initial release

- Shipped the native Swift `beard` CLI for local macOS battery impact reports.
- Added text and JSON reports with battery state, Low Power Mode, display sleep, top app/process impact, and safe recommendations.
- Added unprivileged sampling through Apple command-line tools: `pmset`, `top`, and `ps`.
- Added a 15-minute LaunchAgent that summarizes Beard output through Simon Willison's `llm` CLI and sends spoken updates through Tri-State Relay Service.
- Made the LaunchAgent no-op while the Mac is plugged into AC power.
- Added ISC licensing, user documentation, and signed/notarized macOS arm64 release artifact workflows.
