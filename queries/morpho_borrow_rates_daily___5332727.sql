-- Dune Query 5332727: Morpho Borrow Rates (Daily)
-- https://dune.com/queries/5332727

WITH debt_tokens as (
    select blockchain, token_address, 'USD' base_currency from query_4941025
    union all
    select 'ethereum', 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 'ETH'
), collateral_whitelist as (
    select blockchain, token_address from dune.enacu.result_collateral_whitelist
), markets as (
    select m.blockchain,
           m.market_id,
           collateral_token,
           debt_token,
           max_ltv,
           cast(supply as double) / pow(10, t.decimals) as supply,
           cast(borrow as double) / pow(10, t.decimals) as borrow,
           cast(liquidity as double) / pow(10, t.decimals) as liquidity,
           utilization,
           base_currency
      from query_4939233 m
      join query_5358971 l on m.market_id = l.market_id and m.blockchain = l.blockchain
      join tokens.erc20 t on t.contract_address = m.debt_token and t.blockchain = m.blockchain
      join debt_tokens dt on dt.token_address = m.debt_token and dt.blockchain = m.blockchain
      join collateral_whitelist cw on cw.token_address = m.collateral_token
                                  and cw.blockchain = m.blockchain
), filtered_market_ids as (
    select distinct blockchain, market_id from markets
), intervals AS (
    SELECT prevBorrowRate / pow(10, 18) * 365 * 86400 AS borrow_rate,
           prevBorrowRate / pow(10, 18) * 86400 AS daily_borrow_rate,
           evt_block_time end_date,
           lag(evt_block_time) over (partition by chain, id order by evt_block_time) begin_date,
           chain as blockchain,
           id as market_id
      FROM morpho_blue_multichain.morphoblue_evt_accrueinterest
      JOIN filtered_market_ids fm ON fm.market_id = id AND fm.blockchain = chain
     WHERE evt_block_time > current_date - interval '4' month
), calendar AS (
    SELECT dt as day_start,
           dt + interval '1' day as day_end
      FROM
    UNNEST(sequence(current_date - interval '3' month, current_date, INTERVAL '1' DAY)) t (dt)
), overlaps AS (
  SELECT
      d.day_start,
      GREATEST(i.begin_date, d.day_start)       AS overlap_start,
      LEAST(i.end_date,   d.day_end)            AS overlap_end,
      i.borrow_rate,
      i.daily_borrow_rate,
      blockchain,
      market_id
  FROM intervals i
  JOIN calendar d
    ON i.begin_date < d.day_end
   AND i.end_date   > d.day_start
), weighted AS (
  SELECT
      blockchain,
      market_id,
      day_start,
      borrow_rate,
      daily_borrow_rate,
      to_unixtime(overlap_end) - to_unixtime(overlap_start) as seconds_inside
  FROM overlaps
), temp_data as (
    SELECT blockchain,
           market_id,
           day_start AS day,
           SUM(borrow_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as borrow_rate,
           SUM(daily_borrow_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as daily_borrow_rate
    FROM weighted
    GROUP BY blockchain, market_id, day_start
)
select m.blockchain,
       m.market_id,
       supply,
       borrow,
       liquidity,
       utilization,
       day,
       borrow_rate,
       daily_borrow_rate,
       collateral_token,
       debt_token,
       max_ltv,
       m.base_currency,
       cast(m.market_id as varchar) as lending_protocol
  from temp_data
  join markets m on m.market_id = temp_data.market_id and m.blockchain = temp_data.blockchain
