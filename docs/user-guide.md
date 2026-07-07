# Beard User Guide

Beard is a local macOS battery coach. It samples current app/process impact, explains what looks expensive, and can send short spoken coaching updates through Tri-State Relay Service.

The name is a Coach Beard joke: "Battery Coach" made jonmagic think of Beard from *Ted Lasso*.

## Install from a release download

The easiest path is the notarized installer package:

```sh
sudo installer -pkg Beard-1.0.0-macos-arm64.pkg -target /
beard --version
beard report --limit 5
```

The package installs `beard` to `/usr/local/bin/beard`.

## Install from the zip

Download the macOS arm64 zip, unzip it, and copy the binary somewhere on your `PATH`.

```sh
unzip Beard-1.0.0-macos-arm64.zip
sudo cp Beard-1.0.0-macos-arm64/beard /usr/local/bin/beard
beard --version
beard report --limit 5
```

The zip release binary is signed with Jonathan Hoyt's Developer ID Application certificate, but loose CLI binaries are not stapled the same way as the installer package. Gatekeeper can reject a quarantined zip download.

If macOS blocks the binary after download, remove quarantine from the extracted release folder before copying it into place:

```sh
xattr -dr com.apple.quarantine Beard-1.0.0-macos-arm64
```

## Run from source

```sh
cd ~/code/jonmagic/beard
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

## Spoken battery coaching

From the source checkout, install the LaunchAgent:

```sh
cd ~/code/jonmagic/beard
scripts/install-launch-agent
```

Every 15 minutes, launchd runs `scripts/beard-battery-relay`. It no-ops when `pmset` reports AC Power, so you only get coaching when the Mac is actually drawing from battery. The script:

1. Runs the release Beard binary with `report --json`.
2. Sends the JSON report to Simon Willison's `llm` CLI with the prompt in `prompts/battery-relay-update.md`.
3. Enqueues the short result through the Tri-State Relay Service `relay` CLI.

Tri-State Relay Service is documented at <https://jonmagic.com/tsrs/>.

Useful checks:

```sh
launchctl print gui/$(id -u)/com.jonmagic.beard-battery-relay
tail -50 ~/Library/Logs/beard/battery-relay.log
```

To stop the scheduled coaching:

```sh
scripts/uninstall-launch-agent
```

## Privacy notes

The CLI itself stays local and writes reports only to stdout. Reports include local process names and PIDs.

The spoken coaching runner intentionally sends Beard JSON output to the configured `llm` provider. It uses `llm --no-log` so the prompt and response are not written to the local `llm` log database. The runner logs only the short relay update, not the raw JSON report, and caps the log at roughly 50 KB.

## Troubleshooting

If the scheduled job uses old behavior after code changes, rebuild and reinstall it:

```sh
scripts/install-launch-agent
```

If `relay` rejects an update, check the log. Beard trims spoken updates below the current Relay message limit.

If `llm` fails, check that the configured model/provider is available. Repeated failure relays are deduplicated so you do not get the same high-priority warning every 15 minutes.
