# RNF Codex Build Instructions

This document defines the exact order Codex should implement RNF.

Follow steps sequentially.

Do not modify architecture.

Architecture:

Models → Systems → UI

---

# Step 1 — Create Core Models

Create folder:

Models

Create files:

Stats.swift  
Habit.swift  
HabitCompletion.swift  
Profile.swift  
Quest.swift  

Stats.swift must contain:

strength  
discipline  
focus  
energy  
wisdom  
mind  
spirit  

All stats must be integers.

---

# Step 2 — Create GameState

Create:

GameState.swift

GameState must conform to:

ObservableObject

Import:

Combine

Properties:

@Published level  
@Published xp  
@Published xpToNext  
@Published streak  
@Published stats  

Example stats initialization:

strength = 2  
discipline = 2  
focus = 2  
energy = 2  
wisdom = 2  
mind = 2  
spirit = 2  

---

# Step 3 — Inject GameState

Modify:

RNFApp.swift

Add:

@StateObject var gameState = GameState()

Inject:

.environmentObject(gameState)

Root view must receive GameState.

---

# Step 4 — Create Systems

Create folder:

Systems

Create files:

XPSystem.swift  
StatSystem.swift  
StreakSystem.swift  
QuestGenerator.swift  

Each system must contain only logic.

No UI code allowed.

---

# Step 5 — Implement XPSystem

Function:

applyXP()

Input:

currentXP  
gainedXP  
levelXP  
currentLevel

Output:

newXP  
newLevel  

Logic:

If XP exceeds levelXP → level up.

---

# Step 6 — Implement StatSystem

Function:

applyReward()

Input:

stats  
habitName

Example mapping:

Workout → strength +1  
Read 10 Pages → focus +1  
Meditate → wisdom +1  
Cold Shower → discipline +1  

---

# Step 7 — Implement StreakSystem

Function:

updateStreak()

Input:

currentStreak  
dailyCompleted  
dailyGoal  

Logic:

If dailyCompleted >= dailyGoal → increase streak.

---

# Step 8 — Create UI Components

Create folder:

Components

Files:

HabitRow.swift  
XPBar.swift  
DailyMissionBar.swift  
DisciplineRadarChart.swift  

Each component must be reusable.

---

# Step 9 — Implement ContentView

ContentView must:

Display habits list.

When habit tapped:

Call completeHabit().

completeHabit() must:

Apply stat reward  
Apply XP  
Update daily mission  
Check level up  
Update streak

---

# Step 10 — Implement AscensionView

AscensionView must display:

Level  
XP progress bar  
Radar chart  
Streak  
Titles  

All data must come from GameState.

---

# Step 11 — Add Animations

Implement:

XP gain animation  
Habit completion animation  
Level aura animation  

---

# Step 12 — Persistence

Save GameState to:

UserDefaults

Load state when app starts.

---

# Step 13 — Future Systems (Do Not Implement Yet)

Skill Trees  
Perk System  
Boss Battles  
Evolution System  
AI Quest Generation
