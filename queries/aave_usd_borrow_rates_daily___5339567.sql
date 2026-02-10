-- Dune Query 5339567: AAVE USD borrow rates (Daily)
-- https://dune.com/queries/5339567

with daily_rates as (
    SELECT "day" AS ts_day,
           borrow_rates.blockchain,
           borrowRate AS borrow_rate,
           asset_address as debt_token
      FROM query_4914922 borrow_rates join query_4941025 stables on asset_address = token_address and borrow_rates.blockchain = stables.blockchain
), aave_e_modes_plasma as (
    /* PT-sUSDe-APR 2025 */
    select 0xab509448ad489e2e1341e25cc500f2596464cc82 as collateral_token, 0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34 as debt_token, 0.882 as max_ltv /* USDe */
    union all
    select 0xab509448ad489e2e1341e25cc500f2596464cc82 as collateral_token, 0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb as debt_token, 0.865 as max_ltv /* USDT */
    union all
    /* PT-USDe-APR 2025 */
    select 0x54Dc267be2839303ff1e323584A16e86CeC4Aa44 as collateral_token, 0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34 as debt_token, 0.882 as max_ltv /* USDe */
    union all
    select 0x54Dc267be2839303ff1e323584A16e86CeC4Aa44 as collateral_token, 0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb as debt_token, 0.865 as max_ltv /* USDT */

), aave_e_modes_mainnet as (
    /* PT-sUSDE-31JUL2025 */
    select 0x3b3fB9C57858EF816833dC91565EFcd85D96f634 as collateral_token, 0xdAC17F958D2ee523a2206206994597C13D831ec7 as debt_token, 0.92 as max_ltv /* USDT */
    union all
    select 0x3b3fB9C57858EF816833dC91565EFcd85D96f634 as collateral_token, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 as debt_token, 0.92 as max_ltv /* USDC */
    union all
    select 0x3b3fB9C57858EF816833dC91565EFcd85D96f634 as collateral_token, 0xdC035D45d973E3EC169d2276DDab16f1e407384F as debt_token, 0.92 as max_ltv /* USDS */
    union all
    /* PT-eUSDE-14AUG2025 */
    select 0x14Bdc3A3AE09f5518b923b69489CBcAfB238e617 as collateral_token, 0xdAC17F958D2ee523a2206206994597C13D831ec7 as debt_token, 0.92 as max_ltv /* USDT */
    union all
    select 0x14Bdc3A3AE09f5518b923b69489CBcAfB238e617 as collateral_token, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 as debt_token, 0.92 as max_ltv /* USDC */
    union all
    select 0x14Bdc3A3AE09f5518b923b69489CBcAfB238e617 as collateral_token, 0xdC035D45d973E3EC169d2276DDab16f1e407384F as debt_token, 0.92 as max_ltv /* USDS */
    union all
    /* PT-sUSDE-25SEP2025 */
    select 0x9f56094c450763769ba0ea9fe2876070c0fd5f77 as collateral_token, 0xdAC17F958D2ee523a2206206994597C13D831ec7 as debt_token, 0.92 as max_ltv /* USDT */
    union all
    select 0x9f56094c450763769ba0ea9fe2876070c0fd5f77 as collateral_token, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 as debt_token, 0.92 as max_ltv /* USDC */
    union all
    select 0x9f56094c450763769ba0ea9fe2876070c0fd5f77 as collateral_token, 0xdC035D45d973E3EC169d2276DDab16f1e407384F as debt_token, 0.92 as max_ltv /* USDS */
    union all
    select 0x9f56094c450763769ba0ea9fe2876070c0fd5f77 as collateral_token, 0x4c9edd5852cd905f086c759e8383e09bff1e68b3 as debt_token, 0.92 as max_ltv /* USDe */
    union all
    /* PT-sUSDE-27NOV2025 */
    select 0xe6a934089bbee34f832060ce98848359883749b3 as collateral_token, 0xdAC17F958D2ee523a2206206994597C13D831ec7 as debt_token, 0.92 as max_ltv /* USDT */
    union all
    select 0xe6a934089bbee34f832060ce98848359883749b3 as collateral_token, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 as debt_token, 0.92 as max_ltv /* USDC */
    union all
    select 0xe6a934089bbee34f832060ce98848359883749b3 as collateral_token, 0xdC035D45d973E3EC169d2276DDab16f1e407384F as debt_token, 0.92 as max_ltv /* USDS */
    union all
    select 0xe6a934089bbee34f832060ce98848359883749b3 as collateral_token, 0x4c9edd5852cd905f086c759e8383e09bff1e68b3 as debt_token, 0.92 as max_ltv /* USDe */
    union all
    /* PT-USDE-27NOV2025 */
    select 0x62c6e813b9589c3631ba0cdb013acdb8544038b7 as collateral_token, 0xdAC17F958D2ee523a2206206994597C13D831ec7 as debt_token, 0.92 as max_ltv /* USDT */
    union all
    select 0x62c6e813b9589c3631ba0cdb013acdb8544038b7 as collateral_token, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 as debt_token, 0.92 as max_ltv /* USDC */
    union all
    select 0x62c6e813b9589c3631ba0cdb013acdb8544038b7 as collateral_token, 0xdC035D45d973E3EC169d2276DDab16f1e407384F as debt_token, 0.92 as max_ltv /* USDS */
    union all
    select 0x62c6e813b9589c3631ba0cdb013acdb8544038b7 as collateral_token, 0x4c9edd5852cd905f086c759e8383e09bff1e68b3 as debt_token, 0.92 as max_ltv /* USDe */
    union all
    /* PT-USDE-5DEB2026 */
    select 0x1f84a51296691320478c98b8d77f2bbd17d34350 as collateral_token, 0xdAC17F958D2ee523a2206206994597C13D831ec7 as debt_token, 0.92 as max_ltv /* USDT */
    union all
    select 0x1f84a51296691320478c98b8d77f2bbd17d34350 as collateral_token, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 as debt_token, 0.92 as max_ltv /* USDC */
    union all
    select 0x1f84a51296691320478c98b8d77f2bbd17d34350 as collateral_token, 0xC139190F447e929f090Edeb554D95AbB8b18aC1C as debt_token, 0.92 as max_ltv /* USDtb */
    union all
    select 0x1f84a51296691320478c98b8d77f2bbd17d34350 as collateral_token, 0x4c9edd5852cd905f086c759e8383e09bff1e68b3 as debt_token, 0.92 as max_ltv /* USDe */
    union all
    /* PT-sUSDE-5DEB2026 */
    select 0xe8483517077afa11a9b07f849cee2552f040d7b2 as collateral_token, 0xdAC17F958D2ee523a2206206994597C13D831ec7 as debt_token, 0.92 as max_ltv /* USDT */
    union all
    select 0xe8483517077afa11a9b07f849cee2552f040d7b2 as collateral_token, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 as debt_token, 0.92 as max_ltv /* USDC */
    union all
    select 0xe8483517077afa11a9b07f849cee2552f040d7b2 as collateral_token, 0xC139190F447e929f090Edeb554D95AbB8b18aC1C as debt_token, 0.92 as max_ltv /* USDtb */
    union all
    select 0xe8483517077afa11a9b07f849cee2552f040d7b2 as collateral_token, 0x4c9edd5852cd905f086c759e8383e09bff1e68b3 as debt_token, 0.92 as max_ltv /* USDe */
    union all
    /*sUSDe*/
    select 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497 as collateral_token, 0xdAC17F958D2ee523a2206206994597C13D831ec7 as debt_token, 0.9 as max_ltv /* USDT */
    union all
    select 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497 as collateral_token, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 as debt_token, 0.9 as max_ltv /* USDC */
    union all
    select 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497 as collateral_token, 0xdC035D45d973E3EC169d2276DDab16f1e407384F as debt_token, 0.9 as max_ltv /* USDS */
    union all
    select 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497 as collateral_token, 0x4c9edd5852cd905f086c759e8383e09bff1e68b3 as debt_token, 0.9 as max_ltv /* USDe */
    /*sUSDe*/
    union all
    select 0x356b8d89c1e1239cbbb9de4815c39a1474d5ba7d as collateral_token, 0xdAC17F958D2ee523a2206206994597C13D831ec7 as debt_token, 0.9 as max_ltv /* USDT */
    union all
    select 0x356b8d89c1e1239cbbb9de4815c39a1474d5ba7d as collateral_token, 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f as debt_token, 0.9 as max_ltv /* GHO */
), aave_e_modes as (
    select 'ethereum' as blockchain, * from aave_e_modes_mainnet
    union all
    select 'plasma' as blockchain, * from aave_e_modes_plasma
)
select ts_day,
       em.debt_token,
       borrow_rate,
       collateral_token,
       max_ltv,
       dr.blockchain
  from aave_e_modes em
  join daily_rates dr on em.debt_token = dr.debt_token and dr.blockchain = em.blockchain
