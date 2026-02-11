-- Dune Query 6337968: syrupUSDT real rates (Daily)
-- https://dune.com/queries/6337968

with day_bounds AS (
  SELECT dt as day_start,
         dt + interval '1' day as day_end
      FROM
    UNNEST(sequence(current_date - interval '3' month, current_date, INTERVAL '1' DAY)) t (dt)
), raw_data as (
    select evt_block_time,
           cast(assets_ as double) / cast(shares_ as double) as rate
      from maplefinance_v2_ethereum.pool_v2_evt_withdraw
     where contract_address = 0x356B8d89c1e1239Cbbb9dE4815c39A1474d5BA7D
), data as (
    select rate,
           evt_block_time,
           row_number() over (partition by date_trunc('day', evt_block_time) order by evt_block_time desc) AS rn
      from raw_data
), intervals as (
    select (rate - lag(rate) over (order by evt_block_time)) / rate * 86400 / date_diff('second', lag(evt_block_time) over (order by evt_block_time), evt_block_time) as value,
           rate as open_rate,
           evt_block_time as end_date,
           lag(evt_block_time) over (order by evt_block_time) as begin_date
      from data
     where rn = 1
), overlaps AS (
  SELECT
      d.day_start,
      GREATEST(i.begin_date, d.day_start)       AS overlap_start,
      LEAST(i.end_date,   d.day_end)            AS overlap_end,
      i.value,
      open_rate
  FROM intervals i
  JOIN day_bounds d
    ON i.begin_date < d.day_end
   AND i.end_date   > d.day_start
), weighted AS (
  SELECT
      day_start,
      value,
      open_rate,
      to_unixtime(overlap_end) - to_unixtime(overlap_start) as seconds_inside
  FROM overlaps
)
SELECT day_start AS ts_day,
       SUM(value * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as daily_yield_rate,
       365 * SUM(value * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as apr,
       SUM(open_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as rate
  FROM weighted
 GROUP BY 1
 order by 1 desc
