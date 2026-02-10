-- Dune Query 4941025: USD stablecoins
-- https://dune.com/queries/4941025

with ethereum_tokens as (
    select token_address, 'ethereum' as blockchain
      from UNNEST (ARRAY[
       0xc139190f447e929f090edeb554d95abb8b18ac1c, /*USDtb*/
       0xdAC17F958D2ee523a2206206994597C13D831ec7, /*USDT*/
       0x66a1E37c9b0eAddca17d3662D6c05F4DECf3e110, /*USR*/
       0x6c3ea9036406852006290770BEdFcAbA0e23A0e8, /*PYUSD*/
       0x09D4214C03D01F49544C0448DBE3A27f768F2b34, /*rUSD*/
       0x6B175474E89094C44Da98b954EedeAC495271d0F, /*DAI*/
       0x73A15FeD60Bf67631dC6cd7Bc5B6e8da8190aCF5, /*USD0*/
       0x4c9EDD5852cd905f086C759E8383e09bff1E68B3, /*USDe*/
       0x853d955aCEf822Db058eb8505911ED77F175b99e, /*FRAX*/
       0xdC035D45d973E3EC169d2276DDab16f1e407384F, /*USDS*/
       0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, /*crvUSD*/
       0x437cc33344a0B27A429f795ff6B469C72698B291, /*wM*/
       0x90D2af7d622ca3141efA4d8f1F24d86E5974Cc8F, /*eUSDe*/
       0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, /*USDC*/
       0x8292bb45bf1ee4d140127049757c2e0ff06317ed, /*rlUSD*/
       0xab5eB14c09D416F0aC63661E57EDB7AEcDb9BEfA  /*msUSD*/
      ]) AS a(token_address)
), arbitrum_tokens as (
    select token_address, 'arbitrum' as blockchain
      from UNNEST (ARRAY[
       0xaf88d065e77c8cC2239327C5EDb3A432268e5831, /*USDC*/
       0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9  /*USDT0*/
      ]) AS a(token_address)
), plasma_tokens as (
    select token_address, 'plasma' as blockchain
      from UNNEST (ARRAY[
       0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34, /*USDe*/
       0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb  /*USDT0*/
      ]) AS a(token_address)
)
select * from ethereum_tokens
union all
select * from arbitrum_tokens
union all
select * from plasma_tokens
