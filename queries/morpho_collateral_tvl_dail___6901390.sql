-- Dune Query 6901390: Collateral TVL (Daily)
-- https://dune.com/queries/6901390

with calendar as (
    select dt as ts_day
      from UNNEST(sequence(current_date - interval '3' month, current_date, interval '1' day)) t(dt)

/* ── Morpho ───────────────────────────────────────────── */

), morpho_markets as (
    select m.blockchain,
           m.market_id,
           m.collateral_token,
           m.max_ltv
      from query_4939233 m
      join dune.enacu.result_collateral_whitelist cw
        on cw.token_address = m.collateral_token and cw.blockchain = m.blockchain
), morpho_events as (
    select chain as blockchain,
           id as market_id,
           date_trunc('day', evt_block_time) as ts_day,
           sum(cast(assets as double)) as net_assets
      from morpho_blue_multichain.morphoblue_evt_supplycollateral
     where evt_block_time > current_date - interval '2' year
     group by 1, 2, 3
    union all
    select chain as blockchain,
           id as market_id,
           date_trunc('day', evt_block_time) as ts_day,
           -sum(cast(assets as double)) as net_assets
      from morpho_blue_multichain.morphoblue_evt_withdrawcollateral
     where evt_block_time > current_date - interval '2' year
     group by 1, 2, 3
), morpho_daily_net as (
    select blockchain, market_id, ts_day, sum(net_assets) as net_assets
      from morpho_events
     group by 1, 2, 3
), morpho_cumulative as (
    select blockchain, market_id, ts_day,
           sum(net_assets) over (partition by blockchain, market_id order by ts_day) as total_assets
      from morpho_daily_net
), morpho_per_day as (
    select c.ts_day, m.blockchain, m.market_id, m.collateral_token, m.max_ltv,
           cum.total_assets
      from calendar c
      cross join morpho_markets m
      left join morpho_cumulative cum on cum.market_id = m.market_id
                              and cum.blockchain = m.blockchain
                              and cum.ts_day = c.ts_day
), morpho_grouped as (
    select ts_day, blockchain, market_id, collateral_token, max_ltv, total_assets,
           count(total_assets) over (partition by blockchain, market_id order by ts_day) as grp
      from morpho_per_day
), morpho_filled as (
    select ts_day, blockchain, collateral_token, max_ltv,
           max(total_assets) over (partition by blockchain, market_id, grp) as total_assets
      from morpho_grouped
), morpho_output as (
    select mf.ts_day,
           mf.blockchain,
           mf.collateral_token,
           ct.symbol as collateral_symbol,
           mf.max_ltv,
           mf.total_assets / pow(10, ct.decimals) as collateral_usd,
           mf.total_assets / pow(10, ct.decimals) / (0.8 / (1.0 - mf.max_ltv)) as tvl_usd,
           'morpho' as lending_protocol
      from morpho_filled mf
      join tokens.erc20 ct on ct.contract_address = mf.collateral_token and ct.blockchain = mf.blockchain
     where mf.total_assets > 0

/* ── Aave (per-user pro-rata from query_7382565) ──────── */

), aave_output as (
    select ts_day,
           blockchain,
           collateral_token,
           collateral_symbol,
           max_ltv,
           collateral_usd,
           tvl_usd,
           'aave' as lending_protocol
      from query_7382565

/* ── Combined ─────────────────────────────────────────── */

)
select * from morpho_output
union all
select * from aave_output
order by ts_day desc, tvl_usd desc
