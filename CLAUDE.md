# Leveraged DeFi Dune Dashboard

## Project structure

```
queries/              — own queries (@enacu), editable
queries/deps/         — external queries (other authors), read-only
queries.yml           — dashboard-level query IDs only (for Dune sync)
README.md             — dependency tree with clickable links
```

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

## Workflows

### Adding a new query

1. Open query on Dune, read SQL via Chrome extension (see below)
2. Save with correct filename and header to `queries/`
3. Find dependencies: search for `query_NNNNNN` references in the SQL
4. Recursively download each dependency:
   - Check author on Dune page (breadcrumb near query title)
   - Own queries (@enacu) → `queries/`
   - External authors → `queries/deps/` (placeholder with header only if content blocked)
5. Update dependency tree in README.md
6. If dashboard-level query → add to `queries.yml`

### Removing a query

1. Grep all `.sql` files for the query ID to check if other queries depend on it
2. Only remove if no other query references it (or remove the whole subtree)
3. For each dependency of the removed query: check if it's shared (`*` in tree) — only delete if no other query uses it
4. Remove files, update README dependency tree
5. If dashboard-level → remove from `queries.yml`

### Updating README dependency tree

Format: nested markdown list (not code block — links must be clickable).

```markdown
- **Query Name** ([dune](https://dune.com/queries/ID), [sql](queries/filename.sql))
  - Dependency Name ([dune](...), [sql](...))
    - Shared dep `*` ([dune](...), [sql](...))
```

Conventions:
- `*` = shared dependency (used by multiple parent queries)
- `[ext]` = external author (read-only, lives in `queries/deps/`)
- Links shown only at first occurrence; subsequent mentions show just the name + markers
- Dashboard-level queries in **bold**

## Reading SQL from Dune via Chrome extension

Dune uses CodeMirror 6 with virtual scrolling — only visible lines are rendered in the DOM. Login status does not change the approach: SQL is not exposed via `__NEXT_DATA__`, global variables, textarea, or `cmView.view.state.doc` (private).

### Reading SQL

1. Run the scroll-and-collect script via `javascript_tool`:

```javascript
async function collectAllLines() {
    const scroller = document.querySelector('.cm-scroller');
    const allLines = new Map();
    const steps = 20;
    const stepSize = scroller.scrollHeight / steps;
    for (let i = 0; i <= steps; i++) {
        scroller.scrollTop = i * stepSize;
        await new Promise(r => setTimeout(r, 100));
        const gutters = document.querySelectorAll('.cm-gutterElement');
        const lines = document.querySelectorAll('.cm-line');
        lines.forEach(line => {
            const lr = line.getBoundingClientRect();
            for (const g of gutters) {
                if (Math.abs(g.getBoundingClientRect().top - lr.top) < 5) {
                    const num = parseInt(g.textContent);
                    if (num && !allLines.has(num)) allLines.set(num, line.textContent);
                    break;
                }
            }
        });
    }
    const sorted = [...allLines.entries()].sort((a,b) => a[0] - b[0]);
    window.__fullSQL = sorted.map(([_, t]) => t).join('\n');
    return { totalLines: sorted.length, len: window.__fullSQL.length };
}
collectAllLines();
```

For very long queries (100+ lines), increase `steps` to 40.

2. Read result in chunks (~800 chars per call due to MCP output limit):

```javascript
window.__fullSQL.substring(0, 800)
window.__fullSQL.substring(800, 1600)
// ...etc
```

### Writing SQL back (requires login)

1. Copy new SQL to clipboard via `javascript_tool` (use `.then()`, not `await`):

```javascript
const sql = `...`;
navigator.clipboard.writeText(sql).then(() => 'OK: ' + sql.length);
```

2. Click inside the editor
3. Select all: Ctrl+A
4. Paste: Ctrl+V
5. Click "Save" or "Save and run" button

**Why not `type` action**: detaches on long SQL (>2KB).
**Why not CM dispatch**: `cmView.view` is not exposed on Dune.
**Why `.then()` not `await`**: async clipboard API throws "Document is not focused" with `await`.

### Why this approach

- **Virtual scrolling**: CM6 only renders visible lines, so innerText gives partial results
- **Deduplication**: scrolling causes overlapping lines; matching `.cm-line` to `.cm-gutterElement` by `getBoundingClientRect` proximity (< 5px) ensures each line is captured once
- **No simpler API**: `cmView.view.state.doc` is not exposed; `__NEXT_DATA__` contains only metadata; textarea is empty; no global variable holds the SQL
