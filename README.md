# Beard

Beard is a local macOS CLI that samples current per-app/process energy signals and suggests concrete actions to prolong battery life.

It uses Apple-provided command-line tools (`pmset`, `top`, and `ps`) through absolute paths, keeps data local, and writes reports only to stdout.

The name is a Coach Beard joke. "Battery Coach" immediately made me think of Coach Beard from *Ted Lasso*, so the little battery coach became `beard`.

## Install

Download the notarized macOS installer from the latest release, double-click it, and follow the installer. It installs `beard` to `/usr/local/bin/beard`.

For scripted installs, you can also run `sudo installer -pkg Beard-<version>-macos-arm64.pkg -target /`.

## Usage

```sh
beard
beard --version
beard report --limit 10
beard report --json --samples 3 --interval 1
```

From source, use `swift run` only for development:

```sh
swift run beard report --limit 5
```

## Commands

```text
beard [report] [--json] [--samples N] [--interval SECONDS] [--limit N]
beard --help
beard --version
```

- `--json` emits a versioned machine-readable report.
- `--samples` controls usable `top` samples. Beard runs one extra pass, discards the first sample because macOS can report zeroed first-pass counters, and averages observed processes across the remaining samples.
- `--interval` controls seconds between samples.
- `--limit` controls how many app/process groups are shown.

## What the scores mean

macOS does not expose exact per-app watts or watt-hours through public APIs. Beard reports a relative current impact score from `top` plus CPU percentage, then groups those process samples by responsible app when it can derive one from the process path. On Apple Silicon, that relative power score often tracks CPU impact closely rather than acting as an independent measurement.

For deeper Apple Energy Impact data, `powermetrics --show-process-energy` exists but requires admin privileges. Beard's MVP intentionally stays unprivileged.

## Development

```sh
swift test
swift build
swift run beard --help
swift run beard --version
swift run beard report --limit 5
```

## Documentation

- [User guide](docs/user-guide.md)
- [Release guide](docs/releasing.md)
- [Changelog](CHANGELOG.md)

## Release artifact

Build the signed local download with:

```sh
scripts/package-release
scripts/package-notarized-pkg
```

The zip artifact is written to `dist/Beard-<version>-macos-arm64.zip` with a matching `.sha256` checksum. The notarized installer is written to `dist/Beard-<version>-macos-arm64.pkg` with a matching `.sha256` checksum.

The installer package signs the `beard` binary with Jonathan Hoyt's Developer ID Application certificate, signs the package with the Developer ID Installer certificate, submits it to Apple notarization, staples the accepted ticket, and validates it with Gatekeeper.

## Instruct your agent to make Beard always-on

Beard is deliberately just the local signal source. To make it feel like an always-running battery coach, give your AI agent a recurring instruction that decides when to run Beard and how to speak the result.

The pieces are:

- **Beard**: gathers the local battery/process signal.
- **[`llm`](https://github.com/simonw/llm)**: Simon Willison's CLI for sending the JSON report to an LLM and getting a short coaching sentence back.
- **`say`**: the built-in macOS text-to-speech command, useful for the simplest spoken version.
- **`relay`**: the Tri-State Relay Service CLI. It is a nicer replacement for `say` when you want queued updates, focus/ready controls, lines, and more control over how agent updates are spoken. TSRS is documented at <https://jonmagic.com/tsrs/>.

Give your agent an instruction like this:

```text
Every 15 minutes while I am on battery, run:

beard report --json --samples 2 --interval 1 --limit 8

If the Mac is plugged into power, skip the update. Otherwise, summarize the
biggest current drains in one short coaching note and speak it with my configured
local notifier. Use my normal LLM path if you need one, and keep the spoken
message short enough for my notifier.
```

For example, an agent could summarize with `llm --no-log` and then speak with `say` for the basic version, or enqueue the message with `relay --line "beard" --type update --message "..."` for the TSRS version.

Use [`prompts/local-agent-battery-coach.md`](prompts/local-agent-battery-coach.md) as the longer reusable prompt for that agent. If your agent sends Beard output to an external LLM provider, process names and battery state may leave the machine according to that provider's behavior.

## License

Beard is released under the ISC license. See [LICENSE](LICENSE).

## Agent Harness

Start with `AGENTS.md` for repository instructions. Project-specific skills live under `.github/skills/` when a repeated workflow earns one.
