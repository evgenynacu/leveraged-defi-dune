-- Dune Query 7382565: Aave Per-User Pro-Rata TVL (Daily)
-- https://dune.com/queries/7382565

with calendar as (
    select dt as ts_day
      from UNNEST(sequence(current_date - interval '3' month, current_date, interval '1' day)) t(dt)
), tracked_collaterals as (
    select blockchain, collateral_token, max(max_ltv) as max_ltv
      from dune.enacu.result_borrow_rates_daily
     where blockchain = 'ethereum'
       and lending_protocol = 'aave'
     group by 1, 2
), daily_net_raw as (
    /* heavy aggregation pre-computed in matview */
    select user, token, side, ts_day, net_amount
      from dune.defi_team.result_aave_user_daily_events
), calendar_start as (
    select min(ts_day) as start_day from calendar
), initial_balance as (
    /* кумулятив на день перед началом calendar — для юзеров с events до calendar window */
    select user, token, side,
           (select start_day from calendar_start) - interval '1' day as ts_day,
           sum(net_amount) as net_amount
      from daily_net_raw
     where ts_day < (select start_day from calendar_start)
     group by 1, 2, 3
), daily_net as (
    select * from initial_balance
    union all
    select user, token, side, ts_day, net_amount from daily_net_raw
     where ts_day >= (select start_day from calendar_start)
), cumulative as (
    select user, token, side, ts_day,
           sum(net_amount) over (partition by user, token, side order by ts_day) as cum_amount
      from daily_net
), user_token_sides as (
    select distinct user, token, side from daily_net
), calendar_extended as (
    /* добавляем calendar_start - 1 day чтобы LOCF подхватил initial_balance */
    select (select start_day from calendar_start) - interval '1' day as ts_day
    union all
    select ts_day from calendar
), per_day as (
    select c.ts_day, p.user, p.token, p.side, cum.cum_amount
      from calendar_extended c
      cross join user_token_sides p
      left join cumulative cum
        on cum.user = p.user and cum.token = p.token and cum.side = p.side and cum.ts_day = c.ts_day
), filled as (
    select ts_day, user, token, side, cum_amount,
           count(cum_amount) over (partition by user, token, side order by ts_day) as grp
      from per_day
), positions_locf as (
    select ts_day, user, token, side,
           coalesce(max(cum_amount) over (partition by user, token, side, grp), 0) as cum_amount
      from filled
), positions as (
    /* фильтруем ПОСЛЕ LOCF — иначе initial_balance на (start_day - 1) теряется до вычисления окна */
    select * from positions_locf
     where ts_day >= (select start_day from calendar_start)
), positions_usd as (
    select p.ts_day, p.user, p.token, p.side,
           p.cum_amount / pow(10, t.decimals) as usd
      from positions p
      join tokens.erc20 t on t.contract_address = p.token and t.blockchain = 'ethereum'
     where p.cum_amount > 0

/* ── фильтруем юзеров с non-USD collateral (WETH, WBTC и т.п.) ── */

), usd_tokens as (
    /* все tracked collaterals + debt tokens из matview (избегаем deep nesting query_5339567) */
    select distinct collateral_token as token from dune.enacu.result_borrow_rates_daily
     where blockchain = 'ethereum' and lending_protocol = 'aave'
    union
    select distinct debt_token from dune.enacu.result_borrow_rates_daily
     where blockchain = 'ethereum' and lending_protocol = 'aave'
), mixed_user_days as (
    /* per-day: юзер «mixed» если на этот день держит non-USD токен */
    select distinct ts_day, user
      from positions_usd
     where token not in (select token from usd_tokens)
), user_totals as (
    select ts_day, user, side, sum(usd) as total_usd
      from positions_usd pu
     where not exists (
         select 1 from mixed_user_days m
          where m.ts_day = pu.ts_day and m.user = pu.user
     )
     group by 1, 2, 3
), pro_rata as (
    select pu.ts_day,
           pu.token as collateral_token,
           tc.max_ltv,
           pu.usd as collateral_usd,
           coalesce(udt.total_usd, 0) * (pu.usd / uct.total_usd) as attributed_debt_usd
      from positions_usd pu
      join tracked_collaterals tc on tc.collateral_token = pu.token
      join user_totals uct on uct.user = pu.user and uct.ts_day = pu.ts_day and uct.side = 'collateral'
      left join user_totals udt on udt.user = pu.user and udt.ts_day = pu.ts_day and udt.side = 'debt'
     where pu.side = 'collateral'
       and coalesce(udt.total_usd, 0) > 0  /* только leveraged users (с долгом) */
), aggregated as (
    select ts_day, collateral_token, max_ltv,
           sum(collateral_usd) as collateral_usd,
           sum(attributed_debt_usd) as attributed_debt_usd
      from pro_rata
     group by 1, 2, 3
)
select 'ethereum' as blockchain,
       a.ts_day,
       a.collateral_token,
       t.symbol as collateral_symbol,
       a.max_ltv,
       a.collateral_usd,
       a.attributed_debt_usd,
       a.attributed_debt_usd / (0.8 / (1.0 - a.max_ltv) - 1.0) as tvl_usd
  from aggregated a
  join tokens.erc20 t on t.contract_address = a.collateral_token and t.blockchain = 'ethereum'
 where a.attributed_debt_usd > 0
 order by ts_day desc, tvl_usd desc
