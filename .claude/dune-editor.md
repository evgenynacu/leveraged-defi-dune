# Dune CodeMirror Editor — Read/Write Reference

Dune uses CodeMirror 6 with virtual scrolling — only visible lines are rendered in the DOM. SQL is not exposed via `__NEXT_DATA__`, global variables, textarea, or `cmView.view.state.doc` (private).

## Reading SQL

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

## Writing SQL (requires login)

> **Never click Save until you have run the verification in step 4.** The failure mode
> here is silent and destructive: a paste that no-ops leaves the editor EMPTY, and
> Ctrl+A has already selected the old content. Saving at that point wipes the query —
> and if it backs a materialized view, everything downstream with it.

1. Click inside the editor (`.cm-content`) to focus it.
2. Select all: Ctrl+A. (Keyboard *selection* works fine — it's the clipboard read that
   is unreliable, not key events in general.)
3. Dispatch a synthetic paste carrying the SQL. This replaces the selection:

```javascript
const sql = `...`;
const target = document.querySelector('.cm-content');
target.focus();
const dt = new DataTransfer();
dt.setData('text/plain', sql);
const handled = !target.dispatchEvent(
    new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true })
);
// handled === true means CodeMirror consumed the event (defaultPrevented).
// handled === false means nothing took the paste — do NOT save.
({ handled, len: sql.length });
```

4. **Verify before saving.** Re-read the editor with `collectAllLines()` from the
   Reading section and compare against what you intended to write — line count at
   minimum, ideally a full string comparison. If it does not match, fix it first.
   Never save on the assumption the paste worked.
5. Click "Save" or "Save and run".
6. Matview-backed queries show an "Update a materialized view" dialog — click
   **Continue with execution**.
7. Confirm it persisted: reload the page. The action button should read "Run" rather
   than "Save and run" (no unsaved changes), and a re-read should show the new SQL.

### Fallback: clipboard + Ctrl+V

The older recipe — `navigator.clipboard.writeText(sql).then(...)`, then Ctrl+A, Ctrl+V —
has been **observed to fail**: `writeText` resolves successfully, but the synthetic
Ctrl+V pastes nothing, leaving the editor empty. Playwright's key event did not reach
the OS clipboard in that session. It has worked historically, so it may be
version-dependent rather than dead. Use it only if the ClipboardEvent dispatch fails,
and apply the same step-4 verification either way.

If you do use it: `.then()`, not `await` — the async clipboard API throws
"Document is not focused" under `await`.

### Why this approach

- **Why ClipboardEvent dispatch**: deterministic, carries the payload in-page, and
  depends on no OS clipboard integration
- **Why not `type` action**: detaches on long SQL (>2KB)
- **Why not CM dispatch**: `cmView.view` is not exposed on Dune
- **Virtual scrolling**: CM6 only renders visible lines, so innerText gives partial results
- **Deduplication**: scrolling causes overlapping lines; matching `.cm-line` to `.cm-gutterElement` by `getBoundingClientRect` proximity (< 5px) ensures each line is captured once
- **Read-back caveat**: `collectAllLines()` reads *rendered* text, so trailing whitespace
  is not recoverable and blank lines come through as empty strings. Fine for verification,
  not byte-exact for round-tripping.
