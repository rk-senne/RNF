# RNF Timezone Policy

## Day Boundary Rule

All daily boundaries in RNF use the **device's local calendar** (`Calendar.current.startOfDay(for:)`).

A "day" starts at midnight in the user's local timezone and ends at 23:59:59.

## Normalization

Every date stored in `daily_logs.date`, `habit_completions.date`, and challenge day calculations MUST be normalized to start-of-day before persistence or comparison.

Normalization function: `Calendar.current.startOfDay(for: date)`

This is applied in:
- `DailyLogService.normalizedDay(_:)` — all daily log fetch/create/update paths
- `Date.startOfDay` extension — used by models and engines
- `ChallengeEngine.canAdvance(_:on:)` — challenge day elapsed calculation

## Storage Format

Dates are stored in Supabase as ISO 8601 UTC timestamps. The time component is always `T00:00:00Z` for date-only fields (daily_logs.date, habit_completions.date).

## Challenge Day Calculation

Challenge elapsed days are computed as:
```
startOfDay(challenge.start_date) → startOfDay(currentDate)
elapsed = calendar.dateComponents([.day], from:to:).day
currentDay = elapsed + 1
```

Day 1 is the start date. Day 90 is 89 calendar days after start.

## Implications

- Users who travel across timezones may see their "day" shift. This is acceptable — the device calendar is the authority.
- Duplicate completion guards use normalized dates, so a habit completed at 11pm and retried at 11:30pm on the same device day is correctly deduplicated.
- A habit completed at 11:59pm and retried at 12:01am produces two different normalized dates — this is intentional (new day).

## Testing

Date normalization tests live in `RNFTests/DateNormalizationTests.swift`.
