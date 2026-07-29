-- P30-RET-02: Add streak shield fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS equipped_shields INTEGER NOT NULL DEFAULT 0;

-- Constraint: max 2 shields equipped
ALTER TABLE users ADD CONSTRAINT check_max_shields CHECK (equipped_shields >= 0 AND equipped_shields <= 2);

-- Index not needed (queried by PK)
