-- Dune Query 5829876: [Non-PT] Leveraged Strategies Overview (Daily) - v3
-- https://dune.com/queries/5829876

with raw_data as (
    select * from query_5829852
), data as (
    select blockchain,
           collateral_token_symbol as yield_description,
           (daily_yield_rate - {{ltv}} * daily_borrow_rate) / (1 - {{ltv}}) as daily_strategy_apr,
           AVG((daily_yield_rate - {{ltv}} * daily_borrow_rate) / (1 - {{ltv}})) OVER (PARTITION BY blockchain, yield_protocol, lending_protocol, lending_description, collateral_token, debt_token ORDER BY ts_day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as ma7_daily_strategy_apr,
           AVG((daily_yield_rate - {{ltv}} * daily_borrow_rate) / (1 - {{ltv}})) OVER (PARTITION BY blockchain, yield_protocol, lending_protocol, lending_description, collateral_token, debt_token ORDER BY ts_day ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as ma30_daily_strategy_apr,
           AVG(daily_borrow_rate) OVER (PARTITION BY blockchain, yield_protocol, lending_protocol, lending_description, collateral_token, debt_token ORDER BY ts_day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as ma7_daily_borrow_rate,
           AVG(daily_borrow_rate) OVER (PARTITION BY blockchain, yield_protocol, lending_protocol, lending_description, collateral_token, debt_token ORDER BY ts_day ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) as ma30_daily_borrow_rate,
           max_ltv,
           utilization,
           supply,
           debt_token_symbol as debt_token,
           lending_description,
           ts_day last_updated,
           lending_id,
           lending_protocol,
           row_number() OVER (PARTITION BY blockchain, yield_protocol, lending_protocol, lending_description, collateral_token, debt_token ORDER BY ts_day desc) as rn
      from raw_data d
     where (supply > 100000 or lending_protocol = 'aave' or base_currency = 'ETH')
)
select blockchain,
       yield_description,
       daily_strategy_apr * 365 as strategy_apr,
       ma7_daily_strategy_apr * 365 as ma7_strategy_apr,
       ma30_daily_strategy_apr * 365 as ma30_strategy_apr,
       max_ltv,
       utilization,
       supply,
       debt_token,
       lending_description,
       last_updated,
       lending_id
  from data
 where rn = 1
 order by ma30_daily_strategy_apr desc
