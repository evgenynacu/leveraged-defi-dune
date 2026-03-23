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

1. Copy new SQL to clipboard via `javascript_tool` (use `.then()`, not `await`):

```javascript
const sql = `...`;
navigator.clipboard.writeText(sql).then(() => 'OK: ' + sql.length);
```

2. Click inside the editor
3. Select all: Ctrl+A
4. Paste: Ctrl+V
5. Click "Save" or "Save and run" button

### Why this approach

- **Why not `type` action**: detaches on long SQL (>2KB)
- **Why not CM dispatch**: `cmView.view` is not exposed on Dune
- **Why `.then()` not `await`**: async clipboard API throws "Document is not focused" with `await`
- **Virtual scrolling**: CM6 only renders visible lines, so innerText gives partial results
- **Deduplication**: scrolling causes overlapping lines; matching `.cm-line` to `.cm-gutterElement` by `getBoundingClientRect` proximity (< 5px) ensures each line is captured once
