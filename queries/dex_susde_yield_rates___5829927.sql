-- Dune Query 5829927: [DEX] sUSDe yield rates (Daily)
-- https://dune.com/queries/5829927

with day_bounds AS (
  SELECT dt as day_start,
         dt + interval '1' day as day_end
      FROM
    UNNEST(sequence(date '2025-01-01', current_date, INTERVAL '1' DAY)) t (dt)
), data as (
    SELECT a.block_time as evt_block_time,
           a.price as rate,
           row_number() over (partition by date_trunc('day', block_time) order by block_time desc) AS rn
      FROM dex.prices_block a
     WHERE blockchain = 'ethereum'
       AND a.contract_address = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497
), intervals as (
    select (rate - lag(rate) over (order by evt_block_time)) / rate * 86400 / date_diff('second', lag(evt_block_time) over (order by evt_block_time), evt_block_time) as value,
           evt_block_time as end_date,
           lag(evt_block_time) over (order by evt_block_time) as begin_date,
           rate as open_rate
      from data
     where rn = 1
), overlaps AS (
  SELECT
      d.day_start,
      GREATEST(i.begin_date, d.day_start)       AS overlap_start,
      LEAST(i.end_date,   d.day_end)            AS overlap_end,
      i.value,
      i.open_rate
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
       SUM(open_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as rate
  FROM weighted
 GROUP BY 1
 order by 1 desc
