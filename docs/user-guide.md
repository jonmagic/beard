# Beard User Guide

Beard is a local macOS battery coach. It samples current app/process impact and explains what looks expensive. Your local AI agent can use Beard's JSON output to speak short coaching updates through `say`, Tri-State Relay Service, or another local notifier.

The name is a Coach Beard joke: "Battery Coach" made jonmagic think of Beard from *Ted Lasso*.

## Install from a release download

The easiest path is the notarized installer package:

```sh
sudo installer -pkg Beard-1.0.1-macos-arm64.pkg -target /
beard --version
beard report --limit 5
```

The package installs `beard` to `/usr/local/bin/beard`.

## Install from the zip

Download the macOS arm64 zip, unzip it, and copy the binary somewhere on your `PATH`.

```sh
unzip Beard-1.0.1-macos-arm64.zip
sudo cp Beard-1.0.1-macos-arm64/beard /usr/local/bin/beard
beard --version
beard report --limit 5
```

The zip release binary is signed with Jonathan Hoyt's Developer ID Application certificate, but loose CLI binaries are not stapled the same way as the installer package. Gatekeeper can reject a quarantined zip download.

If macOS blocks the binary after download, remove quarantine from the extracted release folder before copying it into place:

```sh
xattr -dr com.apple.quarantine Beard-1.0.1-macos-arm64
```

## Run from source

```sh
cd ~/code/jonmagic/beard
swift run beard --version
swift run beard report --limit 5
swift run beard report --json --samples 3 --interval 1
```

## Read the report

Beard reports relative current impact, not watts or watt-hours. On Apple Silicon, the power score often tracks CPU impact closely.

The top app/process list is best used as a coaching signal:

- **Copilot**: pause or close extra agent sessions if you are on battery.
- **OrbStack**: stop unused containers or VMs.
- **Safari/WebKit**: close live dashboards, social feeds, video/calls, Office web docs, or heavy GitHub diffs.
- **Microsoft Defender**: check for an active scan or update, but do not disable security tooling just to save battery.
- **WindowServer**: reduce brightness, disconnect extra displays, or close graphics-heavy windows.

## Spoken battery coaching with your agent

Beard does not install or manage a LaunchAgent. Use your local AI agent or scheduler to decide when to run it. The intended loop is:

1. Runs the release Beard binary with `report --json`.
2. Summarize the JSON with your chosen local agent or LLM path.
3. Speak or enqueue the short result through `say`, `relay`, or another local notifier.

Tri-State Relay Service is documented at <https://jonmagic.com/tsrs/>.

Use the agent prompt in `prompts/local-agent-battery-coach.md`. A minimal manual version looks like:

```sh
beard report --json --samples 2 --interval 1 --limit 8 | llm --no-log -s "Turn this Beard battery report into one short spoken coaching update under 240 characters."
```

## Privacy notes

The CLI itself stays local and writes reports only to stdout. Reports include local process names and PIDs.

If your agent or shell pipeline sends Beard JSON output to an LLM provider, process names and battery state may leave the machine according to that provider's behavior. Use options like `llm --no-log` when available if you do not want prompts and responses written to local tool logs.

## Troubleshooting

If `relay` rejects an update, make the spoken text shorter. Tri-State Relay Service currently expects short messages.

If `llm` fails, check that the configured model/provider is available.
