-- Dune Query 7391638: Aave User Daily Events
-- https://dune.com/queries/7391638
-- Materialized as dune.defi_team.result_aave_user_daily_events (daily refresh)
-- Aggregates aToken transfers (collateral) + borrow/repay events (debt) per user/token/side/day

with tracked_collaterals as (
    select blockchain, collateral_token
      from dune.enacu.result_borrow_rates_daily
     where blockchain = 'ethereum'
       and lending_protocol = 'aave'
     group by 1, 2
), atoken_map as (
    select rsv.chain as blockchain,
           rsv.asset as collateral_token,
           rsv.aToken as atoken
      from aave_v3_multichain.poolconfigurator_evt_reserveinitialized rsv
      join tracked_collaterals tc
        on tc.collateral_token = rsv.asset and tc.blockchain = rsv.chain
     where rsv.chain = 'ethereum'
), atoken_transfers as (
    select t.to as user,
           am.collateral_token as token,
           date_trunc('day', t.evt_block_time) as ts_day,
           cast(t.value as double) as net_amount,
           'collateral' as side
      from erc20_ethereum.evt_Transfer t
      join atoken_map am on am.atoken = t.contract_address
     where t.evt_block_time > current_date - interval '3' year
       and t.to <> 0x0000000000000000000000000000000000000000
    union all
    select t."from",
           am.collateral_token,
           date_trunc('day', t.evt_block_time),
           -cast(t.value as double),
           'collateral'
      from erc20_ethereum.evt_Transfer t
      join atoken_map am on am.atoken = t.contract_address
     where t.evt_block_time > current_date - interval '3' year
       and t."from" <> 0x0000000000000000000000000000000000000000
), relevant_users as (
    select distinct user from atoken_transfers where net_amount > 0
), debt_events as (
    select b.onBehalfOf as user,
           b.reserve as token,
           date_trunc('day', b.evt_block_time) as ts_day,
           cast(b.amount as double) as net_amount,
           'debt' as side
      from aave_v3_multichain.pool_evt_borrow b
      join relevant_users ru on ru.user = b.onBehalfOf
     where b.chain = 'ethereum'
       and b.evt_block_time > current_date - interval '3' year
    union all
    select r.user,
           r.reserve,
           date_trunc('day', r.evt_block_time),
           -cast(r.amount as double),
           'debt'
      from aave_v3_multichain.pool_evt_repay r
      join relevant_users ru on ru.user = r.user
     where r.chain = 'ethereum'
       and r.evt_block_time > current_date - interval '3' year
), all_events as (
    select user, token, side, ts_day, net_amount from atoken_transfers
    union all
    select user, token, side, ts_day, net_amount from debt_events
)
select user, token, side, ts_day, sum(net_amount) as net_amount
  from all_events
 group by 1, 2, 3, 4
