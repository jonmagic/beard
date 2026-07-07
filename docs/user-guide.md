# Beard User Guide

Beard is a local macOS battery coach. It samples current app/process impact and explains what looks expensive. Your local AI agent can use Beard's JSON output to speak short coaching updates through `say`, Tri-State Relay Service, or another local notifier.

The name is a Coach Beard joke: "Battery Coach" made jonmagic think of Coach Beard from *Ted Lasso*.

## Install from a release download

The easiest path is the notarized installer package. Double-click `Beard-1.1.0-macos-arm64.pkg`, follow the installer, then open a new terminal and run:

```sh
beard --version
beard report --limit 5
```

The package installs `beard` to `/usr/local/bin/beard`.

For scripted installs, use:

```sh
sudo installer -pkg Beard-1.1.0-macos-arm64.pkg -target /
```

## Install from the zip

Download the macOS arm64 zip, unzip it, and copy the binary somewhere on your `PATH`.

```sh
unzip Beard-1.1.0-macos-arm64.zip
sudo cp Beard-1.1.0-macos-arm64/beard /usr/local/bin/beard
beard --version
beard report --limit 5
```

The zip release binary is signed with Jonathan Hoyt's Developer ID Application certificate, but loose CLI binaries are not stapled the same way as the installer package. Gatekeeper can reject a quarantined zip download.

If macOS blocks the binary after download, remove quarantine from the extracted release folder before copying it into place:

```sh
xattr -dr com.apple.quarantine Beard-1.1.0-macos-arm64
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

The top app/process list is best used as a coaching signal. Beard also assigns a category when a rule matches:

- **Copilot**: pause or close extra agent sessions if you are on battery.
- **OrbStack**: stop unused containers or VMs.
- **Safari/WebKit**: close live dashboards, social feeds, video/calls, Office web docs, or heavy GitHub diffs.
- **Microsoft Defender**: check for an active scan or update, but do not disable security tooling just to save battery.
- **WindowServer**: reduce brightness, disconnect extra displays, or close graphics-heavy windows.

In text output, categories appear next to the app name, such as `OrbStack [container-vm]`. In JSON output, each app can include `category` and `categoryName`.

## Customize suggestion rules

Beard has embedded defaults, so it still works if no rules file exists. Custom rules live at:

```text
~/.config/beard/rules.json
```

Create a minimal rules file like this:

```sh
mkdir -p ~/.config/beard
cat > ~/.config/beard/rules.json <<'JSON'
{
  "schemaVersion": 1,
  "categories": [
    {
      "id": "my-custom-apps",
      "name": "My custom apps",
      "exactMatches": [
        "MyBatteryHog"
      ],
      "containsMatches": [
        "my-background-helper"
      ],
      "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Pause this custom app or its helper when you are on battery."
    }
  ]
}
JSON
```

The file format is JSON:

- `schemaVersion`: currently `1`.
- `highImpactThreshold`: optional number. Defaults to Beard's built-in threshold.
- `genericSuggestion`: optional fallback template for uncategorized apps.
- `categories`: optional array of category rules.

A category rule has:

- `id`: stable machine-readable category id.
- `name`: human-readable category name.
- `exactMatches`: app/process names that must match exactly, case-insensitively.
- `containsMatches`: app/process substrings, case-insensitively. Prefer specific terms like `my-background-helper` over short words like `go` or `app`.
- `suggestion`: template text. Supported placeholders are `{app}`, `{power}`, and `{cpu}`.

User rules overlay Beard's embedded defaults by `id`. If your auto-loaded `~/.config/beard/rules.json` is invalid, Beard warns on stderr and falls back to embedded defaults so reports keep working. If you pass a rules file explicitly, invalid rules fail fast:

```sh
beard report --rules ~/.config/beard/rules.json
BEARD_RULES_PATH=~/.config/beard/rules.json beard report
```

The full built-in rules file is available in the source repository and in the zip release as `rules/beard-rules.json`, but you do not need to copy it just to add one custom category.

## Instruct your agent to make Beard feel always-on

Beard does not install or manage a LaunchAgent. Instead, instruct your local AI agent to use Beard as the battery signal source, choose the cadence, and decide how to speak the result.

There are three optional pieces around Beard:

- [`llm`](https://github.com/simonw/llm): Simon Willison's command-line tool for sending the Beard JSON report to an LLM.
- `say`: the built-in macOS speech command. This is the simplest way to hear a short update.
- `relay`: the Tri-State Relay Service CLI. Use this instead of `say` when you want a queue, focus/ready controls, project lines, and a better agent-update experience. TSRS is documented at <https://jonmagic.com/tsrs/>.

Use this shape:

1. Every 15 minutes, run `beard report --json --samples 2 --interval 1 --limit 8`.
2. If the Mac is plugged into power, skip the update.
3. If the Mac is on battery, summarize the top drains in one short coaching note.
4. Speak or enqueue the note through the user's configured notifier: `say`, `relay`, or something else.

Use the agent prompt in `prompts/local-agent-battery-coach.md`. A minimal manual version looks like:

```sh
beard report --json --samples 2 --interval 1 --limit 8 | llm --no-log -s "Turn this Beard battery report into one short spoken coaching update under 240 characters."
```

That produces text. To hear it, pipe the result into `say` or have your agent enqueue it with `relay`.

## Privacy notes

The CLI itself stays local and writes reports only to stdout. Reports include local process names and PIDs.

If your agent or shell pipeline sends Beard JSON output to an LLM provider, process names and battery state may leave the machine according to that provider's behavior. Use options like `llm --no-log` when available if you do not want prompts and responses written to local tool logs.

## Troubleshooting

If `relay` rejects an update, make the spoken text shorter. Tri-State Relay Service currently expects short messages.

If `llm` fails, check that the configured model/provider is available.
