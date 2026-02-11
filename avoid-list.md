# AVOID List — Tokens Excluded from Dashboard Tracking

Tokens on this list are excluded from the [Leveraged Yield](https://dune.com/enacu/leveraged-yield) dashboard due to exploits, depegs, wind-downs, or unacceptable counterparty risk. Referenced by the `/find-opportunities` skill.

## Active entries

### USD0++ (Usual Protocol)

- **Status**: Depegged, zero-coupon bond restructure
- **Date added**: 2025-12
- **What happened**: In Jan 2025, Usual Protocol changed the USD0++ floor price from $1 to $0.87, causing it to depeg to $0.89 on secondary markets. USD0++ is a 4-year locked bond — holders cannot exit at par without forfeiting accrued rewards.
- **Current state**: Trades at discount to NAV. Restructured as explicit zero-coupon bond with 4-year maturity.
- **Why avoid**: Multi-year lock, history of unilateral mechanism changes, secondary market trades below NAV.
- **Sources**: [The Block](https://www.theblock.co/post/333995/usual-money-protocol-update), [Blockworks](https://blockworks.co/news/usual-depeg-spurs-defi-instability), [Cointelegraph](https://cointelegraph.com/news/usd0-stablecoin-depeg-revenue-switch)

### deUSD / sdeUSD (Elixir)

- **Status**: Collapsed
- **Date added**: 2025-12
- **What happened**: In Nov 2025, Stream Finance disclosed $93M loss. deUSD had ~90% of supply held by Stream Finance as collateral for xUSD. When xUSD collapsed, deUSD lost backing and dropped 97%+ in 24 hours.
- **Current state**: Protocol winding down. Tokens near-worthless.
- **Why avoid**: Total loss of backing from concentrated counterparty risk in a single yield source.
- **Sources**: [Yahoo Finance](https://finance.yahoo.com/news/elixir-shuts-down-deusd-stablecoin-104937488.html), [BeInCrypto](https://beincrypto.com/elixir-deusd-stablecoin-collapse-stream-finance-loss/), [Cryptopolitan](https://www.cryptopolitan.com/elixirs-deusd-drops-98-whats-happening/)

### USDM (Mountain Protocol)

- **Status**: Wind-down complete
- **Date added**: 2025-12
- **What happened**: Mountain Protocol was acquired by Anchorage Digital in May 2025. USDM entered orderly wind-down — minting ceased May 12, yield dropped to zero after 30 days, redemption available throughout.
- **Current state**: No longer operational.
- **Why avoid**: Protocol no longer exists.
- **Sources**: [CoinDesk](https://www.coindesk.com/business/2025/05/12/anchorage-digital-to-acquire-usdm-issuer-mountain-protocol-in-stablecoin-expansion-move), [Mountain Protocol docs](https://docs.mountainprotocol.com/wind-down-documentation/usdm-wind-down-overview), [The Block](https://www.theblock.co/post/354004/anchorage-acquires-mountain-protocol-sunset-usdm-token)

### K (Kinto)

- **Status**: Exploited
- **Date added**: 2026-01
- **What happened**: A proxy initialization exploit on Arbitrum allowed an attacker to mint ~7M K tokens (vs ~2M circulating). Attacker inflated price over 7 days, then deposited minted tokens as collateral on Morpho Blue to borrow USDC. Price crashed 99%.
- **Current state**: Token near-worthless. Morpho markets with K collateral have bad debt (~$1.55M drained).
- **Why avoid**: Exploited token with inflated supply, worthless as collateral.
- **Sources**: [CryptoRank](https://cryptorank.io/news/feed/0724a-kinto-exchange-tanks-87-in-24-hours-hacked), [CoinJournal](https://coinjournal.net/news/kinto-coin-crashes-99-after-arbitrum-contract-exploit/), [Kinto post-mortem (Medium)](https://medium.com/mamori-finance/%EF%B8%8F-post-mortem-k-proxy-hack-our-path-forward-c2c3809882c6)

### xUSD (Stream Finance)

- **Status**: Collapsed
- **Date added**: 2026-01
- **What happened**: In Nov 2025, Stream Finance announced $93M loss blamed on "external fund manager." Court documents revealed funds were misappropriated by Ryan DeMattia to cover personal trading losses from ETH crash liquidations (Oct 2025). TVL collapsed $204M to sub-$100M, xUSD depegged to $0.07-$0.26. Total debt exposure ~$285M across Morpho, Euler, Silo, Gearbox.
- **Current state**: Protocol defunct. Token near-worthless.
- **Why avoid**: Fraud/misappropriation, total loss of funds, massive DeFi contagion.
- **Sources**: [CoinDesk](https://www.coindesk.com/markets/2025/11/04/stream-finance-faces-usd93-million-loss-launches-legal-investigation), [Yahoo Finance](https://finance.yahoo.com/news/stream-finance-loses-93-million-225557903.html), [DL News (lawsuit)](https://www.dlnews.com/articles/defi/stream-finance-founders-sue-partner-over-alleged-93m-loss/), [BlockEden contagion analysis](https://blockeden.xyz/blog/2025/11/08/m-defi-contagion/)

### sUSDD (USDD 2.0)

- **Status**: Under review — governance/transparency concerns
- **Date added**: 2026-01
- **What happened**: USDD is a Justin Sun-backed stablecoin originally launched on Tron in 2022 (as a competitor to Terra UST). Key concerns:
  1. **Silent collateral removal**: In Aug 2024, ~12,000 BTC ($732M) was removed from USDD reserves without DAO vote. USDD is now backed primarily by TRX instead of BTC.
  2. **Centralized custody**: Collateral managed by TRON DAO Reserve (controlled by Justin Sun). Funds held at HTX (exchange affiliated with Sun).
  3. **No meaningful governance**: Collateral changes happened unilaterally despite "DAO" branding.
- **Mitigating factors**: USDD 2.0 claims ~300% overcollateralization, has PSM, launched on Ethereum (Sep 2025), ~$1.4B TVL. Currently maintains peg.
- **Why avoid**: History of silent collateral changes without governance, centralized custody at affiliated exchange, single-actor control. Trust model incompatible with leveraged positions.
- **Sources**: [DL News](https://www.dlnews.com/articles/defi/justin-sun-responds-after-usdd-stablecoin-removes-bitcoin/), [The Block](https://www.theblock.co/post/312708/justin-suns-usdd-stablecoin-is-no-longer-backed-by-bitcoin), [Protos](https://protos.com/justin-suns-usdd-removes-12000-btc-without-dao-approval/), [Decrypt](https://decrypt.co/246054/justin-suns-usdd-stablecoin-loses-bitcoin-backing)

## Removed entries

_None yet._

## How to update this list

- **Adding**: When the `/find-opportunities` skill encounters a token that should be avoided, add it here with the template above (status, date, what happened, current state, why avoid, sources).
- **Removing**: If circumstances change (e.g., protocol recovers, new management), move the entry to "Removed entries" with a note explaining the change.
- **Reviewing**: Periodically review "Under review" entries to decide if they should remain or be removed.
