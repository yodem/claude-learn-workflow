---
name: learn
description: "Deep learning workflow: research a topic via Tavily + Exa, then generate a full NotebookLM learning package (podcast, infographic, mind map, flashcards). Use when the user wants to learn a new technology, framework, language, or concept in depth. Triggers: /learn, 'learn about', 'research and create', 'deep dive into', 'create a learning package'. Do NOT use for simple web searches or quick questions."
argument-hint: "<topic>"
disable-model-invocation: true
metadata:
  author: Yotam Fromm
  version: 1.2.0
  mcp-server: tavily, exa, notebooklm-mcp
  category: learning
  tags: [research, notebooklm, tavily, exa, podcast, flashcards]
---

# Learn Workflow

## Important

CRITICAL: Follow these steps in exact order. Each phase has a verification gate — do NOT proceed to the next phase until verification passes.

- Default output language is **Hebrew** (`he`). User can override with `--language <code>`
- Max 50 sources per NotebookLM notebook. Track count and overflow to new notebooks

## Instructions

### Phase 0: Discover Available Tools

**This phase is mandatory. Do NOT skip it.**

Before any research, discover which search backends and NotebookLM tools are actually available in this session. Use `ToolSearch` to probe for each backend:

1. `ToolSearch(query="+tavily search")` — look for `mcp__tavily__tavily_search` and `mcp__tavily__tavily_extract`
2. `ToolSearch(query="+exa search")` — look for `mcp__exa__web_search_exa` and `mcp__exa__crawling_exa`
3. `ToolSearch(query="+notebooklm")` — look for `mcp__notebooklm-mcp__notebook_create`, `mcp__notebooklm-mcp__source_add`, `mcp__notebooklm-mcp__studio_create`, `mcp__notebooklm-mcp__studio_status`

Run all 3 searches in parallel.

Set flags based on results:
- `HAS_TAVILY` = true if `mcp__tavily__tavily_search` was found
- `HAS_EXA` = true if `mcp__exa__web_search_exa` was found
- `HAS_NOTEBOOKLM` = true if NotebookLM tools were found

**Tell the user which backends are available:**

```
Research backends: [Tavily ✓/✗] [Exa ✓/✗] [WebSearch ✓ (built-in)]
NotebookLM: [✓/✗]
```

**If ANY required backend is missing, STOP the workflow immediately.** Do NOT fall back to WebSearch. Do NOT proceed to Phase 1. Instead, show the user exactly what's missing and how to fix it:

If Tavily is missing:
> **Tavily is not connected.** This is likely because `TAVILY_API_KEY` is not set in your shell environment.
>
> To fix:
> 1. Get a free API key at https://tavily.com
> 2. Add `export TAVILY_API_KEY="your-key-here"` to your `~/.zshrc` (or `~/.bashrc`)
> 3. Run `source ~/.zshrc` and **restart Claude Code**
>
> **Do not paste your API key in this chat.**

If Exa is missing:
> **Exa is not connected.** This is likely because `EXA_API_KEY` is not set in your shell environment.
>
> To fix:
> 1. Get an API key at https://exa.ai
> 2. Add `export EXA_API_KEY="your-key-here"` to your `~/.zshrc` (or `~/.bashrc`)
> 3. Run `source ~/.zshrc` and **restart Claude Code**
>
> **Do not paste your API key in this chat.**

If NotebookLM is missing:
> **NotebookLM is not connected.** Install it from https://github.com/nicholasgriffintn/notebooklm-mcp and run `nlm login` to authenticate.

After showing the missing tools, end with:
> Run `/learn-toolkit:learn $ARGUMENTS` again after fixing the above.

**Verification gate:** ALL three backends must be available: Tavily ✓, Exa ✓, NotebookLM ✓. If any are missing, the workflow STOPS here with setup instructions. Do NOT continue.

### Phase 1: Parallel Research

Research **$ARGUMENTS** across all **available** backends simultaneously. Only use backends where the corresponding flag from Phase 0 is true.

**If HAS_TAVILY:**
- `mcp__tavily__tavily_search(query="$ARGUMENTS", search_depth="advanced", include_raw_content=true)`
- `mcp__tavily__tavily_search(query="$ARGUMENTS tutorial guide 2025 2026", search_depth="advanced", include_raw_content=true)`
- After searches complete, extract top 3-5 most valuable URLs via `mcp__tavily__tavily_extract` if that tool is available

**If HAS_EXA:**
- `mcp__exa__web_search_exa(query="$ARGUMENTS documentation")`
- `mcp__exa__web_search_exa(query="$ARGUMENTS architecture patterns examples")`
- Crawl top 2-3 most valuable URLs via `mcp__exa__crawling_exa`

**Verification gate:** At least 5 unique URLs collected across all backends. If fewer, run additional queries with broader terms before proceeding.

### Phase 2: Organize and Verify

1. Deduplicate URLs across all backends
2. Categorize: official docs > tutorials > blog posts > code repos > comparisons
3. Write a 500-word research summary synthesizing key findings from search result snippets and any fetched content
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

### Example 1: All backends available

User says: `/learn Next.js App Router`

Actions:
1. Phase 0: ToolSearch finds Tavily ✓, Exa ✓, NotebookLM ✓
2. Tavily searches for "Next.js App Router" and "Next.js App Router tutorial guide 2025 2026"
3. Exa searches for "Next.js App Router documentation" and "Next.js App Router architecture patterns"
4. Collects 23 unique URLs, deduplicates to 19
5. Creates "Next.js App Router - Core Learning" notebook, adds all 19 URLs + research summary
6. Generates podcast, infographic, mind map, flashcards in Hebrew
7. Polls until complete, presents summary table

Result: Learning package with 1 notebook, 19 sources, 4 artifacts

### Example 2: Missing backends — workflow stops

User says: `/learn Kafka event streaming` (no Tavily/Exa configured)

Actions:
1. Phase 0: ToolSearch finds Tavily ✗, Exa ✗, NotebookLM ✓
2. Workflow STOPS — displays setup instructions for Tavily and Exa
3. User sets env vars, restarts Claude Code, runs `/learn-toolkit:learn Kafka event streaming` again

Result: No research performed. User gets clear fix instructions.

### Example 3: Overflow to multiple notebooks

User says: `/learn Kubernetes`

Actions:
1. Research yields 65 unique URLs across all backends
2. Creates "Kubernetes - Core Learning" (48 sources)
3. Creates "Kubernetes - Deep Dive" (17 sources + research summary)
4. Generates 4 artifacts per notebook (8 total)

Result: Learning package with 2 notebooks, 65 sources, 8 artifacts

### Example 4: Language override

User says: `/learn GraphQL federation --language en`

Actions: Same workflow, but all NotebookLM artifacts use `language="en"` instead of `"he"`

Result: English-language learning package

## Error Recovery

| Error | Cause | Action |
|-------|-------|--------|
| Tavily MCP not found in ToolSearch | Server not configured, API key missing, or MCP not connected | **STOP workflow.** Show Tavily setup instructions. Do NOT fall back to WebSearch |
| Exa MCP not found in ToolSearch | Server not configured, API key missing, or MCP not connected | **STOP workflow.** Show Exa setup instructions. Do NOT fall back to WebSearch |
| NotebookLM not found in ToolSearch | MCP not configured | **STOP workflow.** Show NotebookLM setup instructions |
| NotebookLM auth expired | Token expired | Run `nlm login` via Bash (timeout 120s), then retry |
| Source add fails for a URL | URL blocked or invalid | Log the URL, skip it, continue with remaining sources |
| Source limit (50) hit | Too many sources | Create new notebook with next-tier name, continue adding |
| Studio generation fails | NotebookLM internal error | Retry once. If still fails, report in summary table as "Failed" |
| State file write fails | /tmp permission issue | Continue without state tracking, use in-memory counting |
