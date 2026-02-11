-- Dune Query 6681179: Collateral Whitelist
-- https://dune.com/queries/6681179
-- Materialized view: dune.enacu.result_collateral_whitelist (weekly refresh)

select distinct
    blockchain
    , token as token_address
from query_5829803
union
select
    blockchain
    , pt_address
from query_6681680
