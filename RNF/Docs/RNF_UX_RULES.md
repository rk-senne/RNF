# RNF UI/UX Rules — Anti-Slop Guardrails

These rules govern every screen in RNF. Violating them creates "AI slop" — technically correct but emotionally dead interfaces.

---

## Rule 1: One Focal Point Per Screen

Every screen has ONE thing the user should focus on first.

| Screen | Focal Point | Everything Else |
|--------|------------|-----------------|
| Home | Today's quests | Stats/arc/challenge are below the fold |
| Workout | The timer | Encouragement is peripheral, not competing |
| Read | Upload proof button | Book info is context, not the action |
| Ascension | Level + tier | Stats/calendar are scrollable depth |
| Morning | The 3 focus choices | Quote is background texture |
| Evening | "Day complete" confirmation | Stats are supporting, not primary |

**Test:** Can a user understand what to DO within 1 second of seeing the screen? If not, remove elements until they can.

---

## Rule 2: Information Hierarchy, Not Information Dump

Never show 7 cards of equal visual weight. Establish clear hierarchy:

1. **Primary:** Large, bold, takes 60% of attention (streak count, timer, quest list)
2. **Secondary:** Normal weight, clear but not competing (XP bar, progress rings)
3. **Tertiary:** Small, subtle, discoverable on scroll (arc progress, guild pulse, pillar streaks)

**Anti-pattern:** PillarStreakRow + GuildPulseBar + DailyMissionBar + XPBar all at the same level in the same card. That's 4 secondary elements with no primary.

**Fix:** The streak count IS the primary. Everything else supports it.

---

## Rule 3: Whitespace Is Not Wasted Space

Premium apps breathe. RNF should have:
- 20pt padding inside cards
- 16-20pt spacing between cards
- Never more than 3 text elements stacked without a visual break
- Empty rows between sections (not just spacing — actual perceived rest)

**Anti-pattern:** VStack with 8 items and `spacing: 10`. Feels cramped and overwhelming.

---

## Rule 4: No Feature Should Announce Itself

Features should be discoverable, not announced. Bad:
- "SEASONAL ARC" header screaming at the user
- "ACTIVE PERKS" section that's empty 80% of the time
- "GUILD PULSE" label on a bar that says "0 members active"

Good:
- Arc progress appears naturally when relevant, disappears when complete
- Perks show their effect, not their existence
- Guild pulse only renders when count > 0

**Rule:** If a section would show "None" or "0" or "Empty", don't show it at all.

---

## Rule 5: Microcopy Is Human, Not System-Generated

Bad (AI slop): "Complete today's habits, workout, and reading proof to advance."
Good (human): "Show up. Stack wins."

Bad: "Begin the 90-day challenge to track your transformation arc."
Good: "Commit to 90 days."

Bad: "Your challenge progress is advancing with each completed day."
Good: "Day 34. Keep going."

**Rules for microcopy:**
- Max 8 words for action labels
- Max 15 words for descriptions
- Never explain what's obvious from context
- Never use "your" when the thing is clearly theirs (it's on THEIR screen)
- Prefer verbs over nouns

---

## Rule 6: Animations Serve Purpose, Not Decoration

Every animation must answer: "What does this communicate?"

- Streak pill bounce → "Your streak just grew" (feedback)
- Shimmer loading → "Data is coming" (status)
- Celebration overlay → "Something rare just happened" (reward)
- Card press scale → "Your tap registered" (acknowledgment)

**Anti-pattern:** Glow that loops forever on the Ascension screen. What does it communicate after second 3? Nothing. It becomes noise.

**Rule:** If an animation runs > 3 seconds, it must be ambient and nearly invisible (< 5% opacity change).

---

## Rule 7: Don't Stack Competing Paradigms

The home screen cannot be simultaneously:
- A dashboard (stats, charts, numbers)
- A task list (checkboxes, quests)
- A narrative (story text, quotes)
- A progress tracker (bars, rings, streaks)

Pick ONE primary paradigm per screen. Others are supporting.

Home = **Task list** (with narrative context above and stats below)
Ascension = **Dashboard** (with narrative absent)
Journey = **Progress tracker** (dedicated screen, not mixed into home)

---

## Rule 8: Cards Are Not Filing Cabinets

A card should contain ONE concept. Not:
- Streak + quests + mission bar + pillar streaks + guild pulse + XP bar (that's 6 concepts in one card)

Instead:
- Card 1: Your state (streak + daily ring). That's it.
- Below card: Quests (no card wrapper — they ARE the content)
- Below quests: Context cards (challenge, arc) — only if relevant

---

## Rule 9: Earn Complexity

- Day 1: Minimal (streak, quests, that's it)
- Day 7: Pillar streaks appear (earned by having multiple pillar data)
- Day 14: Custom habits unlock (earned by consistency)
- Day 30: Arc progress appears (only visible during active months)
- Day 60+: Living UI effects (earned by leveling)

Don't show a user on day 1 the same density as day 60. That's overwhelming and meaningless.

---

## Rule 10: Test With The "Drunk User" Rule

If a user opened this screen at 11pm, exhausted, slightly distracted — could they:
1. Understand their state in < 2 seconds?
2. Complete the primary action in < 3 taps?
3. Leave feeling accomplished, not confused?

If not, simplify.

---

## Applying These Rules

Before adding ANY new UI element, ask:
1. What screen does this go on?
2. What's the ONE focal point of that screen?
3. Does this element support or compete with that focal point?
4. If it competes: does it deserve its own screen instead?
5. Does this element show empty/zero states? If so, hide it entirely.
6. Is the copy < 8 words?
7. Would a tired user at 11pm understand this instantly?
