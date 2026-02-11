-- Dune Query 6685310: sUSDD yield rates (Daily)
-- https://dune.com/queries/6685310

-- sUSDD (Savings USDD) at 0xC5d6A7B61d18AfA11435a889557b068BB9f29930
-- Uses pot/dsr mechanism: constant per-second rate, changes only on governance updates
-- Pot: 0xe789578252cc026ffb3413a1104ba223fdeca500
--
-- DSR history (governance rate changes):
--   Sep 29 2025 (block 23469748): dsr = 1.000000003593629 → 12% APY
--   Jan  9 2026 (block 24197871): dsr = 1.000000002440419 →  8% APY
--   Feb  9 2026 (block 24419856): dsr = 1.000000001847695 →  6% APY

select ts_day,
       power(dsr, 86400) - 1 as daily_yield_rate,
       365 * (power(dsr, 86400) - 1) as yearly_yield_rate
  from (
    select dt as ts_day,
           case when dt < date '2026-01-10'
                then 1.000000003593629043335673582  -- 12% APY
                when dt < date '2026-02-10'
                then 1.000000002440418608258400030  --  8% APY
                else 1.000000001847694957439350562  --  6% APY
           end as dsr
      from UNNEST(sequence(current_date - interval '3' month, current_date, INTERVAL '1' DAY)) t (dt)
  )
 order by 1 desc
