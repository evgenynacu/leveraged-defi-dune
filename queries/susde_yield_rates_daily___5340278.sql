-- Dune Query 5340278: sUSDe yield rates (Daily)
-- https://dune.com/queries/5340278

with day_bounds AS (
  SELECT dt as day_start,
         dt + interval '1' day as day_end
      FROM
    UNNEST(sequence(current_date - interval '3' month, current_date, INTERVAL '1' DAY)) t (dt)
), raw_data as (
    select cast(assets as double) / cast(shares as double) as rate,
           evt_block_time
      from ethena_labs_ethereum.stakedusdev2_evt_deposit
    -- union all
    -- select cast(assets as double) / cast(shares as double) as rate,
    --        evt_block_time
    --   from ethena_labs_ethereum.stakedusdev2_evt_withdraw
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
       SUM(open_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as rate,
       365 * SUM(value * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as yearly_yield_rate
  FROM weighted
 GROUP BY 1
 order by 1 desc
