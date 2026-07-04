-- P21-DATA-04: Discoveries table for server-side persistence

CREATE TABLE IF NOT EXISTS discoveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    discovery_id TEXT NOT NULL,
    earned_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, discovery_id)
);

-- Indexes
CREATE INDEX idx_discoveries_user_id ON discoveries(user_id);

-- RLS
ALTER TABLE discoveries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own discoveries"
    ON discoveries FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own discoveries"
    ON discoveries FOR INSERT
    WITH CHECK (auth.uid() = user_id);
