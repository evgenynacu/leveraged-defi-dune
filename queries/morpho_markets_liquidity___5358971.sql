-- Dune Query 5358971: Morpho Markets liquidity
-- https://dune.com/queries/5358971

with supply as (
    select chain as blockchain, id as market_id, shares, cast(assets as double) / cast(shares as double) as price, evt_block_time
      from morpho_blue_multichain.morphoblue_evt_supply
    union all
    select chain, id, -shares, cast(assets as double) / cast(shares as double) as price, evt_block_time
      from morpho_blue_multichain.morphoblue_evt_withdraw
), supply_prices as (
    select blockchain, market_id, price, row_number() over (partition by blockchain, market_id order by evt_block_time desc) as rn
      from supply
), last_supply_price as (
    select blockchain, market_id, price
      from supply_prices
     where rn = 1
), total_supply as (
    select blockchain, market_id, sum(shares) shares
      from supply
     group by blockchain, market_id
), borrow as (
    select chain as blockchain, id as market_id, shares, cast(assets as double) / cast(shares as double) as price, evt_block_time
      from morpho_blue_multichain.morphoblue_evt_borrow
    union all
    select chain as blockchain, id, -shares, cast(assets as double) / cast(shares as double) as price, evt_block_time
      from morpho_blue_multichain.morphoblue_evt_repay
), borrow_prices as (
    select blockchain, market_id, price, row_number() over (partition by blockchain, market_id order by evt_block_time desc) as rn
      from borrow
), last_borrow_price as (
    select blockchain, market_id, price
      from borrow_prices
     where rn = 1
), total_borrow as (
    select blockchain, market_id, sum(shares) shares
      from borrow
     group by blockchain, market_id
), raw_data as (
    select s.blockchain,
           s.market_id,
           sp.price * s.shares as supply,
           bp.price * b.shares as borrow
      from total_supply s
      join last_supply_price sp on sp.market_id = s.market_id and sp.blockchain = s.blockchain
      join total_borrow b on b.market_id = s.market_id and b.blockchain = s.blockchain
      join last_borrow_price bp on bp.market_id = s.market_id and bp.blockchain = s.blockchain
)
select blockchain,
       market_id,
       supply,
       borrow,
       supply - borrow as liquidity,
       cast(borrow as double) / cast(supply as double) as utilization
  from raw_data
