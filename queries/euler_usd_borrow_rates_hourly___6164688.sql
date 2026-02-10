-- Dune Query 6164688: Euler USD borrow rates (hourly)
-- https://dune.com/queries/6164688

with included as (
    select 0x7c280DBDEf569e96c7919251bD2B0edF0734C5A8 vault, 'USDT Yield' name
    union all
    select 0xe1Ce9AF672f8854845E5474400B6ddC7AE458a10, 'RLUSD Yield'
    union all
    select 0x2daCa71Cb58285212Dc05D65Cfd4f59A82BC4cF6, 'USDe Yield'
    union all
    select 0x61aAC438453d6e3513C0c8dbb69F13860E2B5028, 'eUSDe Yield'
    union all
    select 0xe0a80d35bB6618CBA260120b279d357978c42BCE, 'USDC Yield'
    union all
    select 0xba98fC35C9dfd69178AD5dcE9FA29c64554783b5, 'PYUSD Sentora'
), vaults as (
    select asset,
           contract_address as vault
      from euler_v2_ethereum.evault_evt_evaultcreated
), intervals as (
    select power(1 + interestRate / 1e27, 365.2425 * 86400) - 1 as borrow_rate,
           power(1 + interestRate / 1e27, 86400) - 1 as daily_borrow_rate,
           evt_block_time end_date,
           lag(evt_block_time) over (partition by contract_address order by evt_block_time) begin_date,
           contract_address as debt_vault,
           v.asset as debt_token,
           i.name as vault_name
      from euler_v2_ethereum.evault_evt_vaultstatus
      join vaults v on v.vault = contract_address
      join included i on v.vault = i.vault
     where v.asset in (select token_address from query_4941025)
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
      debt_vault,
      debt_token,
      vault_name
  FROM intervals i
  JOIN calendar d
    ON i.begin_date < d.day_end
   AND i.end_date   > d.day_start
), weighted AS (
  SELECT
      debt_vault,
      debt_token,
      vault_name,
      day_start,
      borrow_rate,
      daily_borrow_rate,
      to_unixtime(overlap_end) - to_unixtime(overlap_start) as seconds_inside
  FROM overlaps
), borrow_rates_by_vault as (
    SELECT debt_vault,
           debt_token,
           vault_name,
           day_start AS day,
           SUM(borrow_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as borrow_rate,
           SUM(daily_borrow_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as daily_borrow_rate
    FROM weighted
    GROUP BY 1, 2, 3, 4
), borrow_rates as (
    select borrow_rate,
           daily_borrow_rate,
           day,
           br.debt_vault as debt_vault,
           debt_token,
           vault_name
      from borrow_rates_by_vault br
)
select day,
       debt_token,
       debt_vault,
       vault_name,
       borrow_rate,
       daily_borrow_rate,
       'USD' base_currency,
       liquidity,
       supply,
       borrow,
       utilization
  from borrow_rates
  join query_5603829 vl on vl.vault_id = debt_vault
