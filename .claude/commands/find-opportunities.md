# Find new yield opportunities not yet tracked by the dashboard

You are researching new leveraged yield opportunities for the [Leveraged Yield](https://dune.com/enacu/leveraged-yield) Dune dashboard.

**Strategy**: deposit yield-bearing token (or PT token) as collateral on a lending protocol, borrow stablecoins, profit from `yield - LTV * borrow_cost`.

**Target position**: ~$100K equity with 5-10x leverage ($500K-$1M effective). Markets must have sufficient depth.

## Step 1: Understand current coverage

Read these files to build a complete picture of what's already tracked:

1. `queries/non_pt_yield_daily_rates___5829803.sql` — extract all tracked Non-PT token addresses, symbols, protocols, and chains
2. `queries/morpho_selected_borrow_rates___6207402.sql` — tokens being monitored for borrow rates (partially tracked, may lack yield rate query)
3. `README.md` — dependency tree including PT coverage

Build a reference table of all tracked token addresses per chain. Mark tokens that are only partially tracked (in borrow monitoring but no yield rate query) as **Type D**.

Also scan for commented-out entries in `morpho_selected_borrow_rates` — these represent previously evaluated but deactivated markets. Note them as context for any related findings.

Flag any currently-tracked tokens that appear on the AVOID list (Step 4) as potential cleanup candidates.

## Step 2: Research lending markets via platform APIs

For each lending protocol, fetch current markets and find ones NOT in our tracked list.

**Important**: Use `javascript_tool` in the browser for API calls (bypasses CORS). WebFetch often fails on DeFi APIs. First call `tabs_context_mcp` and create a tab if needed.

### Morpho Blue

Use `javascript_tool` to fetch from Morpho GraphQL API:

```javascript
// Query per chain with loanAssetAddress_in for USD stablecoins (server-side filter)
// Ethereum stablecoin addresses:
const usdcEth = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const usdtEth = '0xdAC17F958D2ee523a2206206994597C13D831ec7';
const daiEth = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const usdsEth = '0xdC035D45d973E3EC169d2276DDab16f1e407384F';
const pyusdEth = '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8';

fetch('https://blue-api.morpho.org/graphql', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({query: `{
    markets(where: {
      chainId_in: [1],
      supplyAssetsUsd_gte: 1000000,
      loanAssetAddress_in: ["${usdcEth}", "${usdtEth}", "${daiEth}", "${usdsEth}", "${pyusdEth}"]
    }, first: 100) {
      items {
        uniqueKey
        collateralAsset { address symbol name }
        loanAsset { symbol }
        lltv
        state { supplyAssetsUsd borrowAssetsUsd utilization }
      }
      pageInfo { countTotal }
    }
  }`})
}).then(r => r.json()).then(d => {
  const items = d.data.markets.items.filter(m => m.collateralAsset);
  window.__morphoEth = items.map(m => ({
    collateral: m.collateralAsset.symbol,
    collateralName: m.collateralAsset.name,
    collateralAddr: m.collateralAsset.address,
    debt: m.loanAsset.symbol,
    supplyUsd: Math.round(m.state.supplyAssetsUsd),
    lltv: m.lltv,
    utilization: Math.round(m.state.utilization * 10000) / 100,
    key: m.uniqueKey
  }));
  return `Ethereum: ${items.length} markets`;
})
```

Repeat for Arbitrum (chainId 42161, USDC: `0xaf88d065e77c8cC2239327C5EDb3A432268e5831`, USDT: `0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9`) and Base (chainId 8453, USDC: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`).

**Important**: The Morpho API does NOT have `chainId` on the Market type — use `morphoBlue { chain { id } }` if you need it. The `chainId_in` filter works in `where` clauses but not as a return field.

Results may need to be read in chunks via `window.__morphoData = ...` and `window.__morphoData.substring(0, 800)` etc.

**Preserve contract addresses** — `collateralAsset.address` is essential for Dune query creation. Always include it in output.

Filter results:
- Collateral token NOT in tracked list from Step 1
- Group by collateral token, sum supply across all markets

### AAVE v3

Use DeFiLlama pools endpoint via `javascript_tool`:

```javascript
fetch('https://yields.llama.fi/pools')
  .then(r => r.json())
  .then(d => {
    const aave = d.data.filter(p => p.project === 'aave-v3' && p.tvlUsd > 5000000);
    return JSON.stringify(aave.map(p => ({symbol: p.symbol, tvl: Math.round(p.tvlUsd), chain: p.chain, apy: p.apy})).slice(0, 50));
  })
```

Look for yield-bearing tokens used as collateral with TVL > $5M that we don't track.

### Euler v2

Use DeFiLlama:

```javascript
fetch('https://yields.llama.fi/pools')
  .then(r => r.json())
  .then(d => {
    // NOTE: project name is 'euler-v2' (not 'euler')
    const euler = d.data.filter(p => p.project === 'euler-v2' && p.tvlUsd > 1000000);
    return JSON.stringify(euler.map(p => ({symbol: p.symbol, tvl: Math.round(p.tvlUsd), chain: p.chain, apy: p.apy})));
  })
```

### Pendle (for PT tokens)

Use `javascript_tool` to call Pendle API per chain:

```javascript
// Pendle v2 API — paginated, 100 per page. Repeat for chainId 42161 (Arbitrum).
// NOTE: order_by format is "field:-1" (not "field"), e.g. order_by=liquidity_usd:-1
// The response has { total, limit, skip, results: [...] }
async function getAllPendleUSD(chainId) {
  let skip = 0, all = [];
  const usdK = ['USD','DAI','USDC','USDT','GHO','FRAX','RLP','MEV','HYPER','BILL','STABLE'];
  while (true) {
    const r = await fetch(`https://api-v2.pendle.finance/core/v1/${chainId}/markets?limit=100&skip=${skip}`);
    const d = await r.json();
    if (!d.results || d.results.length === 0) break;
    const now = new Date();
    for (const m of d.results) {
      if (!m || !m.expiry || new Date(m.expiry) <= now) continue;
      const liq = m.liquidity?.usd || 0;
      if (liq < 500000) continue;
      const n = ((m.pt?.symbol||'') + ' ' + (m.underlyingAsset?.symbol||'')).toUpperCase();
      if (!usdK.some(k => n.includes(k))) continue;
      all.push({
        name: m.pt?.symbol || m.symbol,
        underlying: m.underlyingAsset?.symbol || 'unknown',
        ptAddr: m.pt?.address,
        liquidity: Math.round(liq),
        impliedApy: m.impliedApy || 0,
        expiry: m.expiry?.substring(0, 10)
      });
    }
    skip += 100;
    if (skip >= d.total) break;
  }
  return all.sort((a,b) => b.liquidity - a.liquidity);
}
Promise.all([getAllPendleUSD(1), getAllPendleUSD(42161)]).then(([eth,arb]) => {
  window.__pendleUSD = {eth, arb};
  return `ETH: ${eth.length}, ARB: ${arb.length} USD markets`;
});
```

Filter: PT underlying NOT already tracked, liquidity > $500K.

### Known yield-bearing stablecoins to verify

Cross-check these known protocols against findings. If any are missing from API results AND not already tracked, investigate manually:

- sUSDf (Falcon Finance) — delta-neutral, ERC-4626, large TVL
- lvlUSD / slvlUSD (Level) — DeFi-native yield
- stUSDS (Sky) — risk capital staking, distinct from sUSDS
- sNUSD (Neutrl) — OTC arbitrage yield
- sUSN (Noon) — delta-neutral + T-bills
- sfrxUSD (Frax) — ERC-4626 vault
- ACRED/sACRED (Apollo) — RWA private credit

All checklist items found in ANY API result should appear in the findings table, even if below threshold. Use LOW or SKIP classification for small markets — this ensures tracking continuity.

This list should be updated after each run with newly discovered tokens.

## Step 3: Classify findings

For each uncovered market found, classify the opportunity:

**Type A - New yield token**: A yield-bearing token used as collateral that we don't track yield rates for. Requires creating a new yield rate query.

**Type B - New PT token**: A Pendle PT wrapping a token we don't track. Requires adding the underlying yield token; PT is handled automatically via Pendle API.

**Type C - New lending market for existing token**: Our tracked token is listed on a lending protocol/chain we don't cover. Only requires extending borrow rate queries.

**Type D - Partially tracked**: Token appears in borrow rate monitoring (`morpho_selected_borrow_rates`) but has no yield rate query. Requires creating the yield rate query to complete integration.

### Market depth assessment

Depth is assessed based on **lending market supply only** (where the leveraged position collateral is held). Pendle/DEX liquidity is separate and does not upgrade the depth classification.

For a $500K-$1M effective position (after leverage):
- **Green**: Lending market supply > $50M (position < 2% of market)
- **Yellow**: Supply $10M-$50M (position 2-10%, manageable)
- **Red**: Supply $5M-$10M (position > 10%, concentration risk)
- **Skip**: Supply < $5M (insufficient for target size)

## Step 4: Liquidity and volatility assessment

### Entry/exit liquidity

For each finding, verify that $500K-$1M worth of the collateral token can be acquired AND liquidated with acceptable slippage (<0.5%). Check:

1. **DEX liquidity**: Use DeFiLlama or 1inch API to check on-chain swap depth for the token
2. **Mint/redeem**: Does the protocol allow direct minting from underlying stablecoins? Is there a cooldown or queue?
3. **Restrictions**: Some tokens (RWA, private credit, tranched) may require KYC, whitelisting, or have lock-up periods that prevent free trading

Classify entry/exit:
- **Open**: Can freely buy/sell on DEXes or mint/redeem without restrictions. Good swap depth.
- **Restricted**: Requires KYC, whitelisting, or institutional access. Cannot be freely acquired.
- **Illiquid**: Token exists on DEXes but with thin liquidity — >1% slippage on $500K swap.
- **Queued**: Mint/redeem available but with cooldown periods (days/weeks).

**Skip or downgrade** any finding where entry/exit is Restricted or Illiquid — even if Morpho TVL is large, we can't use it if we can't get the collateral token.

### Collateral/debt price volatility

With 5-10x leverage, small price deviations between collateral and debt tokens cause amplified P&L swings. A 0.2% collateral depeg with 10x leverage = ~2% instant portfolio loss.

For each finding, assess price stability:
- **Stable**: Token maintains tight peg to USD (±0.05%), e.g. ERC-4626 vaults with atomic redemption
- **Moderate**: Occasional deviations up to ±0.3%, recovers quickly. Viable but requires timing entry.
- **Volatile**: Regular deviations >0.5% or slow recovery. High risk with leverage — need careful entry timing and cannot exit quickly when price moves against position.

Check via:
1. CoinGecko/DeFiLlama price charts — look for depeg events in last 3 months
2. DEX pool depth — thin pools amplify volatility
3. Redemption mechanism — can holders redeem at NAV (stable) or only via secondary market (volatile)?

This does NOT eliminate opportunities — volatile tokens can still be profitable — but it affects:
- When to enter (wait for favorable price)
- Leverage choice (lower leverage for volatile tokens)
- Exit strategy (may need to wait for peg recovery)

## Step 5: Web research and validation

For each Type A finding (new yield token), search the web to understand:
- Protocol background and team
- Yield mechanism (staking, RWA, delta-neutral, etc.)
- Current TVL and APY
- Any red flags (depegs, exploits, wind-downs, regulatory issues)

**Known tokens to AVOID**: See [`avoid-list.md`](../../avoid-list.md) for the full list with detailed reasons and sources.

When you discover a new token that should be avoided, add it to `avoid-list.md` following the template there.

## Step 6: Check on-chain data availability

For each Type A candidate, verify yield rate is computable on-chain:

1. **Primary**: Search Dune spellbook via `mcp__dune__search_spellbook` with protocol name
2. **Fallback**: WebSearch `site:dune.com {token_symbol} yield rate` or `site:dune.com {protocol_name}`
3. **Contract check**: WebSearch Etherscan for the token contract — if verified ERC-4626, Dune has decoded `Deposit`/`Withdraw` events
4. **Public queries**: WebSearch `site:dune.com/queries {token_symbol}`

The standard rate computation pattern: ERC-4626 `Deposit`/`Withdraw` events → `rate = cast(assets as double) / cast(shares as double)`

## Step 7: Present findings

Present findings in this EXACT table format:

| # | Priority | Type | Token | Contract | Protocol | Chain(s) | Morpho TVL | Pendle TVL | Yield est. | Entry/Exit | Peg stability | Depth | Notes |
|---|----------|------|-------|----------|----------|----------|------------|------------|------------|------------|---------------|-------|-------|

Where:
- **Contract**: Token contract address (REQUIRED — extract from API responses)
- **Entry/Exit**: Open / Restricted / Illiquid / Queued (see Step 4)
- **Peg stability**: Stable / Moderate / Volatile (see Step 4)
- **Depth**: Green / Yellow / Red / Skip per market depth assessment above (lending market supply only)
- **Notes**: relationship to existing tracked tokens, red flags, etc.

**Contract addresses are REQUIRED** for all findings. Extract `collateralAsset.address` from Morpho API, `pt.address` from Pendle API, etc. Without addresses, findings are not actionable for Dune query creation.

For HIGH priority items (regardless of Dune status), include a structured block:

```
Token: {symbol}
Contract: {address}
Protocol: {protocol_name}
ERC-4626: Yes/No
Dune table: {decoded_table_name or "needs decoding request"}
Yield source: {mechanism description}
Entry/exit: {Open/Restricted/Illiquid/Queued — explain how to acquire and any restrictions}
Peg stability: {Stable/Moderate/Volatile — recent depeg events, redemption mechanism}
Relationship to tracked: {none / "partially tracked — in morpho_selected_borrow_rates" / etc.}
```

### Coverage summary

After the findings table, include an API coverage report (must include all 3 chains, even if 0 results):

| Chain | Morpho | AAVE | Euler | Pendle |
|-------|--------|------|-------|--------|
| Ethereum | OK/Fail | OK/Fail | ... | ... |
| Arbitrum | ... | ... | ... | ... |
| Base | ... | ... | ... | ... |

## Constraints

- Focus on USD-denominated yield tokens (`base_currency = 'USD'`)
- Minimum lending protocol supply: **$5M** (but prefer Green depth > $50M)
- Minimum PT DEX liquidity: **$500K**
- Chains: ethereum, arbitrum, base
- Do NOT use Dune query editor for research — use platform APIs, web search, and Dune spellbook search
- Use `javascript_tool` for API calls (not WebFetch) to avoid CORS issues
- PT tokens don't need manual yield rate queries (handled via Pendle API)
