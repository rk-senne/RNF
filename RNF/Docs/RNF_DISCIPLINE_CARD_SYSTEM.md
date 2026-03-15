# RNF Discipline Card System

The Discipline Card is a shareable visual summary of a user's progress.

It transforms personal discipline progress into a social artifact.

This system serves two purposes:

• identity reinforcement
• viral growth

---

# Purpose

The Discipline Card allows users to:

• celebrate progress
• visualize their growth
• share discipline achievements

It acts as a digital badge of consistency.

---

# Card Structure

Each card includes:

RNF logo
User level
Evolution rank
Streak
XP progress
Character stats
Challenge progress

Example:

RNF — Rise and Forge

Level 8 — Awakened

Streak: 12 Days
XP: 340 / 500

Stats
Strength ████░░
Discipline █████░
Focus ███░░░
Energy ████░░
Wisdom ██░░░░
Mind ███░░░
Spirit ██░░░░

Day 12 / 90

---

# Design System

Card uses RNF visual identity.

Background:

#121212

Accent color:

RNF Purple
#6E2BD9

Text:

SF Pro

Layout:

Minimal
Centered
High contrast

No clutter.

---

# Card Generation Triggers

The card may be generated when:

Level Up
Streak Milestone
Evolution Unlock
90-Day Completion

Examples:

Level 10 reached
30 day streak
Ascendant evolution
90-day challenge completion

---

# Share Flow

1 User reaches milestone
2 RNF generates Discipline Card
3 User taps Share
4 iOS Share Sheet opens

Users can share to:

Instagram
Twitter
Messages
WhatsApp
Email

---

# Image Generation

The card is rendered using SwiftUI.

File:

DisciplineCardView.swift

The view displays progress data.

---

# Export Logic

The SwiftUI view is converted to an image.

Example:

ImageRenderer(content: DisciplineCardView)

The rendered image is exported.

---

# Sharing

Use:

UIActivityViewController

to present iOS sharing options.

---

# Data Sources

The card reads from:

GameState

Data used:

level
xp
xpToNext
streak
stats
titles
current_day

---

# Card Variants

Different milestones produce different cards.

Level Card

Shows level milestone.

Streak Card

Shows streak achievement.

Evolution Card

Shows evolution transformation.

Challenge Card

Shows 90-day completion.

---

# Branding

Every card includes:

RNF logo
Subtle brand signature

Example:

Rise and Forge

This increases brand recognition when shared.

---

# Privacy

Users control sharing.

Cards contain no sensitive data.

Email and account info never displayed.

---

# Growth Impact

The Discipline Card acts as a viral loop.

User shares card
Friends see progress
Friends install RNF

This creates organic growth.

---

# Behavioral Impact

Cards reinforce identity.

Users feel:

"I am disciplined."

Identity reinforcement increases retention.
