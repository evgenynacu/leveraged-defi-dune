-- Dune Query 5901216: wstUSR yield rates (Daily)
-- https://dune.com/queries/5901216

with day_bounds AS (
  SELECT dt as day_start,
         dt + interval '1' day as day_end
      FROM
    UNNEST(sequence(date '2025-01-01', current_date, INTERVAL '1' DAY)) t (dt)
), wrap_data AS (
    SELECT
        evt_block_time,
        CAST(_stUSRAmount AS DOUBLE) AS stUSR_amount,
        CAST(_wstUSRAmount AS DOUBLE) AS wstUSR_amount,
        'wrap' AS action
    FROM resolv_ethereum.WstUSR_evt_Wrap
), unwrap_data AS (
    SELECT
        evt_block_time,
        CAST(_stUSRAmount AS DOUBLE) AS stUSR_amount,
        CAST(_wstUSRAmount AS DOUBLE) AS wstUSR_amount,
        'unwrap' AS action
    FROM resolv_ethereum.WstUSR_evt_Unwrap
), raw_data as (
    SELECT
        evt_block_time,
        CASE
            WHEN wstUSR_amount = 0 THEN NULL  -- Avoid division by zero
            ELSE stUSR_amount / wstUSR_amount
        END AS rate
    FROM (
        SELECT * FROM wrap_data
        UNION ALL
        SELECT * FROM unwrap_data
    ) combined
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
       SUM(open_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as rate
  FROM weighted
 GROUP BY 1
 order by 1 desc
