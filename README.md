# Beard

Beard is a local macOS CLI that samples current per-app/process energy signals and suggests concrete actions to prolong battery life.

It uses Apple-provided command-line tools (`pmset`, `top`, and `ps`) through absolute paths, keeps data local, and writes reports only to stdout.

The name is a Coach Beard joke. Thinking of it as "Coach Battery" made me jump to Coach Beard from *Ted Lasso*, so the little battery coach became `beard`.

## Install

Download the notarized macOS installer from the latest release, double-click it, and follow the installer. It installs `beard` to `/usr/local/bin/beard`.

For scripted installs, you can also run `sudo installer -pkg Beard-<version>-macos-arm64.pkg -target /`.

## Usage

```sh
beard
beard --version
beard report --limit 10
beard report --json --samples 3 --interval 1
beard report --rules ~/.config/beard/rules.json
```

From source, use `swift run` only for development:

```sh
swift run beard report --limit 5
```

## Commands

```text
beard [report] [--json] [--samples N] [--interval SECONDS] [--limit N] [--rules PATH]
beard --help
beard --version
```

- `--json` emits a versioned machine-readable report.
- `--samples` controls usable `top` samples. Beard runs one extra pass, discards the first sample because macOS can report zeroed first-pass counters, and averages observed processes across the remaining samples.
- `--interval` controls seconds between samples.
- `--limit` controls how many app/process groups are shown.
- `--rules` overlays custom suggestion categories from a JSON rules file.

## What the scores mean

macOS does not expose exact per-app watts or watt-hours through public APIs. Beard reports a relative current impact score from `top` plus CPU percentage, then groups those process samples by responsible app when it can derive one from the process path. On Apple Silicon, that relative power score often tracks CPU impact closely rather than acting as an independent measurement.

For deeper Apple Energy Impact data, `powermetrics --show-process-energy` exists but requires admin privileges. Beard's MVP intentionally stays unprivileged.

Suggestions come from category rules rather than one-off app logic. Beard ships embedded defaults for common categories like browser, containers/VMs, developer tools, chat/calls, media, security tooling, display, and sync/storage. JSON reports include `category` and `categoryName` for each app/process group when a rule matches.

To customize suggestions, create `~/.config/beard/rules.json` with one or more category rules. User rules overlay Beard's embedded defaults by `id`, so you can add your own apps without losing future built-in categories. See the [user guide](docs/user-guide.md#customize-suggestion-rules) for the JSON format and a copy-paste example.

## Development

```sh
swift test
swift build
swift run beard --help
swift run beard --version
swift run beard report --limit 5
swift run beard report --rules rules/beard-rules.json
```

## Documentation

- [Docs overview](docs/README.md)
- [User guide](docs/user-guide.md)
- [Release guide](docs/releasing.md)
- [Changelog](CHANGELOG.md)

## Release artifact

Build the signed local download with:

```sh
scripts/package-release
scripts/package-notarized-pkg
```

The zip artifact is written to `dist/Beard-<version>-macos-arm64.zip` with a matching `.sha256` checksum and includes `rules/beard-rules.json` as a customization starting point. The notarized installer is written to `dist/Beard-<version>-macos-arm64.pkg` with a matching `.sha256` checksum.

The installer package signs the `beard` binary with Jonathan Hoyt's Developer ID Application certificate, signs the package with the Developer ID Installer certificate, submits it to Apple notarization, staples the accepted ticket, and validates it with Gatekeeper.

## Ask your agent to set up an always-on coach

Beard is deliberately just the local signal source. To make it feel like an always-running battery coach, ask your AI agent to help set up the local loop that runs Beard, summarizes the report, and speaks or queues the result.

The pieces are:

- **Beard**: gathers the local battery/process signal.
- **[`llm`](https://github.com/simonw/llm)**: Simon Willison's CLI for sending the JSON report to an LLM and getting a short coaching sentence back.
- **`say`**: the built-in macOS text-to-speech command, useful for the simplest spoken version.
- **`relay`**: the Tri-State Relay Service CLI. It is a nicer replacement for `say` when you want queued updates, focus/ready controls, lines, and more control over how agent updates are spoken. TSRS is documented at <https://jonmagic.com/tsrs/>.

Give your agent an instruction like this:

```text
Help me set up a local battery coach that runs every 15 minutes while I am on
battery power.

Use `beard report --json --samples 2 --interval 1 --limit 8` as the signal.
If the Mac is plugged into power, skip the update.

Summarize the biggest current drains in one short coaching note. Use my normal
`llm` command if you need a model call. Speak with `say` for the simple version
or enqueue with `relay --line "beard"` if Tri-State Relay Service is installed.

Show me the files or commands you create, and make the setup easy to remove.
```

For example, an agent could create a launchd job that summarizes with `llm --no-log` and then speaks with `say`, or enqueue the message with `relay --line "beard" --type update --message "..."` for the TSRS version. The point is that Beard stays a CLI and the recurring automation lives in your local setup.

Use [`prompts/local-agent-battery-coach.md`](prompts/local-agent-battery-coach.md) as the longer reusable prompt for that setup work. If your agent sends Beard output to an external LLM provider, process names and battery state may leave the machine according to that provider's behavior.

## License

Beard is released under the ISC license. See [LICENSE](LICENSE).

## Agent Harness

Start with `AGENTS.md` for repository instructions. Project-specific skills live under `.github/skills/` when a repeated workflow earns one.
