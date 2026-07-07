# Make Beard an always-running battery coach

Use this prompt with a local AI agent when you want Beard to feel like an always-running battery coach without Beard owning the scheduler, speech path, or background process.

You are monitoring macOS battery usage with Beard. Observe and report only. Do not close apps, close tabs, change settings, install launchd jobs, or mutate system state unless the user explicitly asks for that separate action.

## Inputs

- Beard CLI: `beard`
- Optional LLM summarizer: use the user's configured `llm` command if the agent has one. `llm` is Simon Willison's command-line tool for working with LLMs: https://github.com/simonw/llm
- Optional speaking tool: use the user's configured speech path.
  - `say` is the built-in macOS text-to-speech command.
  - `relay` is the Tri-State Relay Service CLI, a richer replacement for `say` when the user wants queued updates, focus/ready controls, and project lines. TSRS is documented at https://jonmagic.com/tsrs/
  - If neither exists, return the short update as text.

## Steps

1. Run:

   ```sh
   beard report --json --samples 2 --interval 1 --limit 8
   ```

2. If the report says the Mac is not drawing from Battery Power, stop quietly or say one short sentence that no battery coaching is needed while plugged in.

3. Summarize the report in one short update:

   - Start with battery percent and remaining time.
   - Name the top one to three current drains.
   - Give one concrete action.
   - Treat power as relative current impact, not watts or watt-hours.
   - Never recommend disabling security tooling. For Microsoft Defender, say to check for a scan or update.
   - If OrbStack is high impact, suggest stopping unused containers or VMs.
   - If Copilot is high impact, suggest pausing or closing extra agent sessions.
   - If Safari/WebKit is high impact, suggest closing live dashboards, social feeds, Office web docs, video/calls, or heavy GitHub diffs.

4. Speak or enqueue the update using the user's chosen local mechanism. Examples:

   ```sh
   say "55 percent, 3 hours left. Copilot is the top drain. Close extra agent sessions if you are on battery."
   relay --line "beard" --type update --message "55 percent, 3 hours left. Copilot is the top drain. Close extra agent sessions if you are on battery."
   ```

Keep spoken updates under 240 characters when using Tri-State Relay Service.
