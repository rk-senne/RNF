-- P21-DATA-08: Pillar streaks table for server-side persistence

CREATE TABLE IF NOT EXISTS pillar_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pillar TEXT NOT NULL,
    current_streak INT NOT NULL DEFAULT 0,
    best_streak INT NOT NULL DEFAULT 0,
    last_completed_date DATE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, pillar)
);

-- Indexes
CREATE INDEX idx_pillar_streaks_user_id ON pillar_streaks(user_id);

-- RLS
ALTER TABLE pillar_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own pillar streaks"
    ON pillar_streaks FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
