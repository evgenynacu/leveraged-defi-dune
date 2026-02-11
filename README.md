# Leveraged DeFi Dune Dashboard

SQL queries for the [Leveraged Yield](https://dune.com/enacu/leveraged-yield) Dune dashboard.

This repo serves as a version-controlled source of truth for all dashboard queries, making them easy to edit, review, and sync back to Dune.

## Methodology: PT vs non‑PT
We intentionally split the approach because the yield sources behave differently.

PT (Pendle)

- PT markets provide a current implied rate to expiry.
- Therefore PT is a forward‑looking estimate of a “start‑today” strategy:
  - yield side = current implied daily rate;
  - funding side = MA borrow rate over 1/7/30 days (cost of debt smoothing).
- This is not a backtest and is sensitive to changes in implied rate.

Non‑PT

- There is no forward implied rate; we only have realized daily yield.
- So we run a true backtest: daily yield minus funding cost at the chosen LTV.
- MA7/MA30 are only smoothing of historical daily strategy APR.

Strategy formula (used in both)
APR = 365 * (yield_rate − LTV * borrow_rate) / (1 − LTV)

- For PT: yield_rate = current implied daily rate.
- For non‑PT: yield_rate = realized daily yield.

## Dependency Tree

> `*` = shared dependency, `[ext]` = external author (read-only), `[mv]` = materialized view (`dune.enacu.result_*` table)

- **Leveraged Strategies Overview (Daily) - v3** ([dune](https://dune.com/queries/5514812), [sql](queries/leveraged_strategies_overview___5514812.sql))
  - [PT] Leveraged Strategies data (daily) ([dune](https://dune.com/queries/5514773), [sql](queries/pt_leveraged_strategies_data___5514773.sql))
    - pendle_api_markets `[ext]` `*` ([dune](https://dune.com/queries/4133060), [sql](queries/deps/pendle_api_markets___4133060.sql))
    - Borrow rates (Daily) `*` `[mv]` ([dune](https://dune.com/queries/5333272), [sql](queries/borrow_rates_daily___5333272.sql))
      - Morpho Borrow Rates (Daily) `[mv]` ([dune](https://dune.com/queries/5332727), [sql](queries/morpho_borrow_rates_daily___5332727.sql))
        - USD stablecoins `*` ([dune](https://dune.com/queries/4941025), [sql](queries/usd_stablecoins___4941025.sql))
        - Morpho Markets `*` ([dune](https://dune.com/queries/4939233), [sql](queries/morpho_markets___4939233.sql))
        - Morpho Markets liquidity `*` ([dune](https://dune.com/queries/5358971), [sql](queries/morpho_markets_liquidity___5358971.sql))
        - Collateral Whitelist `*` `[mv]` ([dune](https://dune.com/queries/6681179), [sql](queries/collateral_whitelist___6681179.sql))
          - [Non-PT] Yield daily rates `*`
          - Pendle Active Markets `*` ([dune](https://dune.com/queries/6681680), [sql](queries/pendle_active_markets___6681680.sql))
      - AAVE USD borrow rates (Daily) ([dune](https://dune.com/queries/5339567), [sql](queries/aave_usd_borrow_rates_daily___5339567.sql))
        - AAVE v3 mainnet USD borrow rates ([dune](https://dune.com/queries/4914922), [sql](queries/aave_borrow_rates___4914922.sql))
        - USD stablecoins `*`
      - Euler USD borrow rates (daily) ([dune](https://dune.com/queries/5603135), [sql](queries/euler_borrow_rates_daily___5603135.sql))
        - USD stablecoins `*`
        - Collateral Whitelist `*` `[mv]`
        - Euler Vaults Liquidity `*` ([dune](https://dune.com/queries/5603829), [sql](queries/euler_vaults_liquidity___5603829.sql))
- **[Non-PT] Leveraged Strategies Overview (Daily) - v3** ([dune](https://dune.com/queries/5829876), [sql](queries/non_pt_leveraged_strategies___5829876.sql))
  - [Non-PT] Leveraged Strategies data (daily) ([dune](https://dune.com/queries/5829852), [sql](queries/non_pt_leveraged_strategies_d___5829852.sql))
    - [Non-PT] Yield daily rates ([dune](https://dune.com/queries/5829803), [sql](queries/non_pt_yield_daily_rates___5829803.sql))
      - sUSDe yield rates (Daily) ([dune](https://dune.com/queries/5340278), [sql](queries/susde_yield_rates_daily___5340278.sql))
      - [DEX] sUSDe yield rates (Daily) ([dune](https://dune.com/queries/5829927), [sql](queries/dex_susde_yield_rates___5829927.sql))
      - srUSD yield rates (Daily) ([dune](https://dune.com/queries/5352937), [sql](queries/srusd_yield_rates_daily___5352937.sql))
      - wstUSR yield rates (Daily) ([dune](https://dune.com/queries/5901216), [sql](queries/wstusr_yield_rates_daily___5901216.sql))
      - mHYPER yield rates (Daily) ([dune](https://dune.com/queries/5901329), [sql](queries/mhyper_yield_rates_daily___5901329.sql))
      - mMEV yield rates (Daily) ([dune](https://dune.com/queries/5959288), [sql](queries/mmev_yield_rates_daily___5959288.sql))
      - RLP yield rates (Daily) ([dune](https://dune.com/queries/5953061), [sql](queries/rlp_yield_rates_daily___5953061.sql))
      - syrupUSDC real rates (Daily) ([dune](https://dune.com/queries/5963774), [sql](queries/syrup_yield_rates_daily___5963774.sql))
      - syrupUSDT real rates (Daily) ([dune](https://dune.com/queries/6337968), [sql](queries/syrup_usdt_yield_rates___6337968.sql))
      - sUSDS yield rates (Daily) ([dune](https://dune.com/queries/5995161), [sql](queries/susds_daily_yield_rate___5995161.sql))
      - sDAI yield rates (Daily) ([dune](https://dune.com/queries/5995196), [sql](queries/sdai_daily_yield_rate___5995196.sql))
      - stcUSD yield rates (Daily) ([dune](https://dune.com/queries/6231536), [sql](queries/stcusd_yield_rates_daily___6231536.sql))
      - wsrUSD yield rates (Daily) ([dune](https://dune.com/queries/6256035), [sql](queries/wsrusd_yield_rates_daily___6256035.sql))
    - Borrow rates (Daily) `*` `[mv]`
- **Euler USD borrow rates (hourly)** ([dune](https://dune.com/queries/6164688), [sql](queries/euler_usd_borrow_rates_hourly___6164688.sql))
  - USD stablecoins `*`
  - Euler Vaults Liquidity `*`
- **Morpho Selected Borrow Rates (Hourly)** ([dune](https://dune.com/queries/6207402), [sql](queries/morpho_selected_borrow_rates___6207402.sql))
  - USD stablecoins `*`
  - Morpho Markets `*`
  - Morpho Markets liquidity `*`
