# RNF Codex Task Breakdown

This document defines the exact build order for RNF.

Codex should implement tasks sequentially.

Each task must be completed before moving to the next.

---

# Stage 1 — Project Setup

Task 1

Create SwiftUI project structure.

Folders:

App  
Views  
ViewModels  
Models  
Services  
Components  
DesignSystem

---

Task 2

Implement global GameState.

File:

GameState.swift

Properties:

level  
xp  
xpToNext  
streak  
stats  
titles

GameState must conform to ObservableObject.

---

Task 3

Inject GameState into SwiftUI environment.

File:

RNFApp.swift

Use:

.environmentObject(gameState)

---

# Stage 2 — Core Models

Create model files.

Habit.swift  
Quest.swift  
Stats.swift  
Profile.swift  
HabitCompletion.swift  
DailyLog.swift

Each model must conform to:

Codable  
Identifiable

---

# Stage 3 — Core Systems

Implement game logic systems.

XPSystem.swift  
StatSystem.swift  
StreakSystem.swift  
QuestGenerator.swift  
BadgeSystem.swift  
QuestDifficultySystem.swift

---

# Stage 4 — Core UI Components

Create reusable components.

DailyMissionBar.swift  
XPBar.swift  
DisciplineRadarChart.swift

---

# Stage 5 — Root Navigation

Create RootView.swift.

Tab structure:

Habits  
Ascension  
Workouts  
Read  
Profile

---

# Stage 6 — Habit System

Implement HabitRow.swift.

Features:

habit display  
completion button  
completion animation

---

Update ContentView.swift.

Features:

habit list  
habit completion  
XP reward  
stat updates  
streak tracking

---

# Stage 7 — Ascension Screen

Create AscensionView.swift.

Display:

level  
XP progress  
streak  
titles  
stat radar chart

---

# Stage 8 — Supabase Integration

Install Supabase Swift SDK.

Create:

SupabaseService.swift

Initialize Supabase client.

---

Create service files.

UserService.swift  
HabitService.swift  
DailyLogService.swift  
ReadingService.swift  
SubscriptionService.swift

---

# Stage 9 — Daily Log System

Implement daily_logs table integration.

On app launch:

Check if today's log exists.

If not:

Create new daily log.

---

# Stage 10 — Workout Timer

Create WorkoutTimerView.swift.

Features:

countdown timer  
pause  
finish  
XP reward

---

# Stage 11 — Reading Proof

Implement image upload.

Steps:

capture photo  
compress image  
upload to Supabase Storage  
store database record

---

# Stage 12 — Calendar System

Create calendar component.

Display:

complete days  
partial days  
missed days  
forgiven days

Calendar uses:

daily_logs table.

---

# Stage 13 — Forgiveness System

Implement forgiveness token logic.

Conditions:

missed day  
forgiveness available

Allow user to preserve streak.

---

# Stage 14 — Subscription System

Integrate StoreKit 2.

Features:

trial start  
subscription validation  
plan management

---

# Stage 15 — Testing

Implement test coverage.

Test:

habit completion  
XP system  
streak system  
quest generator  
calendar updates

---

# Final Goal

Codex should produce a functional RNF MVP with:

habit system  
XP progression  
calendar tracking  
workout timer  
reading proof upload  
subscription integration
