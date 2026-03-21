# RNF Architecture Rules

Architecture:

UI → ViewModel → Engine → Services → Systems → Models

Rules:

- SwiftUI Views must never mutate GameState directly.
- ViewModels coordinate UI actions.
- Engines orchestrate multi-step gameplay flows.
- Services handle Supabase communication.
- Systems contain pure game logic.
- Models contain only data.

GameState is the single source of truth.
