# /learn — Deep Learning Workflow for Claude Code

A Claude Code **skill** that chains **Tavily**, **Exa**, and **NotebookLM** into an automated learning pipeline. Give it a topic, get back a full learning package: podcast, infographic, mind map, and flashcards.

Built following [Claude Code best practices](https://docs.anthropic.com/en/docs/claude-code) — proper skill structure with YAML frontmatter, progressive disclosure via `references/`, explicit error recovery, and graceful MCP fallbacks.

## How It Works

```
/learn <topic>
```

```
Phase 1: Research (parallel)          Phase 2: Organize
  ├── Tavily (advanced search)   ->     ├── Deduplicate URLs
  ├── Exa (web + code search)    ->     ├── Categorize sources
  └── WebSearch (fallback)       ->     └── Create research summary

Phase 3: NotebookLM                   Phase 4: Generate (parallel)
  ├── Create notebook(s)         ->     ├── Hebrew podcast (deep dive)
  ├── Add URLs as sources        ->     ├── Bento-grid infographic
  ├── Add research summary       ->     ├── Mind map
  └── Overflow -> new notebook   ->     └── Flashcards

Phase 5: Poll & Report
  └── Final summary table with notebook links and artifact status
```

### Source Overflow Handling

NotebookLM allows up to **50 sources per notebook**. When the limit is reached, the workflow automatically creates additional notebooks:

| Notebook | Contents |
|----------|----------|
| `[Topic] - Core Learning` | Official docs, tutorials, main articles |
| `[Topic] - Deep Dive` | Code examples, comparisons, advanced content |
| `[Topic] - Community` | Blog posts, discussions, alternatives |

## Setup

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- API keys for:
  - **Tavily** — [tavily.com](https://tavily.com)
  - **Exa** — [exa.ai](https://exa.ai)
  - **NotebookLM MCP** — `notebooklm-mcp` server (see Step 3)

### Step 1: Install the skill

Claude Code uses a **skills** system (`.claude/skills/<name>/SKILL.md`) with YAML frontmatter for discoverability. The older `commands/` directory also works but skills take precedence.

```bash
# Option A: Personal skill (available in all your projects)
mkdir -p ~/.claude/skills/learn/references
cp skills/learn/SKILL.md ~/.claude/skills/learn/SKILL.md
cp skills/learn/references/*.md ~/.claude/skills/learn/references/

# Option B: Project skill (available only in current project, committable)
mkdir -p .claude/skills/learn/references
cp skills/learn/SKILL.md .claude/skills/learn/SKILL.md
cp skills/learn/references/*.md .claude/skills/learn/references/

# Option C: Legacy command (still works, simpler but less discoverable)
cp commands/learn.md ~/.claude/commands/learn.md
```

### Step 2: Configure MCP servers

Add to `~/.claude/settings.json` under `"mcpServers"`:

```json
{
  "mcpServers": {
    "tavily": {
      "type": "url",
      "url": "https://mcp.tavily.com/mcp/?tavilyApiKey=YOUR_TAVILY_API_KEY"
    },
    "exa": {
      "type": "url",
      "url": "https://mcp.exa.ai/mcp?exaApiKey=YOUR_EXA_API_KEY&tools=web_search_exa,web_search_advanced_exa,get_code_context_exa,crawling_exa,company_research_exa,people_search_exa,deep_researcher_start,deep_researcher_check"
    }
  }
}
```

Replace `YOUR_TAVILY_API_KEY` and `YOUR_EXA_API_KEY` with your actual keys.

**MCP server scoping** (choose based on your needs):

| Scope | Where | Use case |
|-------|-------|----------|
| User (recommended) | `~/.claude/settings.json` | Available in all projects |
| Project | `.mcp.json` in project root | Shared with team via git |
| Local | `.claude/settings.local.json` | Per-machine, gitignored |

When servers share the same name across scopes, local wins over project, project wins over user.

**Environment variable support**: `.mcp.json` supports `${VAR}` and `${VAR:-default}` syntax for API keys, so you can commit the config without hardcoding secrets:

```json
{
  "mcpServers": {
    "tavily": {
      "type": "url",
      "url": "https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}"
    }
  }
}
```

### Step 3: Install NotebookLM MCP

Install and authenticate the NotebookLM MCP server:

```bash
# Install (see https://github.com/nicholasgriffintn/notebooklm-mcp)
# Then authenticate:
nlm login
```

### Step 4: Restart Claude Code

MCP servers load at session start:

```bash
/exit
claude
```

### Step 5: Verify

```
/learn React Server Components
```

You should see parallel research across Tavily and Exa, followed by NotebookLM notebook creation and artifact generation.

## Usage

```bash
# Learn a new technology
/learn Kafka event streaming

# Learn a programming language
/learn Rust ownership and borrowing

# Learn a framework
/learn Next.js App Router and Server Components

# Learn a concept
/learn distributed consensus algorithms

# Override language (default is Hebrew)
/learn GraphQL federation --language en
```

## Output

```
## Learning Package: Kafka Event Streaming

### Notebooks
| # | Notebook                     | Sources | Link        |
|---|------------------------------|---------|-------------|
| 1 | Kafka - Core Learning        | 28      | [Open](url) |
| 2 | Kafka - Deep Dive            | 15      | [Open](url) |

### Artifacts
| Notebook | Type        | Status | Title                       |
|----------|-------------|--------|-----------------------------|
| Core     | Podcast     | Done   | יסודות קפקא ועיבוד אירועים |
| Core     | Infographic | Done   | ארכיטקטורת קפקא             |
| Core     | Mind Map    | Done   | עולם קפקא - מפת מושגים     |
| Core     | Flashcards  | Done   | 12 כרטיסיות למידה           |
```

## Configuration

### Language

Default: **Hebrew** (`he`). Override per-invocation or edit `SKILL.md`.

### Research Backends

All three run in parallel with graceful fallback:

| Available | Behavior |
|-----------|----------|
| Tavily + Exa + WebSearch | Full coverage (best) |
| Tavily + WebSearch | Tavily primary |
| Exa + WebSearch | Exa primary |
| WebSearch only | Built-in only (reduced depth) |

### Artifact Types

Default: podcast + infographic + mind map + flashcards. Additional types available in `references/artifact-generation.md`:

| Type | Options |
|------|---------|
| Audio | `deep_dive`, `brief`, `critique`, `debate` |
| Infographic | `bento_grid`, `sketch_note`, `professional`, `editorial` |
| Video | `explainer`, `brief`, `cinematic` |
| Slides | `detailed_deck`, `presenter_slides` |
| Report | `Briefing Doc`, `Study Guide`, `Blog Post` |

## File Structure

```
claude-learn-workflow/
├── README.md
├── LICENSE
├── skills/
│   └── learn/
│       ├── SKILL.md                          # Main skill (install this)
│       └── references/
│           ├── notebooklm-loading.md         # Notebook creation & overflow
│           └── artifact-generation.md        # Tool call signatures
├── commands/
│   └── learn.md                              # Legacy command (alternative)
└── examples/
    └── settings-snippet.json                 # MCP config template
```

### Why skills over commands?

| Feature | Commands (`~/.claude/commands/`) | Skills (`~/.claude/skills/`) |
|---------|----------------------------------|------------------------------|
| YAML frontmatter | No | Yes (name, description, triggers) |
| Auto-discovery | By name only | By description + trigger patterns |
| Progressive disclosure | Flat file | SKILL.md + references/ directory |
| Precedence | Lower | Higher (skills win on name collision) |
| Monorepo support | No | Yes (nested `.claude/skills/` dirs) |

## Context: The 3-Step Learning Framework

This tool implements **Step 3** of a developer learning framework:

| Step | Tool | Environment | When to Use |
|------|------|-------------|-------------|
| 1 | ASCII Visualizer | Terminal | Quick concept, stay in CLI |
| 2 | Playground (HTML) | Browser | Compare alternatives, interactive |
| **3** | **NotebookLM + /learn** | **Web / MCP** | **Deep learning, new tech, team materials** |

## License

MIT
