# RNF State Management

This document defines how application state flows through the RNF iOS application.

The goal is to keep the system predictable, scalable, and easy to debug.

RNF follows a **unidirectional data flow architecture**.

---

# Architecture Overview

State must flow in a single direction.

Flow:

View  
↓  
ViewModel  
↓  
Service Layer  
↓  
Supabase / Local Storage  
↓  
Updated State  
↓  
View Refresh

Views never mutate shared state directly.

---

# Core State Object

RNF uses a global shared state object.

File:

GameState.swift

GameState holds the player's current progress.

Example fields:

level  
xp  
xpToNext  
streak  
stats  
titles

GameState must conform to:

ObservableObject

Example:

class GameState: ObservableObject {

    @Published var level: Int
    @Published var xp: Int
    @Published var xpToNext: Int
    @Published var streak: Int
    @Published var stats: Stats
    @Published var titles: [String]

}

---

# EnvironmentObject

GameState is injected into the SwiftUI environment.

Root:

RNFApp.swift

Example:

@main
struct RNFApp: App {

    @StateObject var gameState = GameState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameState)
        }
    }

}

All views can read GameState through:

@EnvironmentObject var game: GameState

---

# State Ownership Rules

Rule 1

Views display state but do not modify core systems.

Rule 2

ViewModels control business logic.

Rule 3

Services interact with the backend.

---

# View Layer

Views are responsible for:

displaying UI  
handling user interaction  
triggering ViewModel actions

Views must never:

query Supabase  
calculate XP  
update database directly

Example:

ContentView.swift

Calls:

viewModel.completeHabit()

---

# ViewModel Layer

ViewModels contain UI logic.

Example:

HomeViewModel.swift

Responsibilities:

manage screen state  
call services  
update GameState

Example method:

completeHabit(habit)

Pseudo flow:

1 user taps habit  
2 ViewModel calls HabitService  
3 service updates database  
4 GameState updated  
5 UI refresh

---

# Service Layer

Services handle data operations.

Examples:

HabitService  
DailyLogService  
XPService  
UserService  
SubscriptionService

Services are responsible for:

database queries  
API calls  
data validation

Services must not reference SwiftUI views.

---

# State Update Example

Habit completion flow:

User taps habit

View
↓
HomeViewModel.completeHabit()

HomeViewModel
↓
HabitService.completeHabit()

HabitService
↓
Supabase insert habit_completions

DailyLogService updates daily_logs

XPService adds XP

GameState updated

UI refreshes automatically.

---

# Local UI State

Views may store temporary UI state.

Example:

@State private var animatedHabit: UUID?

Examples of valid local state:

animation flags  
modal visibility  
temporary selections

Local state must not represent core gameplay data.

---

# Persistence

Persistent state comes from:

Supabase database

Local state should not permanently store gameplay progress.

Offline support may temporarily store data locally.

---

# State Synchronization

When app launches:

1 user authenticated
2 user profile loaded
3 GameState initialized
4 daily log loaded
5 UI rendered

---

# Derived State

Some state should be computed rather than stored.

Examples:

XP progress percentage  
level title  
daily completion progress

These values should be derived from GameState.

---

# Example Derived Property

extension GameState {

    var xpProgress: Double {
        return Double(xp) / Double(xpToNext)
    }

}

---

# Error Handling

ViewModels must handle errors from services.

Example:

network failure  
database error

UI should display safe fallback states.

Example:

retry button  
error message

---

# Concurrency Rules

Network calls must run asynchronously.

Use Swift concurrency:

async / await

Example:

Task {
    await viewModel.completeHabit()
}

---

# Thread Safety

GameState updates must occur on the main thread.

Example:

await MainActor.run {
    gameState.xp += 10
}

---

# Future Enhancements

Future versions may introduce:

Redux-style store  
state snapshot debugging  
offline sync queues  
background refresh logic

---

# Design Philosophy

RNF state must remain:

predictable  
simple  
traceable

Every state change should be explainable.

Complex state leads to bugs.

Clean architecture allows RNF to grow safely.
