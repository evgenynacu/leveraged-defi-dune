-- Dune Query 4914922: AAVE v3 mainnet USD borrow rates
-- https://dune.com/queries/4914922

-- This is a query to get the DeFi dollar borrow rate, an aggregate value of the borrowing rate of USD stablecoins
-- on-chain.
-- The stablecoins considered are: (USDT, USDC, DAI, FDUSD, USDE, USDD, FRAX, PYUSD, USDP, CRVUSD, LUSD, GHO)
-- (0xdAC17F958D2ee523a2206206994597C13D831ec7, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409, 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3, 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6, 0x853d955aCEf822Db058eb8505911ED77F175b99e, 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8, 0x8E870D67F660D95d5be530380D0eC0bd388289E1, 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0, 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f)
-- tokens are ("usdt", "usdc", "dai", "fdusd", "usde", "usdd", "frax", "pyusd", "usdp", "crvusd", "lusd", "gho")

-- let's make it generalizable to all the chains and L2s

with dt as (
    SELECT dt
      FROM
    UNNEST(sequence(date '2025-01-01', current_date, INTERVAL '1' DAY)) t (dt)
),
AaveV3EthereumYieldTokens as (
    select
        rsv.evt_block_time as listingTime,
        rsv.asset as underlyingAsset,
        tkn.decimals,
        tkn.symbol,
        rsv.variableDebtToken,
        rsv.aToken,
        rsv.chain as blockchain
    from aave_v3_multichain.poolconfigurator_evt_reserveinitialized rsv
    left join tokens.erc20 tkn on tkn.contract_address = rsv.asset and rsv.chain = tkn.blockchain
    where lower(tkn.symbol) in ('usds', 'usdt', 'usdc', 'dai', 'fdusd', 'usde', 'usdd', 'frax', 'pyusd', 'usdp', 'crvusd', 'lusd', 'gho', 'usdbc', 'usdc.e', 'dai.e', 'm.usdc', 'm.usdt', 'm.dai', 'xdai', 'usdt0')
    --where rsv.asset in (0xdAC17F958D2ee523a2206206994597C13D831ec7, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409, 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3, 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6, 0x853d955aCEf822Db058eb8505911ED77F175b99e, 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8, 0x8E870D67F660D95d5be530380D0eC0bd388289E1, 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0, 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f)
),
token_days as (
    SELECT dt.dt, AaveV3EthereumYieldTokens.blockchain, AaveV3EthereumYieldTokens.symbol, AaveV3EthereumYieldTokens.underlyingAsset as asset_address
    FROM dt
    INNER JOIN AaveV3EthereumYieldTokens
    ON dt.dt >= date(AaveV3EthereumYieldTokens.listingTime)
),
AaveV3EthereumDebtEvents as (
    (
        select
            vdm.chain as blockchain, symbol, contract_address, evt_tx_hash, evt_index, evt_block_number, evt_block_time,
            index, index/pow(10,27) as index_normalized, value, value/pow(10,ayt.decimals) as value_normalized,
            value/pow(10, ayt.decimals)/index*pow(10, 27) as scaled_value_normalized
        from aave_v3_multichain.VariableDebtToken_evt_Mint vdm
        join AaveV3EthereumYieldTokens ayt on vdm.contract_address = ayt.variableDebtToken and ayt.blockchain = vdm.chain
    )
    union ALL
    (
        select
            vdm.chain as blockchain, symbol, contract_address, evt_tx_hash, evt_index, evt_block_number, evt_block_time,
            index, index/pow(10,27) as index_normalized, -value as value, -value/pow(10, ayt.decimals) as value_normalized,
            -value/pow(10, ayt.decimals)/index*pow(10, 27) as scaled_value_normalized
        from aave_v3_multichain.VariableDebtToken_evt_Burn vdm
        join AaveV3EthereumYieldTokens ayt on vdm.contract_address = ayt.variableDebtToken and ayt.blockchain = vdm.chain
    )
),

AaveV3EthereumScaledDebtChangeDaily as (
    select
        token_days.dt as day,
        token_days.symbol,
        contract_address,
        token_days.blockchain,
        token_days.asset_address,
        sum(COALESCE(scaled_value_normalized,0)) as daily_change_totalScaledDebt
    from token_days
    LEFT JOIN AaveV3EthereumDebtEvents
    ON token_days.symbol = AaveV3EthereumDebtEvents.symbol
    AND token_days.blockchain = AaveV3EthereumDebtEvents.blockchain
    AND token_days.dt = date_trunc('day', AaveV3EthereumDebtEvents.evt_block_time)
    group by 1,2,3,4,5
),

AaveV3EthereumBorrowIndices_ as (
    select
        token_days.symbol,
        token_days.blockchain,
        token_days.dt as day,
        max(AaveV3EthereumDebtEvents.index) as index,
        max(AaveV3EthereumDebtEvents.index_normalized) as index_normalized
    from token_days
    LEFT JOIN AaveV3EthereumDebtEvents
    ON token_days.dt = date_trunc('day', AaveV3EthereumDebtEvents.evt_block_time)
    AND token_days.blockchain = AaveV3EthereumDebtEvents.blockchain
    AND token_days.symbol = AaveV3EthereumDebtEvents.symbol
    group by 1, 2, 3
),
AaveV3EthereumBorrowIndices as (
    select
        blockchain,
        symbol,
        day,
        index as index_raw,
        index_normalized as index_normalized_raw,
        LAST_VALUE(index_normalized) IGNORE NULLS OVER (
                 PARTITION BY blockchain, symbol ORDER BY day
                 RANGE BETWEEN INTERVAL '7' DAY PRECEDING AND CURRENT ROW
             ) as index_normalized
    from AaveV3EthereumBorrowIndices_
) , Pool_evt_ReserveDataUpdated as (
    select chain, evt_block_time, reserve, variableBorrowRate from aave_v3_multichain.Pool_evt_ReserveDataUpdated
    union all
    select 'plasma', evt_block_time, reserve, variableBorrowRate from aave_v3_plasma.poolinstance_evt_reservedataupdated
) , DailyBorrowRates_ as (
    select
        date_trunc('day', evt_block_time) as day,
        rsd.chain as blockchain,
        ayt.symbol,
        avg(variableBorrowRate)/1e27 as borrowRate
    from Pool_evt_ReserveDataUpdated rsd
    join AaveV3EthereumYieldTokens ayt on ayt.underlyingAsset = rsd.reserve and rsd.chain = ayt.blockchain
    group by 1, 2, 3
--    order by day
) , DailyBorrowRates as (
    SELECT token_days.dt as day, token_days.blockchain, token_days.symbol, DailyBorrowRates_.borrowRate as borrowRate_raw,
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
),
DailyPrices as (
    select
        date_trunc('day', minute) as day,
        p.blockchain,
        p.contract_address,
        p.symbol,
        avg(price) as price
    from prices.usd p
    join AaveV3EthereumYieldTokens ayt on ayt.underlyingAsset = p.contract_address and ayt.blockchain = p.blockchain
    group by 1, 2, 3, 4
),
AaveV3EthereumTotalDebtScaled as (
    select debt.day,
            debt.blockchain,
            debt.symbol,
            debt.contract_address,
            debt.asset_address,
            debt.daily_change_totalScaledDebt,
            I.index_normalized,
            I.index_normalized_raw,
            sum(debt.daily_change_totalScaledDebt) over (partition by debt.symbol, debt.blockchain order by debt.day) as totalScaledDebt
            --,I.index_normalized * sum(debt.daily_change_totalScaledDebt) over
             --   (partition by debt.symbol order by debt.day) as totalDebt
    from AaveV3EthereumScaledDebtChangeDaily debt
    left join AaveV3EthereumBorrowIndices I
    on debt.symbol = I.symbol and debt.day = I.day and debt.blockchain = I.blockchain
),
AaveV3EthereumTotalDebtUSD as (
    select
        debt.*,
        index_normalized * totalScaledDebt as totalDebt,
        p.price,
        p.price * index_normalized * totalScaledDebt as totalDebtUSD
    from AaveV3EthereumTotalDebtScaled debt
    left join DailyPrices p
    on p.contract_address = debt.asset_address and p.day = debt.day and debt.blockchain = p.blockchain
),
AaveV3EthereumTotalDebtUSDWithRates as (
    select
        debt.*,
        rates.borrowRate,
        rates.borrowRate_raw
    from AaveV3EthereumTotalDebtUSD debt
    left join DailyBorrowRates rates
    on lower(rates.symbol) = lower(debt.symbol) and rates.day = debt.day and rates.blockchain = debt.blockchain
),
AaveV3EthereumDollarBorrowRate_ as (
    select
        day, blockchain, symbol, contract_address, asset_address,
        daily_change_totalScaledDebt, borrowRate, borrowRate_raw,
        index_normalized, index_normalized_raw, price, totalScaledDebt,
        totalDebt, totalDebtUSD,
        sum(totalDebt*price) over (partition by day) as aggregateDebtUSD,
        sum(borrowRate * totalDebt * price) over (partition by day) as totalAnnualizedIncomeUSD
    from AaveV3EthereumTotalDebtUSDWithRates
--    order by day
),
AaveV3EthereumDollarBorrowRate as (
    select
        *,
        totalAnnualizedIncomeUSD/aggregateDebtUSD as dollarBorrowRate,
        totalDebt*price/aggregateDebtUSD as shareOfDebt,
        borrowRate - totalAnnualizedIncomeUSD/aggregateDebtUSD as borrowRateSpread
    from AaveV3EthereumDollarBorrowRate_
--    order by day
)

select * from AaveV3EthereumDollarBorrowRate


/*

AaveV3EthereumDollarBorrowRate_ as (
    select
        day, symbol, contract_address, asset_address,
        daily_change_totalScaledDebt, borrowRate, borrowRate_raw,
        index_normalized, index_normalized_raw, price, totalScaledDebt,
        totalDebt, totalDebtUSD,
        (sum(borrowRate * totalDebt * price) over (partition by day))/(sum(totalDebt * price) over (partition by day)) as dollarBorrowRate,
        sum(totalDebt*price) over (partition by day) as aggregateDebtUSD,
        totalDebt * price / (sum(totalDebt*price) over (partition by day)) as shareOfDebt,
        borrowRate - (sum(borrowRate * totalDebt * price) over (partition by day))/(sum(totalDebt * price) over (partition by day)) as borrowRateSpread
    from AaveV3EthereumTotalDebtUSDWithRates
    order by day
)
,result as (
    select debt.day,
            debt.symbol,
            debt.contract_address,
            debt.asset_address,
            debt.daily_change_totalScaledDebt,
            rates.borrowRate,
            rates.borrowRate_raw,
            I.index_normalized,
            I.index_normalized_raw,
            p.price
            ,sum(debt.daily_change_totalScaledDebt) over
                (partition by debt.symbol order by debt.day) as totalScaledDebt
            ,I.index_normalized * sum(debt.daily_change_totalScaledDebt) over
                (partition by debt.symbol order by debt.day) as totalDebt
            ,p.price * I.index_normalized * sum(debt.daily_change_totalScaledDebt) over
                (partition by debt.symbol order by debt.day) as totalDebtUSD
    from AaveV3EthereumScaledDebtChangeDaily debt
    left join AaveV3EthereumBorrowIndices I
    on debt.day = I.day and debt.symbol = I.symbol
    left join DailyBorrowRates rates
    on rates.day = debt.day and rates.symbol = debt.symbol
    left join DailyPrices p 0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb
    ON p.day = debt.day and p.contract_address = debt.asset_address
)

select day, symbol, contract_address, asset_address,
    daily_change_totalScaledDebt, borrowRate, borrowRate_raw,
    index_normalized, index_normalized_raw, price, totalScaledDebt,
    totalDebt, totalDebtUSD,
    (sum(borrowRate * totalDebt * price) over (partition by day))/(sum(totalDebt * price) over (partition by day)) as dollarBorrowRate,
    sum(totalDebt*price) over (partition by day) as aggregateDebtUSD,
    totalDebt * price / (sum(totalDebt*price) over (partition by day)) as shareOfDebt,
    borrowRate - (sum(borrowRate * totalDebt * price) over (partition by day))/(sum(totalDebt * price) over (partition by day)) as borrowRateSpread
from result
order by day
*/
