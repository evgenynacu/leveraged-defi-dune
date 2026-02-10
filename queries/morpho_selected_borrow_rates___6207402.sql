-- Dune Query 6207402: Morpho Selected Borrow Rates (Hourly)
-- https://dune.com/queries/6207402

WITH included as (
    select 0x3274643db77a064abd3bc851de77556a4ad2e2f502f4f0c80845fa8f909ecf0b as market_id, 'sUSDS/USDT' as name
    -- union all
    -- select 0x7fd694cd13880ce994c61e8f8991ce0c9e321e3d50f548dd62a1b6e610d29f32, 'PT-cUSDO-NOV/USDT'
    -- union all
    -- select 0x802ec6e878dc9fe6905b8a0a18962dcca10440a87fa2242fbf4a0461c7b0c789, 'PT-cUSD-JAN/USDC'
    -- union all
    -- select 0x21b67f89513da0b0c94af8778134a1ba3f762f944f16208b42cc0663b07eaf05, 'PT-iUSD-DEC/USDC'
    -- union all
    -- select 0xe1b65304edd8ceaea9b629df4c3c926a37d1216e27900505c04f14b2ed279f33, 'RLP/USDC'
    union all
    select 0xeb17955ea422baeddbfb0b8d8c9086c5be7a9cfdefb292119a102e981a30062e, 'stcUSD/USDC'
    -- union all
    -- select 0x03f715ef1ae508ab3e1faf4dffdbf2a077d1f0ad10c5aad42cf4438d5e3328af, 'PT-stcUSD-29JAN2026/USDC'
    union all
    select 0xbbf7ce1b40d32d3e3048f5cf27eeaa6de8cb27b80194690aab191a63381d8c99, 'siUSD/USDC'
    -- union all
    -- select 0x32e253d33f1594a67fc6ef51bf7a39cc4bf2d14904998dee769706fcde489ed9, 'wsrUSD/USDC'
    -- union all
    -- select 0xa9f70093360419b4544f17a4553ac5847d896be23f020295bd95c24af4df700e, 'wsrUSD/USDT'
    union all
    select 0x29ae8cad946d861464d5e829877245a863a18157c0cde2c3524434dafa34e476, 'sUSDD/USDT'
), debt_tokens as (
    select blockchain, token_address, 'USD' base_currency from query_4941025
    union all
    select 'ethereum', 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 'ETH'
), markets as (
    select m.blockchain,
           i.name as market_name,
           m.market_id,
           collateral_token,
           debt_token,
           max_ltv,
           cast(supply as double) / pow(10, t.decimals) as supply,
           cast(borrow as double) / pow(10, t.decimals) as borrow,
           cast(liquidity as double) / pow(10, t.decimals) as liquidity,
           utilization,
           'USD' base_currency
      from query_4939233 m
      join query_5358971 l on m.market_id = l.market_id and m.blockchain = l.blockchain
      join tokens.erc20 t on t.contract_address = m.debt_token and t.blockchain = m.blockchain
      join included i on i.market_id = m.market_id
), intervals AS (
    SELECT prevBorrowRate / pow(10, 18) * 365 * 86400 AS borrow_rate,
           prevBorrowRate / pow(10, 18) * 86400 AS daily_borrow_rate,
           evt_block_time end_date,
           lag(evt_block_time) over (partition by chain, id order by evt_block_time) begin_date,
           chain as blockchain,
           id as market_id
      FROM morpho_blue_multichain.morphoblue_evt_accrueinterest
     WHERE evt_block_time > cast('2025-01-01' as timestamp)
), calendar AS (
    SELECT dt as day_start,
           dt + interval '1' hour as day_end
      FROM UNNEST(SEQUENCE(
          CAST(DATE_TRUNC('hour', CURRENT_TIMESTAMP - INTERVAL '30' day) AS TIMESTAMP),
          CAST(DATE_TRUNC('hour', CURRENT_TIMESTAMP) AS TIMESTAMP),
          INTERVAL '1' hour
      )) AS t(dt)
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
       m.market_name,
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
