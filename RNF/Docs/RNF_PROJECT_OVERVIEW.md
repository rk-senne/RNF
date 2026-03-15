RNF – Project Overview

Product Name

RNF (Rise and Forge)

Vision

RNF is a Real Life RPG system that helps users turn daily habits into lasting discipline.

Instead of tracking habits in a static list, RNF treats real-world growth like a role-playing game where the user develops a character through real actions.

Users gain:

• XP
• Levels
• Character stats
• Titles
• Streaks
• Character progression

The system is designed to make users feel like:

“I am leveling up my life.”

⸻

Product Mission

RNF helps users build discipline through a structured 90-day progression system.

The application combines:

• Habit tracking
• Micro-workouts
• Reading accountability
• Daily streaks
• Character development

The philosophy is calm discipline rather than motivational noise.

⸻

Core Gameplay Loop

RNF is built around a simple progression loop.

User completes a habit
→ Habit grants XP
→ XP increases level
→ Habits improve character stats
→ Stats influence future quests
→ Streaks unlock titles
→ New quests target weaker stats

Loop:

Habit → XP → Level → Stats → Titles → Streaks → Quests → Growth

⸻

90-Day Discipline System

Users commit to a 90-day challenge.

Each day includes:

• Daily habits
• Movement / workouts
• Reading
• Progress tracking

The app tracks:

• streaks
• XP
• levels
• calendar progress

Over time, new habits unlock and the challenge evolves.

⸻

Platforms

V1 Platform:

iOS

Framework:

SwiftUI

Architecture:

MVVM

⸻

Technology Stack

Frontend
SwiftUI

Backend
Supabase

Database
PostgreSQL

Authentication
Supabase Auth

Storage
Supabase Storage (reading proof images)

Subscriptions
Apple StoreKit 2

Analytics
PostHog or Amplitude (minimal tracking)

Notifications
UNUserNotificationCenter (local notifications)

⸻

Application Architecture

RNF follows a layered architecture.

User
↓
SwiftUI App
↓
ViewModel
↓
Service Layer
↓
Supabase API
↓
PostgreSQL Database

Views never directly call Supabase.

All database access must go through the Service Layer.

⸻

Project Folder Structure

RNFApp
│
├── App
│   └── RNFApp.swift
│
├── Views
│   ├── Splash
│   ├── Auth
│   ├── Home
│   ├── Workouts
│   ├── Read
│   ├── Profile
│   └── Subscription
│
├── ViewModels
│
├── Models
│
├── Systems
│
├── Services
│   ├── SupabaseService
│   ├── HabitService
│   ├── ChallengeService
│   └── SubscriptionService
│
├── Components
│
└── DesignSystem


⸻

Architecture Layers

1. Models (Data Structures)

Models represent the data used by the RPG system.

Files:

Habit.swift
Quest.swift
Stats.swift
Profile.swift
HabitCompletion.swift

Purpose:

Define the structure of the game and user data.

⸻

2. Systems (Game Logic)

Systems contain the rules of the RPG engine.

Files:

XPSystem.swift
StatSystem.swift
StreakSystem.swift
QuestGenerator.swift
QuestMapper.swift
QuestRewardSystem.swift
QuestDifficultySystem.swift
BadgeSystem.swift

Purpose:

Handle leveling, stat growth, streak calculation, quest generation, and rewards.

⸻

3. Services (Backend Communication)

Services communicate with Supabase.

Files:

SupabaseService.swift
HabitService.swift
ChallengeService.swift
SubscriptionService.swift

Purpose:

Handle database queries, authentication, and syncing.

⸻

4. ViewModels (State Management)

ViewModels connect UI to systems and services.

Views never contain business logic.

Purpose:

Manage state and coordinate systems.

⸻

5. UI Components

UI files render the application.

Files:

ContentView.swift
AscensionView.swift
EvolutionView.swift
ProfileView.swift

Components:

DailyMissionBar.swift
XPBar.swift
DisciplineRadarChart.swift

Purpose:

Display user progress and respond to state changes.

⸻

Global State

GameState.swift holds the shared RPG state.

GameState contains:

level
xp
xpToNext
streak
stats
titles

All screens observe this state using SwiftUI’s:

EnvironmentObject

⸻

Core Data Model

Profile

Represents the player’s state.

Profile

id
xp
level
streak_days

strength
discipline
focus
energy
wisdom
mind
spirit

⸻

Daily System (Calendar Backbone)

Every day generates a daily log.

Daily flow:

1 User opens app
2 Daily log loaded
3 User completes habits
4 XP calculated
5 Streak updated
6 Calendar updated

Everything depends on the daily_logs table.

⸻

Design Principles

RNF must feel:

Minimal
Structured
Calm
Premium

Avoid:

• visual noise
• bright gradients
• excessive gamification clutter

The experience should feel like a disciplined personal operating system.

⸻

Color System

Primary Accent

RNF Purple
#6E2BD9

Dark Mode Background

#121212

Light Mode Background

#F4F5F7

Success

#1F8A4D

Missed

#2A2A2A (dark)
#DADADA (light)

⸻

Typography

Primary Font

SF Pro

Hierarchy

H1
28–32pt

H2
18–20pt

Body
17pt

Caption
13pt

⸻

Accessibility

RNF must support:

• Dynamic Type
• VoiceOver
• WCAG AA contrast
• Reduce Motion
• 44pt tap targets

Accessibility is part of MVP.

⸻

Theme System

Default theme:

Follow iOS system appearance.

User options:

• Light
• Dark
• System

⸻

Phase 1 Goal

Validate retention of the 90-day habit system.

Target metric:

Day 7 retention ≥ 40%

⸻

Phase 1 Core Features

Authentication
Habit tracking
Workout timer
Reading proof upload
Calendar progress
Forgiveness system
Subscription

⸻

Long-Term Systems

Planned future systems include:

Skill Trees
Perk System
Boss Battles
Evolution System
AI Quest Generation
Guilds / Social Challenges

These features expand the RPG progression once the core loop proves retention.

