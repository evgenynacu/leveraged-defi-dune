-- Dune Query 5603135: Euler USD borrow rates (daily)
-- https://dune.com/queries/5603135

with vaults as (
    select chain as blockchain,
           asset,
           contract_address as vault
      from euler_v2_multichain.evault_evt_evaultcreated
), collateral_tokens as (
    select blockchain,
           token_address
      from dune.enacu.result_collateral_whitelist
), vault_collaterals_raw as (
    select cast(liquidationLTV as double) / 10000 as max_ltv,
           ltvs.chain as blockchain,
           vd.vault debt_vault,
           vd.asset debt_token,
           vc.vault collateral_vault,
           vc.asset collateral_token,
           row_number() over (partition by ltvs.chain, ltvs.contract_address, ltvs.collateral order by evt_block_time desc) as rn
      from euler_v2_multichain.evault_evt_govsetltv ltvs
      join vaults vd on vd.vault = ltvs.contract_address and vd.blockchain = ltvs.chain
      join vaults vc on vc.vault = ltvs.collateral and vc.blockchain = ltvs.chain
      join query_4941025 stables on stables.token_address = vd.asset and stables.blockchain = vd.blockchain
      join collateral_tokens ct on vc.blockchain = ct.blockchain and vc.asset = ct.token_address
), vault_collaterals as (
    select max_ltv, blockchain, debt_vault, debt_token, collateral_vault, collateral_token
      from vault_collaterals_raw
     where rn = 1
       and max_ltv <> 0
), intervals as (
    select power(1 + interestRate / 1e27, 365.2425 * 86400) - 1 as borrow_rate,
           power(1 + interestRate / 1e27, 86400) - 1 as daily_borrow_rate,
           evt_block_time end_date,
           lag(evt_block_time) over (partition by chain, contract_address order by evt_block_time) begin_date,
           contract_address as debt_vault,
           chain as blockchain
      from euler_v2_multichain.evault_evt_vaultstatus
      join vaults v on v.vault = contract_address and v.blockchain = chain
      join query_4941025 stables on stables.token_address = v.asset and stables.blockchain = v.blockchain
     where evt_block_time > current_date - interval '4' month
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
      debt_vault,
      blockchain
  FROM intervals i
  JOIN calendar d
    ON i.begin_date < d.day_end
   AND i.end_date   > d.day_start
), weighted AS (
  SELECT
      blockchain,
      debt_vault,
      day_start,
      borrow_rate,
      daily_borrow_rate,
      to_unixtime(overlap_end) - to_unixtime(overlap_start) as seconds_inside
  FROM overlaps
), borrow_rates_by_vault as (
    SELECT blockchain,
           debt_vault,
           day_start AS day,
           SUM(borrow_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as borrow_rate,
           SUM(daily_borrow_rate * seconds_inside) / NULLIF(SUM(seconds_inside), 0) as daily_borrow_rate
    FROM weighted
    GROUP BY 1, 2, 3
), borrow_rates as (
    select br.blockchain,
           borrow_rate,
           daily_borrow_rate,
           day,
           br.debt_vault as debt_vault,
           collateral_vault,
           debt_token,
           collateral_token,
           max_ltv
      from borrow_rates_by_vault br
      join vault_collaterals vc on vc.debt_vault = br.debt_vault and vc.blockchain = br.blockchain
)
select day,
       vl.blockchain,
       debt_token,
       collateral_token,
       debt_vault,
       collateral_vault,
       borrow_rate,
       daily_borrow_rate,
       max_ltv,
       'USD' base_currency,
       liquidity,
       supply,
       borrow,
       utilization
  from borrow_rates
  join query_5603829 vl on vl.vault_id = debt_vault and borrow_rates.blockchain = vl.blockchain
