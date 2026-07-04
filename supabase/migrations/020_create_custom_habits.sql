-- P21-DATA-06: Custom habits table for server-side persistence

CREATE TABLE IF NOT EXISTS custom_habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    stat_category TEXT NOT NULL DEFAULT 'discipline',
    xp_reward INT NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- Indexes
CREATE INDEX idx_custom_habits_user_id ON custom_habits(user_id);

-- RLS
ALTER TABLE custom_habits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own custom habits"
    ON custom_habits FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
