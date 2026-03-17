# Setup Instructions for AI Assistants

When a user shares this repository URL, your job is to install the `/learn` skill and configure the required MCP servers. Follow these steps exactly.

## Step 1: Install the skill files

```bash
mkdir -p ~/.claude/skills/learn/references
```

Then copy these files from this repo:
- `skills/learn/SKILL.md` -> `~/.claude/skills/learn/SKILL.md`
- `skills/learn/references/notebooklm-loading.md` -> `~/.claude/skills/learn/references/notebooklm-loading.md`
- `skills/learn/references/artifact-generation.md` -> `~/.claude/skills/learn/references/artifact-generation.md`

Use the Write tool to create each file. Read them from this repo first.

## Step 2: Collect API keys from the user

Ask the user for the following. Do NOT proceed without them:

1. **Tavily API key** — "Do you have a Tavily API key? Get one free at https://tavily.com if not."
2. **Exa API key** — "Do you have an Exa API key? Get one at https://exa.ai if not."
3. **NotebookLM MCP** — "Do you have the notebooklm-mcp server installed? If not, I'll skip NotebookLM setup and you can add it later."

If the user doesn't have a key for Tavily or Exa, still proceed with whichever they have. The skill has fallback support. At minimum, one search backend is needed.

## Step 3: Configure MCP servers

Read the user's `~/.claude/settings.json`. If it exists, merge the new MCP servers into the existing `mcpServers` object. If it doesn't exist, create it.

Add these entries (replacing API keys with the user's actual keys):

```json
{
  "mcpServers": {
    "tavily": {
      "type": "url",
      "url": "https://mcp.tavily.com/mcp/?tavilyApiKey=USER_TAVILY_KEY"
    },
    "exa": {
      "type": "url",
      "url": "https://mcp.exa.ai/mcp?exaApiKey=USER_EXA_KEY&tools=web_search_exa,web_search_advanced_exa,get_code_context_exa,crawling_exa,company_research_exa,people_search_exa,deep_researcher_start,deep_researcher_check"
    }
  }
}
```

IMPORTANT: Do NOT overwrite existing settings. Merge into the existing JSON structure. Preserve all existing mcpServers, permissions, hooks, plugins, and other settings.

## Step 4: NotebookLM setup (if user has it)

If the user confirmed they have notebooklm-mcp:
- Check if it's already in their MCP config
- If not, ask how they installed it and help add the correct config entry
- Run `nlm login` if they need to authenticate

If the user doesn't have it:
- Tell them: "NotebookLM MCP is optional but recommended. The skill will still work for research — it just won't generate podcasts/infographics. You can add it later by installing notebooklm-mcp from https://github.com/nicholasgriffintn/notebooklm-mcp"

## Step 5: Confirm and instruct

After setup, tell the user:

---

Setup complete! Here's what was installed:

**Skill:** `/learn` — installed to `~/.claude/skills/learn/`

**MCP servers configured:**
- [list which ones were added]

**To use it:**
1. Restart Claude Code (exit and relaunch, or start a new session)
2. Type `/learn <topic>` — for example: `/learn Kafka event streaming`

**What it does:**
- Researches your topic across Tavily, Exa, and web search in parallel
- Loads all sources into a NotebookLM notebook (auto-creates overflow notebooks at 50 sources)
- Generates a Hebrew learning package: podcast, infographic, mind map, and flashcards
- Override language with `--language en`

**Customization:**
- Edit `~/.claude/skills/learn/SKILL.md` to change default language or artifact types
- See `~/.claude/skills/learn/references/artifact-generation.md` for all available NotebookLM artifact options

---

## Important notes for the AI assistant

- Always read the user's existing settings.json before writing to it
- Never expose or log API keys in visible output
- If you cannot write to ~/.claude/ (permissions), suggest the user run the commands manually
- If the user is using a different AI tool (not Claude Code), explain that this skill is designed for Claude Code's skill system but the workflow logic in SKILL.md can be adapted
