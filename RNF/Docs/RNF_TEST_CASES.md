# RNF Test Cases

This document defines the expected behavior of core systems.

---

# Habit Completion Tests

Test 1

Action:
User taps a habit.

Expected:

habit marked completed
XP added
daily mission counter increases
stats updated

---

Test 2

Action:
User taps completed habit.

Expected:

habit cannot be completed again.

---

# XP System Tests

Test 1

Action:
User gains XP below level threshold.

Expected:

XP increases
level unchanged

---

Test 2

Action:
User gains XP crossing threshold.

Expected:

level increases
remaining XP carries forward

---

# Daily Mission Tests

Test 1

Action:
User completes required habits.

Expected:

daily mission complete
streak increases

---

Test 2

Action:
User fails to complete habits.

Expected:

streak resets.

---

# Quest Generator Tests

Test 1

Stats:

strength = 5
focus = 2

Expected:

generated quest targets focus.

---

# Calendar Tests

Test 1

User completes all habits.

Expected:

calendar day marked complete.

---

Test 2

User completes some habits.

Expected:

calendar day marked partial.

---

# Reading Proof Tests

Action:

User uploads reading photo.

Expected:

image stored
reading marked complete
XP awarded.

---

# Workout Tests

Action:

User completes timer workout.

Expected:

XP awarded
daily log updated.
