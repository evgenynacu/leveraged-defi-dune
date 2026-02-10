-- Dune Query 5829852: [Non-PT] Leveraged Strategies data (daily) - v3
-- https://dune.com/queries/5829852

select yr.blockchain,
       yr.ts_day,
       collateral_token,
       ct.symbol as collateral_token_symbol,
       debt_token,
       dt.symbol as debt_token_symbol,
       daily_yield_rate,
       daily_borrow_rate,
       yield_protocol,
       lending_protocol,
       lending_description,
       label as lending_id,
       max_ltv,
       supply,
       borrow,
       liquidity,
       utilization,
       br.base_currency
  from query_5829803 yr
  join query_5333272 br on yr.ts_day = br.ts_day and yr.token = br.collateral_token
       and br.base_currency = yr.base_currency and yr.blockchain = br.blockchain
  join tokens.erc20 dt on dt.contract_address = debt_token and dt.blockchain = br.blockchain
  join tokens.erc20 ct on ct.contract_address = collateral_token and ct.blockchain = br.blockchain
