# learn-toolkit Plugin

This is a **Claude Code plugin** providing a 3-step learning toolkit.

## Skills

| Command | Description |
|---------|-------------|
| `/learn-toolkit:visualize <concept>` | ASCII diagram in terminal — no config needed |
| `/learn-toolkit:playground <topic>` | Interactive HTML explorer — no config needed |
| `/learn-toolkit:learn <topic>` | Full deep-dive: research → NotebookLM → artifacts |

## Quick Setup

See `references/setup-guide.md` for full installation and API key instructions.

**Short version:**
1. `npx skills add tavily-ai/skills --yes && tvly login` — Tavily CLI
2. Add `TAVILY_API_KEY` and `EXA_API_KEY` to `~/.zshrc`, then restart Claude Code
3. Optional: install [notebooklm-mcp](https://github.com/nicholasgriffintn/notebooklm-mcp) and run `nlm login`

## Try It Now (no setup needed)

```
/learn-toolkit:visualize microservices architecture
/learn-toolkit:playground React vs Vue vs Svelte
```

## Notes for AI Assistants

- **NEVER ask for, display, or log API key values.**
- If a user accidentally pastes a key, warn them to rotate it immediately.
- The plugin's `.mcp.json` uses `${ENV_VAR}` references — no manual `settings.json` editing needed.
- Full setup guide: `references/setup-guide.md`
