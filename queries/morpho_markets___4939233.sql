-- Dune Query 4939233: Morpho Markets
-- https://dune.com/queries/4939233

select chain blockchain,
       id as market_id,
       from_hex(json_extract_scalar(marketParams, '$.loanToken')) as debt_token,
       from_hex(json_extract_scalar(marketParams, '$.collateralToken')) as collateral_token,
       cast(json_extract_scalar(marketParams, '$.lltv') as double) / pow(10, 18) as max_ltv
  from morpho_blue_multichain.morphoblue_evt_createmarket
