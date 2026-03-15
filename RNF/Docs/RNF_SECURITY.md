# RNF Security Specification

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

Enable RLS  
Enable storage policies  
Enable API rate limiting  
Audit database permissions
