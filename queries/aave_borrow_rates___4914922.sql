-- Dune Query 4914922: AAVE v3 mainnet USD borrow rates
-- https://dune.com/queries/4914922

with dt as (
    SELECT dt
      FROM
    UNNEST(sequence(current_date - interval '3' month, current_date, INTERVAL '1' DAY)) t (dt)
),
AaveV3EthereumYieldTokens as (
    select
        rsv.evt_block_time as listingTime,
        rsv.asset as underlyingAsset,
        tkn.symbol,
        rsv.chain as blockchain
    from aave_v3_multichain.poolconfigurator_evt_reserveinitialized rsv
    left join tokens.erc20 tkn on tkn.contract_address = rsv.asset and rsv.chain = tkn.blockchain
    where lower(tkn.symbol) in ('usds', 'usdt', 'usdc', 'dai', 'fdusd', 'usde', 'usdd', 'frax', 'pyusd', 'usdp', 'crvusd', 'lusd', 'gho', 'usdbc', 'usdc.e', 'dai.e', 'm.usdc', 'm.usdt', 'm.dai', 'xdai', 'usdt0')
),
token_days as (
    SELECT dt.dt, AaveV3EthereumYieldTokens.blockchain, AaveV3EthereumYieldTokens.symbol, AaveV3EthereumYieldTokens.underlyingAsset as asset_address
    FROM dt
    INNER JOIN AaveV3EthereumYieldTokens
    ON dt.dt >= date(AaveV3EthereumYieldTokens.listingTime)
), Pool_evt_ReserveDataUpdated as (
    select chain, evt_block_time, reserve, variableBorrowRate from aave_v3_multichain.Pool_evt_ReserveDataUpdated
    union all
    select 'plasma', evt_block_time, reserve, variableBorrowRate from aave_v3_plasma.poolinstance_evt_reservedataupdated
), DailyBorrowRates_ as (
    select
        date_trunc('day', evt_block_time) as day,
        rsd.chain as blockchain,
        ayt.symbol,
        avg(variableBorrowRate)/1e27 as borrowRate
    from Pool_evt_ReserveDataUpdated rsd
    join AaveV3EthereumYieldTokens ayt on ayt.underlyingAsset = rsd.reserve and rsd.chain = ayt.blockchain
    group by 1, 2, 3
), DailyBorrowRates as (
    SELECT token_days.dt as day, token_days.blockchain, token_days.symbol, token_days.asset_address,
            COALESCE(DailyBorrowRates_.borrowRate,
             LAST_VALUE(DailyBorrowRates_.borrowRate) IGNORE NULLS OVER (
                 PARTITION BY token_days.blockchain, token_days.symbol ORDER BY token_days.dt
                 RANGE BETWEEN INTERVAL '7' DAY PRECEDING AND CURRENT ROW
             )) as borrowRate
    FROM token_days
    LEFT JOIN DailyBorrowRates_
    ON token_days.dt = DailyBorrowRates_.day
    AND token_days.symbol = DailyBorrowRates_.symbol
    AND token_days.blockchain = DailyBorrowRates_.blockchain
)

select day, blockchain, symbol, asset_address, borrowRate
  from DailyBorrowRates
