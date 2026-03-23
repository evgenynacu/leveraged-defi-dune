# Add a new Non-PT yield token to the dashboard

You are adding a new yield-bearing token to the [Leveraged Yield](https://dune.com/enacu/leveraged-yield) Dune dashboard's Non-PT section.

**Input**: The user will provide the token symbol, contract address, protocol name, and chain. They may also provide hints about the yield mechanism.

## Step 1: Research the token's yield mechanism

Determine how to compute the daily yield rate on-chain:

### Pattern A: ERC-4626 vault (most common)
Rate = `cast(assets as double) / cast(shares as double)` from Deposit events.

1. Search Dune for decoded tables: `mcp__dune__search_spellbook` with protocol name
2. Check if `{namespace}_ethereum.{Contract}_evt_Deposit` exists with `assets` and `shares` columns via `mcp__dune__get_table_schema`
3. Template: copy pattern from `queries/siusd_yield_rates_daily___6685146.sql` or `queries/stcusd_yield_rates_daily___6231536.sql`

### Pattern B: Hardcoded dsr/rate (governance-only changes)
For tokens using MakerDAO-style pot/dsr mechanism where rate changes only on governance updates.

1. Find the pot/rate contract via RPC (`eth_call` to the token contract)
2. Read current dsr via `eth_call` to the pot contract
3. Binary-search historical rate changes using archive RPC (`ethereum-rpc.publicnode.com` — supports archive state; `llamarpc` does NOT)
4. Hardcode rates in a CASE statement: `power(dsr, 86400) - 1` for daily rate
5. Template: `queries/susdd_yield_rates_daily___6685310.sql`

**Zero table scans, 0s execution.** Requires manual update when governance changes the rate.

### Tables to AVOID (too expensive)
- **`ethereum.logs`** — raw logs, very large, expensive credits
- **`erc20_ethereum.evt_Transfer`** — billions of rows, slow even with filters
- Always prefer decoded contract-specific tables or hardcoded values

## Step 2: Create the yield rate query

1. Write SQL locally as `queries/{name}___NEW.sql` following the file header format:
```sql
-- Dune Query NEW: {token} yield rates (Daily)
-- https://dune.com/queries/NEW
```

2. The query MUST output at least: `ts_day`, `daily_yield_rate`
3. Use `UNNEST(sequence(current_date - interval '3' month, current_date, INTERVAL '1' DAY))` for the date range
4. Order by `ts_day desc`

## Step 3: Deploy to Dune

1. Navigate to `dune.com/queries` and create a new query
2. Paste SQL via clipboard (see `.claude/dune-editor.md` for the read/write technique)
3. Run the query to verify results
4. Save with name "{token} yield rates (Daily)" via the Save dialog
5. Note the query ID from the URL

## Step 4: Update local files

1. **Rename**: `queries/{name}___NEW.sql` → `queries/{name}___{id}.sql`
2. **Update header**: replace `NEW` with actual query ID in the file header
3. **Update `non_pt_yield_daily_rates___5829803.sql`**:
   - Add a CTE before the closing `)`:
     ```sql
     ), {token}_rates as (
         select '{chain}' as blockchain,
                {token_address} as token,
                ts_day,
                daily_yield_rate,
                '{protocol}' as yield_protocol,
                'USD' as base_currency
           from query_{id}
     )
     ```
   - Add `union all select * from {token}_rates` at the bottom
4. **Deploy** updated `non_pt_yield_daily_rates` to Dune (clipboard paste → Ctrl+A → Ctrl+V → Save and run)

## Step 5: Refresh matview chain

Order matters — each step depends on the previous one completing:

1. **Collateral Whitelist** (6681179) — trivial edit (Enter in editor) + "Save and run" + confirm "Update a materialized view" dialog by clicking "Continue with execution"
2. **Morpho Borrow Rates Daily** (5332727) — **select Medium engine** from Run dropdown first, then "Save and run" + confirm matview dialog. Takes ~1min.
3. **Borrow Rates Daily** (5333272) — trivial edit + "Save and run" + confirm matview dialog. Takes ~40s.

**Trivial edit trick**: click in editor → End → Enter (adds blank line). This makes the button switch from "Run" to "Save and run".

## Step 6: Verify

1. Run **Non-PT Leveraged Strategies Overview** (5829876)
2. Search for the token symbol in the results table
3. Verify it has: `strategy_apr`, `ma7_strategy_apr`, `ma30_strategy_apr`, `max_ltv`, `utilization`, `supply`
4. If the token does NOT appear, check:
   - Is the token in `morpho_selected_borrow_rates` (6207402)? If not, there's no borrow market for it.
   - Does the collateral whitelist include the token address? Re-run step 5.1.

## Step 7: Update README

Add the new yield rate query to the dependency tree in README.md under `[Non-PT] Yield daily rates`:
```markdown
      - {token} yield rates (Daily) ([dune](https://dune.com/queries/{id}), [sql](queries/{filename}.sql))
```

## Reference: existing yield rate queries

| Pattern | Example file | Mechanism |
|---------|-------------|-----------|
| ERC-4626 Deposit events | `siusd_yield_rates_daily___6685146.sql` | `assets/shares` from decoded Deposit |
| ERC-4626 weighted intervals | `stcusd_yield_rates_daily___6231536.sql` | Time-weighted rate changes within days |
| Hardcoded dsr | `susdd_yield_rates_daily___6685310.sql` | CASE on date, `power(dsr, 86400) - 1` |
| DEX price-based | `dex_susde_yield_rates___5829927.sql` | DEX trade prices for rate estimation |
| DSR from on-chain | `susds_daily_yield_rate___5995161.sql` | Reads pot/dsr from decoded contract events |
