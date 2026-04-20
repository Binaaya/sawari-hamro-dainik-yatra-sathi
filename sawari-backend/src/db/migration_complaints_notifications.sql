-- Migration: Add userid column to complaints table for operator support
-- Also creates notifications and device_tokens tables

-- 1. Add userid to complaints (allows both passengers and operators to file complaints)
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS userid INTEGER REFERENCES users(userid);

-- 2. Backfill existing complaints with userid from the passengers table
UPDATE complaints c
SET userid = p.userid
FROM passengers p
WHERE c.passengerid = p.passengerid
AND c.userid IS NULL;

-- 3. Make userid NOT NULL after backfill
ALTER TABLE complaints ALTER COLUMN userid SET NOT NULL;

-- 4. Make passengerid nullable (operators won't have one)
ALTER TABLE complaints ALTER COLUMN passengerid DROP NOT NULL;

-- 5. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  notificationid SERIAL PRIMARY KEY,
  userid INTEGER NOT NULL REFERENCES users(userid),
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'general',
  isread BOOLEAN DEFAULT FALSE,
  createdat TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_userid ON notifications(userid);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(userid, isread);

-- 6. Create device_tokens table for FCM push notifications
CREATE TABLE IF NOT EXISTS device_tokens (
  tokenid SERIAL PRIMARY KEY,
  userid INTEGER NOT NULL REFERENCES users(userid),
  fcm_token TEXT NOT NULL UNIQUE,
  device_type VARCHAR(20) DEFAULT 'android',
  createdat TIMESTAMP DEFAULT NOW(),
  updatedat TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_userid ON device_tokens(userid);
