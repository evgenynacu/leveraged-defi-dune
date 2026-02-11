-- Dune Query 5514773: [PT] Leveraged Strategies data (daily) - v3
-- https://dune.com/queries/5514773

with pendle_usd_rates as (
    select blockchain,
           pt_address as token,
           'pendle' as yield_protocol,
           'USD' as base_currency,
           expiry,
           liquidity_usd,
           exp(implied_apy / 365) - 1 as implied_daily_rate
      from query_4133060
     where expiry > current_date
       and is_active = true
    -- select blockchain,
    --        pt_address as token,
    --        ts_day,
    --        'pendle' as yield_protocol,
    --        'USD' as base_currency,
    --        expiry,
    --        liquidity_usd,
    --        implied_daily_rate
    --   from query_5513618
) select
       yr.blockchain,
       br.ts_day,
       collateral_token,
       ct.symbol as collateral_token_symbol,
       debt_token,
       dt.symbol as debt_token_symbol,
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
       br.base_currency,
       expiry,
       liquidity_usd,
       implied_daily_rate
  from pendle_usd_rates yr
  join dune.enacu.result_borrow_rates_daily br on
    yr.token = br.collateral_token and
    yr.base_currency = br.base_currency and
    yr.blockchain = br.blockchain
  join tokens.erc20 dt on dt.contract_address = debt_token and dt.blockchain = yr.blockchain
  join tokens.erc20 ct on ct.contract_address = collateral_token and ct.blockchain = yr.blockchain
