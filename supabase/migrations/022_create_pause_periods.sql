-- P22-EMO-08: pause_periods table for intentional pause tracking

CREATE TABLE IF NOT EXISTS pause_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    cycle_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT valid_date_range CHECK (end_date >= start_date),
    CONSTRAINT max_14_days CHECK (end_date - start_date <= 14),
    UNIQUE(user_id, cycle_id)
);

-- Indexes
CREATE INDEX idx_pause_periods_user_id ON pause_periods(user_id);
CREATE INDEX idx_pause_periods_dates ON pause_periods(user_id, start_date, end_date);

-- RLS
ALTER TABLE pause_periods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own pause periods"
    ON pause_periods FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own pause periods"
    ON pause_periods FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own pause periods"
    ON pause_periods FOR DELETE
    USING (auth.uid() = user_id);
