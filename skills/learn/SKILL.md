---
name: learn
description: "Deep learning workflow: research a topic via Tavily + Exa, then generate a full NotebookLM learning package (podcast, infographic, mind map, flashcards). Use when the user wants to learn a new technology, framework, language, or concept in depth. Triggers: /learn, 'learn about', 'research and create', 'deep dive into', 'create a learning package'. Do NOT use for simple web searches or quick questions."
argument-hint: "<topic>"
disable-model-invocation: true
metadata:
  author: Yotam Fromm
  version: 1.0.0
  mcp-server: tavily, exa, notebooklm-mcp
  category: learning
  tags: [research, notebooklm, tavily, exa, podcast, flashcards]
---

# Learn Workflow

## Important

CRITICAL: Follow these steps in exact order. Each phase has a verification gate — do NOT proceed to the next phase until verification passes.

- This workflow requires 3 MCP servers: **tavily**, **exa**, **notebooklm-mcp**
- If a server is unavailable, follow the fallback in the Error Recovery table
- Default output language is **Hebrew** (`he`). User can override with `--language <code>`
- Max 50 sources per NotebookLM notebook. Track count and overflow to new notebooks

## Instructions

### Phase 1: Parallel Research

Research **$ARGUMENTS** across all available backends simultaneously.

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

**Verification gate:** At least 5 unique URLs collected across all backends. If fewer, run additional queries with broader terms before proceeding.

### Phase 2: Organize and Verify

1. Deduplicate URLs across all backends
2. Categorize: official docs > tutorials > blog posts > code repos > comparisons
3. Write a 500-word research summary synthesizing key findings
4. Save state:
```bash
echo '{"topic":"...","notebooks":[],"total_sources":0}' > /tmp/learn-workflow-state.json
```

**Verification gate:** State file written successfully. Research summary covers at least 3 distinct subtopics. If not, return to Phase 1 with refined queries.

### Phase 3: Load into NotebookLM

IMPORTANT: Max 50 sources per notebook. Track the count. Overflow creates a new notebook.

Consult `${CLAUDE_SKILL_DIR}/references/notebooklm-loading.md` for notebook creation strategy, source addition patterns, and overflow handling.

1. Create notebook: `mcp__notebooklm-mcp__notebook_create(title="[Topic] - Core Learning")`
2. Add all URL sources with `wait=false` (non-blocking)
3. Add research summary text source with `wait=true` (blocking)
4. Update state file with notebook ID and source count after each addition
5. If source count reaches 48, create overflow notebook and continue

**Verification gate:** Run `mcp__notebooklm-mcp__studio_status` and confirm all sources show `status: "ready"` or `"completed"`. If sources are still processing, wait 10 seconds and check again (max 3 retries).

### Phase 4: Generate Artifacts

For each notebook, create all four artifacts in parallel (confirm=true on each).

Consult `${CLAUDE_SKILL_DIR}/references/artifact-generation.md` for exact tool call signatures.

| Artifact | Type | Key params |
|----------|------|-----------|
| Podcast | `audio` | `deep_dive`, `language="he"` |
| Infographic | `infographic` | `bento_grid`, `portrait`, `language="he"` |
| Mind Map | `mind_map` | `language="he"` |
| Flashcards | `flashcards` | `medium`, `language="he"` |

**Verification gate:** All 4 `studio_create` calls returned successfully with artifact IDs. If any failed, retry once before reporting failure.

### Phase 5: Poll and Report

Poll `mcp__notebooklm-mcp__studio_status` every 30 seconds until all artifacts are complete (max 10 polls / 5 minutes).

Present final summary to user:

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

**Verification gate:** Summary table includes at least 1 notebook and 4 artifacts. All artifact statuses are reported (completed or failed, not in_progress).

## Examples

### Example 1: Learning a new framework

User says: `/learn Next.js App Router`

Actions:
1. Tavily searches for "Next.js App Router" and "Next.js App Router tutorial guide 2025 2026"
2. Exa searches for "Next.js App Router documentation" and "Next.js App Router architecture patterns"
3. Collects 23 unique URLs, deduplicates to 19
4. Creates "Next.js App Router - Core Learning" notebook, adds all 19 URLs + research summary
5. Generates podcast, infographic, mind map, flashcards in Hebrew
6. Polls until complete, presents summary table

Result: Learning package with 1 notebook, 19 sources, 4 artifacts

### Example 2: Overflow to multiple notebooks

User says: `/learn Kubernetes`

Actions:
1. Research yields 65 unique URLs across all backends
2. Creates "Kubernetes - Core Learning" (48 sources)
3. Creates "Kubernetes - Deep Dive" (17 sources + research summary)
4. Generates 4 artifacts per notebook (8 total)

Result: Learning package with 2 notebooks, 65 sources, 8 artifacts

### Example 3: Language override

User says: `/learn GraphQL federation --language en`

Actions: Same workflow, but all NotebookLM artifacts use `language="en"` instead of `"he"`

Result: English-language learning package

## Error Recovery

| Error | Cause | Action |
|-------|-------|--------|
| Tavily MCP unavailable | Server not configured or down | Fall back to Exa + WebSearch. Warn user about reduced coverage |
| Exa MCP unavailable | Server not configured or down | Fall back to Tavily + WebSearch |
| Both search MCPs unavailable | Neither configured | Use WebSearch only. Warn: "Research depth is limited to built-in search" |
| NotebookLM auth expired | Token expired | Run `nlm login` via Bash (timeout 120s), then retry |
| Source add fails for a URL | URL blocked or invalid | Log the URL, skip it, continue with remaining sources |
| Source limit (50) hit | Too many sources | Create new notebook with next-tier name, continue adding |
| Studio generation fails | NotebookLM internal error | Retry once. If still fails, report in summary table as "Failed" |
| State file write fails | /tmp permission issue | Continue without state tracking, use in-memory counting |
