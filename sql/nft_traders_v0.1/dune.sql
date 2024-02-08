with
  buyer_table as (
    Select
      buyer as ADDRESS,
      amount_usd as SALES_AMOUNT,
      block_time as BLOCK_TIMESTAMP,
      tx_id as TX_ID,
      'buy' as SIDE,
      account_mint as ACCOUNT_MINT

    FROM
      nft_solana.trades
    WHERE
      blockchain = 'solana'
      And trade_type = 'secondary'
      AND block_slot > 200083290
      AND amount_usd IS NOT NULL
    ORDER BY
      block_time DESC
  ),
  seller_table as (
    Select
      seller as ADDRESS,
      amount_usd as SALES_AMOUNT,
      block_time as BLOCK_TIMESTAMP,
      tx_id as TX_ID,
      'sell' as SIDE,
      account_mint as ACCOUNT_MINT
    FROM
      nft_solana.trades
    WHERE
      blockchain = 'solana'
      And trade_type = 'secondary'
      AND block_slot > 200083290
      AND amount_usd IS NOT NULL
    ORDER BY
      block_time DESC
  ),
  nft_trades_union as (
    SELECT
      *
    FROM
      buyer_table
    UNION ALL
    SELECT
      *
    FROM
      seller_table
  ),
  nft_trades_temp as (
    select
      *,
      LAG(BLOCK_TIMESTAMP, 1) OVER (
        PARTITION BY
          ADDRESS
        ORDER BY
          BLOCK_TIMESTAMP
      ) AS PREV_TRADE_BLOCK_TIMESTAMP
    from
      nft_trades_union
  ),
  nft_trades_with_lasttrade as (
    SELECT
      ADDRESS,
      SALES_AMOUNT,
      BLOCK_TIMESTAMP,
      SIDE,
      EXTRACT(
        MINUTE
        FROM
          (BLOCK_TIMESTAMP - PREV_TRADE_BLOCK_TIMESTAMP)
      ) AS MINUTES_SINCE_LAST_TRADE,
      ACCOUNT_MINT
    from
      nft_trades_temp
    WHERE
      PREV_TRADE_BLOCK_TIMESTAMP IS NOT NULL
    ORDER BY
      BLOCK_TIMESTAMP desc
  )
SELECT
  ADDRESS,
  SUM(SALES_AMOUNT) as TOTAL_USD_AMOUNT_TRADED,
  count(BLOCK_TIMESTAMP) as TOTAL_TRADE_COUNT,
  COUNT(DISTINCT ACCOUNT_MINT) as UNIQUE_NFT_TRADED,
  SUM(
    CASE
      WHEN SIDE = 'buy' then 1
      ELSE 0
    END
  ) as TOTAL_BUYS,
  SUM(
    CASE
      WHEN SIDE = 'sell' then 1
      ELSE 0
    END
  ) as TOTAL_SELLS,
  EXTRACT(
    DAY
    FROM
      (MAX(BLOCK_TIMESTAMP) - MIN(BLOCK_TIMESTAMP))
  ) AS NB_DAYS_SINCE_FIRST_TRADE,
  AVG(MINUTES_SINCE_LAST_TRADE) as AVG_NB_MINUTES_BETWEEN_TRADES
from
  nft_trades_with_lasttrade
GROUP BY
  1
ORDER BY
  TOTAL_USD_AMOUNT_TRADED DESC
LIMIT
  900000