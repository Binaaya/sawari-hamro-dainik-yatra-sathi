-- Migration: Widen paymentmethod columns to store Khalti pidx references
-- Khalti pidx strings like "Khalti:nMqRnDqNyr7yEAdBzGzZhK" exceed VARCHAR(20)

ALTER TABLE transactions ALTER COLUMN paymentmethod TYPE VARCHAR(100);
ALTER TABLE topuphistory ALTER COLUMN paymentmethod TYPE VARCHAR(100);
