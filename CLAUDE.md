# Leveraged DeFi Dune Dashboard

## Project structure

```
queries/              — own queries (@enacu), editable
queries/deps/         — external queries (other authors), read-only
queries.yml           — dashboard-level query IDs only (for Dune sync)
README.md             — dependency tree with clickable links
.claude/commands/     — slash command skills
.claude/dune-editor.md — CodeMirror read/write reference (used by skills)
```

### Available skills

- `/find-opportunities` — research new yield tokens not yet tracked by the dashboard
- `/add-yield-token` — add a new Non-PT yield token (create query, deploy, refresh matviews, verify)
- `/sync-query` — download a Dune query to local repo or remove one

### File naming (Dune sync format)

```
{name.replace(" ","_").lower()[:30]}___{query_id}.sql
```

Three underscores before the ID. Name truncated to 30 chars, lowercase, spaces → underscores.

### SQL file header

```sql
-- Dune Query {id}: {title}
-- https://dune.com/queries/{id}
```

## Dune platform notes

### Query engine sizes

- **Small**: 120s timeout, 1x compute, standard queue (default)
- **Medium**: Extended timeout, 1x compute, priority queue
- **Large**: Extended timeout, 2x compute, priority queue (unavailable on current plan)

### Saving queries

A new query must be saved via the **Save** button (opens a dialog). Without this, the query is "temporary" and other queries cannot reference it as `query_NNNNNN`.

### Materialized views

- **Create**: icon button in "Query results" section header (between grid/CSV icons)
- **Table name**: `dune.{user}.result_{query_name}`
- **Refresh**: "Save and run" updates both query results and the materialized table
- **Use case**: break "too many stages" errors from deeply nested `query_NNNNNN` dependencies

### README dependency tree format

Nested markdown list (not code block). Conventions: `*` = shared dep, `[ext]` = external author, `[mv]` = materialized view. Dashboard-level queries in **bold**. Links shown only at first occurrence.
