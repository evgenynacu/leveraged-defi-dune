-- Dune Query 5333272: Borrow rates (Daily)
-- https://dune.com/queries/5333272

with morpho_borrow_rates as (
    select blockchain, day as ts_day, supply, borrow, liquidity, utilization, collateral_token, debt_token, max_ltv, borrow_rate, daily_borrow_rate, 'morpho' as lending_protocol, lending_protocol as lending_description, base_currency from dune.enacu.result_morpho_borrow_rates_daily
), aave_usd_borrow_rates as (
    select blockchain, ts_day, 0, 0, 0, 0, collateral_token, debt_token, max_ltv, borrow_rate, borrow_rate / 365, 'aave', 'Aave', 'USD' from query_5339567
), euler_borrow_rates as (
    select 'ethereum', day, supply, borrow, liquidity, utilization, collateral_token, debt_token, max_ltv, borrow_rate, daily_borrow_rate, 'euler', "right"("left"(cast(debt_vault as varchar), 6), 4) || '-' || "right"("left"(cast(collateral_vault as varchar), 6), 4), base_currency
      from query_5603135
), all as (
    select * from morpho_borrow_rates
    union all select * from aave_usd_borrow_rates
    union all select * from euler_borrow_rates
)
select ct.symbol || '/' || dt.symbol || '-' || "left"(lending_description, 10) as label,
       ct.symbol as collateral_symbol,
       dt.symbol as debt_symbol,
       a.*
  from all a
  join tokens.erc20 ct on ct.contract_address = collateral_token and ct.blockchain = a.blockchain
  join tokens.erc20 dt on dt.contract_address = debt_token and dt.blockchain = a.blockchain
