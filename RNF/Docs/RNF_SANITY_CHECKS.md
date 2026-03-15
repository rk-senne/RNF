# RNF Sanity Checks

Sanity checks ensure data remains consistent.

---

# Habit Completion Rules

A habit can only be completed once per day.

If duplicate completion detected:

ignore request.

---

# XP Limits

Maximum daily XP should not exceed expected range.

Example:

Daily XP cap = 100 XP.

---

# Streak Validation

If a daily log is marked missed:

streak resets.

Unless forgiveness token used.

---

# Date Integrity

Daily logs must not allow:

future dates  
duplicate entries

---

# Reading Upload Validation

Image must exist before marking reading complete.

---

# Workout Completion Validation

Workout must run at least 80% of duration to count as completed.

---

# Quest Validation

Quest completion must correspond to an existing quest ID.

---

# Profile Data Integrity

XP cannot be negative.

Stats must remain within expected range.

Example:

0 ≤ stat ≤ 100
