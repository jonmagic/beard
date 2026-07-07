# Beard

Beard is a local macOS CLI that samples current per-app/process energy signals and suggests concrete actions to prolong battery life.

It uses Apple-provided command-line tools (`pmset`, `top`, and `ps`) through absolute paths, keeps data local, and writes reports only to stdout.

The name is a Coach Beard joke. "Battery Coach" immediately made me think of Beard from *Ted Lasso*, so the little battery coach became `beard`.

Source: <https://github.com/jonmagic/beard>

## Install

Download the notarized macOS installer from the latest release, then install it:

```sh
sudo installer -pkg Beard-1.0.1-macos-arm64.pkg -target /
```

The installer puts the binary at `/usr/local/bin/beard`.

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

## Local agent battery coaching

Beard intentionally does not install a scheduler, background job, or LaunchAgent. It is just the local signal source.

The useful loop is for your local AI agent to run `beard report --json`, summarize it with whatever LLM path you already use, and speak or enqueue the result with your preferred local tool, such as `say` or Tri-State Relay Service. TSRS is described at <https://jonmagic.com/tsrs/>.

Use [`prompts/local-agent-battery-coach.md`](prompts/local-agent-battery-coach.md) as the prompt for that agent. If your agent sends Beard output to an external LLM provider, process names and battery state may leave the machine according to that provider's behavior.

## License

Beard is released under the ISC license. See [LICENSE](LICENSE).

## Agent Harness

Start with `AGENTS.md` for repository instructions. Project-specific skills live under `.github/skills/` when a repeated workflow earns one.
