-- Dune Query 5603829: Euler Vaults Liquidity
-- https://dune.com/queries/5603829

with vaults as (
    select asset,
           contract_address as vault_id,
           chain as blockchain
      from euler_v2_multichain.evault_evt_evaultcreated
), raw_data as (
    select chain as blockchain,
           contract_address as vault_id,
           (totalBorrows + cash) as supply,
           totalBorrows as borrow,
           cash as liquidity,
           row_number() over (partition by chain, contract_address order by evt_block_time desc) as rn
      from euler_v2_multichain.evault_evt_vaultstatus
)
select v.vault_id,
       raw_data.blockchain,
       supply / pow(10, t.decimals) as supply,
       borrow / pow(10, t.decimals) as borrow,
       liquidity / pow(10, t.decimals) as liquidity,
       case when supply = 0 then 0 else liquidity / supply end as utilization
  from raw_data
  join vaults v on v.vault_id = raw_data.vault_id and v.blockchain = raw_data.blockchain
  join tokens.erc20 t on t.contract_address = v.asset and t.blockchain = raw_data.blockchain
 where rn = 1
