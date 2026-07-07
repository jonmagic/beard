# Beard

Beard is a local macOS CLI that samples current per-app/process energy signals and suggests concrete actions to prolong battery life.

It uses Apple-provided command-line tools (`pmset`, `top`, and `ps`) through absolute paths, keeps data local, and writes reports only to stdout.

The name is a Coach Beard joke. "Battery Coach" immediately made me think of Beard from *Ted Lasso*, so the little battery coach became `beard`.

Source: <https://github.com/jonmagic/beard>

## Usage

```sh
swift run beard
swift run beard --version
swift run beard report --limit 10
swift run beard report --json --samples 3 --interval 1
```

Installed binary usage is the same without `swift run`:

```sh
beard report
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

The zip artifact is written to `dist/Beard-1.0.0-macos-arm64.zip` with a matching `.sha256` checksum. The notarized installer is written to `dist/Beard-1.0.0-macos-arm64.pkg` with a matching `.sha256` checksum.

The installer package signs the `beard` binary with Jonathan Hoyt's Developer ID Application certificate, signs the package with the Developer ID Installer certificate, submits it to Apple notarization, staples the accepted ticket, and validates it with Gatekeeper.

## Tri-State Relay battery updates

Beard can install a user LaunchAgent that runs every 15 minutes while the Mac is on battery power, summarizes `beard report --json` through Simon Willison's `llm` CLI with `--no-log`, and enqueues the spoken update through jonmagic's Tri-State Relay Service CLI.

That glue is the point of the project: Beard gathers the local battery/process signal, `llm` turns it into a short coaching note, and Tri-State Relay Service speaks it as a lightweight audio stream. TSRS is described at <https://jonmagic.com/tsrs/>.

```sh
scripts/install-launch-agent
scripts/uninstall-launch-agent
```

The installed job label is `com.jonmagic.beard-battery-relay`. It no-ops when `pmset` reports AC Power, logs to `~/Library/Logs/beard/battery-relay.log`, and caps that log at roughly 50 KB on each run. The prompt lives at `prompts/battery-relay-update.md`.

Useful checks:

```sh
launchctl print gui/$(id -u)/com.jonmagic.beard-battery-relay
tail -50 ~/Library/Logs/beard/battery-relay.log
```

The relay runner sends Beard's JSON report to the configured `llm` CLI provider, so process names and battery state may leave the machine according to that provider's behavior. The `--no-log` flag prevents `llm` from writing the prompt/response to its local log database.

The LaunchAgent uses the release binary at `.build/release/beard`. Re-run `scripts/install-launch-agent` after source changes so the scheduled job uses the latest code.

## License

Beard is released under the ISC license. See [LICENSE](LICENSE).

## Agent Harness

Start with `AGENTS.md` for repository instructions. Project-specific skills live under `.github/skills/` when a repeated workflow earns one.
