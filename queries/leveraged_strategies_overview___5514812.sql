-- Dune Query 5514812: Leveraged Strategies Overview (Daily) - v3
-- https://dune.com/queries/5514812

with raw_data as (
    select * from query_5514773
), data as (
    select blockchain,
           collateral_token_symbol as yield_description,
           daily_borrow_rate,
           AVG(daily_borrow_rate) OVER (PARTITION BY blockchain, yield_protocol, lending_protocol, lending_description, collateral_token, debt_token ORDER BY ts_day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as ma7_daily_borrow_rate,
           AVG(daily_borrow_rate) OVER (PARTITION BY blockchain, yield_protocol, lending_protocol, lending_description, collateral_token, debt_token ORDER BY ts_day ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as ma30_daily_borrow_rate,
           max_ltv,
           utilization,
           supply,
           debt_token_symbol as debt_token,
           lending_description,
           ts_day last_updated,
           lending_id,
           expiry,
           liquidity_usd,
           implied_daily_rate,
           lending_protocol,
           row_number() OVER (PARTITION BY blockchain, yield_protocol, lending_protocol, lending_description, collateral_token, debt_token ORDER BY ts_day desc) as rn
      from raw_data d
     where (supply > 100000 or lending_protocol = 'aave' or base_currency = 'ETH')
)
select blockchain,
       yield_description,
       365 * (implied_daily_rate - {{ltv}} * daily_borrow_rate) / (1 - {{ltv}}) as implied_apr_1,
       365 * (implied_daily_rate - {{ltv}} * ma7_daily_borrow_rate) / (1 - {{ltv}}) as implied_apr_7,
       365 * (implied_daily_rate - {{ltv}} * ma30_daily_borrow_rate) / (1 - {{ltv}}) as implied_apr_30,
       date_diff('day', now(), expiry) as days_left,
       implied_daily_rate * 365 as implied_rate,
       liquidity_usd,
       max_ltv,
       utilization,
       supply,
       debt_token,
       lending_description,
       last_updated,
       lending_id
  from data
 where rn = 1
   and date_diff('day', now(), expiry) > {{days_left}}
 order by 4 desc
