-- Dune Query 6681680: Pendle Active Markets
-- https://dune.com/queries/6681680

SELECT * FROM query_4133060
WHERE expiry > current_date
  AND is_active = true
