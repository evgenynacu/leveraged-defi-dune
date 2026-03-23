# Sync a Dune query to local repo

Download a Dune query (or remove a local query), keeping the local repo in sync.

**Input**: Dune query URL or ID, or a request to remove a query.

## Adding a query

1. **Navigate** to the query on Dune in the browser
2. **Read SQL** using the CodeMirror scroll-and-collect technique (see `.claude/dune-editor.md`)
3. **Save locally** with correct filename and header (see CLAUDE.md for naming format):
   - Check author on Dune page (breadcrumb near query title):
     - Own queries (@enacu) → `queries/`
     - External authors → `queries/deps/` (placeholder with header only if content blocked)
4. **Find dependencies**: search for `query_NNNNNN` references in the SQL
5. **Recursively download** each dependency (repeat steps 1-4)
6. **Update README.md** dependency tree:
   - Format: nested markdown list (not code block — links must be clickable)
   - `*` = shared dependency, `[ext]` = external author, `[mv]` = materialized view
   - Links shown only at first occurrence; subsequent mentions show just the name + markers
   - Dashboard-level queries in **bold**
7. If dashboard-level query → add to `queries.yml`

## Removing a query

1. **Check dependents**: grep all `.sql` files for the query ID
2. Only remove if no other query references it (or remove the whole subtree)
3. For each dependency: check if shared (`*` in tree) — only delete if no other query uses it
4. Remove files, update README dependency tree
5. If dashboard-level → remove from `queries.yml`
