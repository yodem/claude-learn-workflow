# Setup Instructions for AI Assistants

This repository is a **Claude Code plugin**. When a user shares this repo URL, guide them through the plugin install — do NOT manually copy skill files.

## Quick install (preferred)

### Step 1: Add the marketplace and install the plugin

```
/plugin marketplace add yodem/claude-learn-workflow
/plugin install learn-toolkit@learn-toolkit-marketplace
```

Or via CLI:
```bash
claude plugin install learn-toolkit@learn-toolkit-marketplace
```

This installs all 3 skills and configures MCP servers automatically:
- `/learn-toolkit:visualize` — ASCII diagrams in terminal (no config needed)
- `/learn-toolkit:playground` — Interactive HTML explorer (no config needed)
- `/learn-toolkit:learn` — Tavily + Exa research into NotebookLM packages

### Step 2: Set up API keys for /learn (optional)

The `/learn-toolkit:visualize` and `/learn-toolkit:playground` skills work immediately with no API keys.

For `/learn-toolkit:learn`, the plugin's `.mcp.json` configures Tavily and Exa servers using environment variable references (`${TAVILY_API_KEY}`, `${EXA_API_KEY}`). The user needs to set these in their shell profile.

**SECURITY: NEVER ask the user to paste API keys in the chat.**

Detect their shell:
```bash
echo $SHELL
```

Then tell them:

---

The plugin is installed. To enable the `/learn-toolkit:learn` search backends, add your API keys to your shell profile.

**Open your shell profile in your editor** (`~/.zshrc` for zsh, `~/.bashrc` for bash) and add:

```bash
export TAVILY_API_KEY="your-tavily-key-here"    # Get one free at https://tavily.com
export EXA_API_KEY="your-exa-key-here"          # Get one at https://exa.ai
```

Then run `source ~/.zshrc` (or `~/.bashrc`) and restart Claude Code.

**Do not paste your API keys in this chat.** Add them directly to your shell profile.

---

If the user doesn't have API keys, that's fine — `/learn-toolkit:learn` falls back to built-in WebSearch. `/learn-toolkit:visualize` and `/learn-toolkit:playground` work with no keys at all.

### Step 3: NotebookLM (optional)

If the user wants podcast/infographic generation:
- Check if they have `notebooklm-mcp` installed
- If not: "NotebookLM is optional. `/learn-toolkit:learn` will still research your topic — it just won't generate podcasts, infographics, and flashcards. Add it later from https://github.com/nicholasgriffintn/notebooklm-mcp"

### Step 4: Confirm

Tell the user:

---

Plugin **learn-toolkit** installed. Here's what you have:

| Skill | Command | Ready? |
|-------|---------|--------|
| ASCII Visualizer | `/learn-toolkit:visualize <concept>` | Yes |
| Interactive Playground | `/learn-toolkit:playground <topic>` | Yes |
| Deep Learning | `/learn-toolkit:learn <topic>` | After setting env vars + restart |

**Try now (no restart needed):**
```
/learn-toolkit:visualize microservices architecture
/learn-toolkit:playground React vs Vue vs Svelte
```

**After env vars + restart:**
```
/learn-toolkit:learn Kafka event streaming
```

**When to use which:**
- Quick concept, stay in terminal -> `/learn-toolkit:visualize`
- Compare options, explore interactively -> `/learn-toolkit:playground`
- Deep dive, new technology, team materials -> `/learn-toolkit:learn`

---

## Important notes for the AI assistant

- **NEVER ask for, display, or log API key values.** Not in chat, not in tool calls, not in file contents.
- If a user accidentally pastes a key, warn them to rotate it immediately
- The plugin bundles MCP configs via `.mcp.json` with `${ENV_VAR}` references — no manual settings.json editing needed
- If the user's Claude Code version doesn't support plugins (< 1.0.33), fall back to manual skill installation using the files in `skills/`
