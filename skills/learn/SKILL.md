---
name: learn
description: "Deep learning workflow: research a topic via Tavily + Exa, then generate a full NotebookLM learning package (podcast, infographic, mind map, flashcards). Use when the user wants to learn a new technology, framework, language, or concept in depth. Triggers: /learn, 'learn about', 'research and create', 'deep dive into', 'create a learning package'. Do NOT use for simple web searches or quick questions."
---

Research **$ARGUMENTS** across multiple search backends, then build a NotebookLM learning package.

If `$ARGUMENTS` is empty, ask: "What topic do you want to learn about?"

## Workflow

### Phase 1: Parallel Research

Run all available search backends simultaneously. Do NOT wait for one before starting another.

**Tavily** (`mcp__tavily__tavily_search`):
- `search_depth: "advanced"`, `include_raw_content: true`
- Query 1: `$ARGUMENTS`
- Query 2: `$ARGUMENTS tutorial guide 2025 2026`
- Extract top 3-5 URLs via `mcp__tavily__tavily_extract` if available

**Exa** (`mcp__exa__web_search_exa`):
- Query 1: `$ARGUMENTS documentation`
- Query 2: `$ARGUMENTS architecture patterns examples`
- Crawl valuable URLs via `mcp__exa__crawling_exa`

**WebSearch** (built-in fallback):
- Use only if Tavily or Exa is unavailable

### Phase 2: Organize

1. Deduplicate URLs across all backends
2. Categorize: official docs > tutorials > blog posts > code repos > comparisons
3. Write a 500-word research summary synthesizing key findings
4. Save state: `echo '{"topic":"...","notebooks":[],"total_sources":0}' > /tmp/learn-workflow-state.json`

### Phase 3: Load into NotebookLM

**IMPORTANT: Max 50 sources per notebook.** Track the count. Overflow creates a new notebook.

See `references/notebooklm-loading.md` for notebook creation strategy, source addition patterns, and overflow handling.

### Phase 4: Generate Artifacts

For each notebook, create **all four in parallel** (confirm=true on each):

| Artifact | Key params |
|----------|-----------|
| Podcast | `audio`, `deep_dive`, `language="he"` |
| Infographic | `infographic`, `bento_grid`, `portrait`, `language="he"` |
| Mind Map | `mind_map`, `language="he"` |
| Flashcards | `flashcards`, `medium`, `language="he"` |

See `references/artifact-generation.md` for exact tool call signatures.

### Phase 5: Poll & Report

Poll `mcp__notebooklm-mcp__studio_status` every 30s until all artifacts complete. Present final summary:

```
## Learning Package: [Topic]

### Notebooks
| # | Name | Sources | Link |
|---|------|---------|------|

### Artifacts
| Notebook | Type | Status | Title |
|----------|------|--------|-------|

### Research Summary
- X official docs, X tutorials, X articles, X repos
- Total unique sources: X
```

## Error Recovery

| Error | Action |
|-------|--------|
| Tavily MCP unavailable | Fall back to Exa + WebSearch |
| Exa MCP unavailable | Fall back to Tavily + WebSearch |
| Both unavailable | Use WebSearch only, warn about reduced coverage |
| Source add fails | Log URL, skip, continue with remaining sources |
| Source limit (50) hit | Create new notebook, continue adding |
| Studio generation fails | Retry once, then report failure in summary |
| NotebookLM auth expired | Run `nlm login` via Bash, retry |

## Language

Default: Hebrew (`he`). User can override: `/learn GraphQL --language en`
