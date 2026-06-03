# RNF Security Specification

Production-readiness reference:

See `RNF_PRODUCTION_READINESS_SPEC.md` for required auth, RLS, secret handling, and user-isolation rules. If the two documents conflict, the stricter security rule applies.

---

Security ensures users cannot access or modify other users' data.

---

# Row Level Security (Supabase)

All tables must enforce RLS.

Policy rule:

auth.uid() = user_id

---

# Protected Tables

users  
daily_logs  
habit_completions  
reading_uploads  
subscriptions  

---

# Storage Security

Reading proof images stored in:

bucket: reading-proof

Path format:

reading-proof/{user_id}/{date}.jpg

Access rule:

users can only access their own folder.

---

# Local Validation Notes

Validated against service-layer code.

Row ownership:

Daily log reads include `user_id` filters.

Habit completion lookup includes `user_id`, `habit_id`, and `date` filters.

Calendar month reads include `user_id` filters.

Active challenge reads include `user_id` and `status` filters.

Subscription sync updates include a `user_id` filter.

Reading uploads write `reading_uploads.user_id` from the active caller-supplied user id.

Storage path:

`ReadingService` stores proof images under:

reading-proof/{user_id}/{yyyy-MM-dd}.jpg

This matches the documented storage path assumption.

RLS dependency:

Some write paths update by a row id returned from a prior user-scoped read. Supabase RLS must still enforce ownership on writes so clients cannot mutate rows they did not read legitimately.

Required table policy shape:

users.id = auth.uid()

All user-owned tables:

auth.uid() = user_id

Required storage policy shape:

The first folder segment must equal the authenticated user's id.

---

# Authentication Security

Passwords handled only by Supabase Auth.

No password storage inside RNF database.

Sessions stored securely in Keychain.

---

# API Rules

Service layer validates:

user session exists  
user_id matches auth.uid()

---

# Rate Limiting

Login attempts limited.

Recommended:

5 failed attempts → temporary lock.

---

# Data Validation

All writes must validate:

XP values positive  
habit IDs valid  
date format correct

---

# Production Security Checklist

Before launch:

Enable RLS for every protected table  
Enable storage policies for `reading-proof`  
Enable API rate limiting  
Audit database permissions
