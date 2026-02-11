-- Dune Query 5829803: [Non-PT] Yield daily rates
-- https://dune.com/queries/5829803

with susde_rates as (
    select 'ethereum' as blockchain,
           0x9D39A5DE30e57443BfF2A8307A4256c8797A3497 as token,
           ts_day,
           daily_yield_rate,
           'Ethena' as yield_protocol,
           'USD' as base_currency
      from query_5340278
), susde_arb_rates as (
    select 'arbitrum' as blockchain,
           0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2 as token,
           ts_day,
           daily_yield_rate,
           'Ethena' as yield_protocol,
           'USD' as base_currency
      from query_5340278
), dex_susde_rates as (
    select 'ethereum' as blockchain,
           0x9D39A5DE30e57443BfF2A8307A4256c8797A3497 as token,
           ts_day,
           daily_yield_rate,
           'Ethena' as yield_protocol,
           'USD' as base_currency
      from query_5829927
), srusd_rates as (
    select 'ethereum' as blockchain,
           0x738d1115B90efa71AE468F1287fc864775e23a31 as token,
           ts_day,
           daily_yield_rate,
           'Reservoir' as yield_protocol,
           'USD' as base_currency
      from query_5352937
), wstusr_rates as (
    select 'ethereum' as blockchain,
           0x1202F5C7b4B9E47a1A484E8B270be34dbbC75055 as token,
           ts_day,
           daily_yield_rate,
           'Resolv' as yield_protocol,
           'USD' as base_currency
      from query_5901216
), wstusr_arb_rates as (
    select 'arbitrum' as blockchain,
           0x66CFbD79257dC5217903A36293120282548E2254 as token,
           ts_day,
           daily_yield_rate,
           'Resolv' as yield_protocol,
           'USD' as base_currency
      from query_5901216
), mhyper_rates as (
    select 'ethereum' as blockchain,
           0x9b5528528656DBC094765E2abB79F293c21191B9 as token,
           ts_day,
           daily_yield_rate,
           'Midas' as yield_protocol,
           'USD' as base_currency
      from query_5901329
), mmev_rates as (
    select 'ethereum' as blockchain,
           0x030b69280892c888670EDCDCD8B69Fd8026A0BF3 as token,
           ts_day,
           daily_yield_rate,
           'Midas' as yield_protocol,
           'USD' as base_currency
      from query_5959288
), rlp_yield_rates as (
    select 'ethereum' as blockchain,
           0x4956b52aE2fF65D74CA2d61207523288e4528f96 as token,
           ts_day,
           daily_yield_rate,
           'RLP' as yield_protocol,
           'USD' as base_currency
      from query_5953061
), rlp_arb_yield_rates as (
    select 'arbitrum' as blockchain,
           0x35E5dB674D8e93a03d814FA0ADa70731efe8a4b9 as token,
           ts_day,
           daily_yield_rate,
           'RLP' as yield_protocol,
           'USD' as base_currency
      from query_5953061
), syrup_rates as (
    select 'ethereum' as blockchain,
           0x80ac24aA929eaF5013f6436cdA2a7ba190f5Cc0b as token,
           ts_day,
           daily_yield_rate,
           'Maple' as yield_protocol,
           'USD' as base_currency
      from query_5963774
), syrup_arb_rates as (
    select 'arbitrum' as blockchain,
           0x41CA7586cC1311807B4605fBB748a3B8862b42b5 as token,
           ts_day,
           daily_yield_rate,
           'Maple' as yield_protocol,
           'USD' as base_currency
      from query_5963774
), syrup_usdt_rates as (
    select 'ethereum' as blockchain,
           0x356b8d89c1e1239cbbb9de4815c39a1474d5ba7d as token,
           ts_day,
           daily_yield_rate,
           'Maple' as yield_protocol,
           'USD' as base_currency
      from query_6337968
), susds_rates as (
    select 'ethereum' as blockchain,
           0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD as token,
           ts_day,
           daily_yield_rate,
           'Sky' as yield_protocol,
           'USD' as base_currency
      from query_5995161
), susds_arb_rates as (
    select 'arbitrum' as blockchain,
           0xdDb46999F8891663a8F2828d25298f70416d7610 as token,
           ts_day,
           daily_yield_rate,
           'Sky' as yield_protocol,
           'USD' as base_currency
      from query_5995161
), sdai_rates as (
    select 'ethereum' as blockchain,
           0x83F20F44975D03b1b09e64809B757c47f942BEeA as token,
           ts_day,
           daily_yield_rate,
           'Maker' as yield_protocol,
           'USD' as base_currency
      from query_5995196
), stcusd_rates as (
    select 'ethereum',
           0x88887bE419578051FF9F4eb6C858A951921D8888 as token,
           ts_day,
           daily_yield_rate,
           'Cap Money' as yield_protocol,
           'USD' as base_currency
      from query_6231536
), wsrusd_rates as (
    select 'ethereum',
           0xd3fD63209FA2D55B07A0f6db36C2f43900be3094 as token,
           ts_day,
           daily_yield_rate,
           'Reservoir' as yield_protocol,
           'USD' as base_currency
      from query_6256035
), siusd_rates as (
    select 'ethereum' as blockchain,
           0xdbdc1ef57537e34680b898e1febd3d68c7389bcb as token,
           ts_day,
           daily_yield_rate,
           'InfiniFi' as yield_protocol,
           'USD' as base_currency
      from query_6685146
), susdd_rates as (
    select 'ethereum' as blockchain,
           0xC5d6A7B61d18AfA11435a889557b068BB9f29930 as token,
           ts_day,
           daily_yield_rate,
           'USDD' as yield_protocol,
           'USD' as base_currency
      from query_6685310
)
select * from susde_rates
union all
select * from susde_arb_rates
union all
select * from srusd_rates
union all
select * from wsrusd_rates
union all
select * from wstusr_rates
union all
select * from wstusr_arb_rates
union all
select * from mhyper_rates
union all
select * from mmev_rates
union all
select * from rlp_yield_rates
union all
select * from rlp_arb_yield_rates
union all
select * from syrup_rates
union all
select * from syrup_arb_rates
union all
select * from susds_rates
union all
select * from susds_arb_rates
union all
select * from sdai_rates
union all
select * from stcusd_rates
union all
select * from syrup_usdt_rates
union all
select * from siusd_rates
union all
select * from susdd_rates
