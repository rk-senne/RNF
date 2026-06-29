# RNF — The Forge Voice Spec

Version: 2.0  
Status: APPROVED  
Priority: P1

---

## Concept

The Forge speaks. Rarely. Briefly. Pre-recorded. Human.

Not TTS. Not AI-generated. A real voice, recorded in a studio, processed with subtle reverb to sound like it comes from within — not from a speaker.

One-way only. The user never talks back. The Forge announces. The user listens.

---

## Voice Direction (for casting / recording)

| Property | Direction |
|----------|-----------|
| Gender | Deep male or deep female (two options shipped in-app) |
| Tone | Flat. Not monotone — flat affect. Like someone stating facts they're certain of. |
| Energy | Low. Never raised. Like speaking to someone in the same room at 2 AM. |
| Speed | Deliberate. Slight pause between words. Each word is chosen, not rushed. |
| Emotion | None. No warmth. No excitement. Pure cold acknowledgment. |
| Reference | The System voice in Solo Leveling. GLaDOS minus the sarcasm. A Buddhist monk stating reality. |

**Processing chain:**
- Record dry (no room reverb)
- Add subtle plate reverb (0.8s tail, 30% wet) — sounds like the voice exists "inside"
- Slight low-end boost (100-200Hz shelf +2dB) — adds weight
- Gentle compression (3:1) — keeps level consistent across clips
- Export: .caf (Apple compressed audio), 44.1kHz mono

---

## Audio Clips Required

15 clips total. Average 1-2 seconds each. Total recording time: ~30 seconds of dialogue.

| ID | Text | Duration | Trigger |
|----|------|:--------:|---------|
| `activated` | "Activated." | ~1s | Voice first enabled in settings |
| `day_n` | "Day [N]." | ~1s | Morning intention opens (record "Day" separately, number spoken dynamically via concat OR record day 1-90 individually for key milestones) |
| `level_n` | "Level [N]." | ~1s | Level up |
| `spark` | "Spark." | ~0.5s | Streak tier reached |
| `ember` | "Ember." | ~0.5s | Streak tier reached |
| `flame` | "Flame." | ~0.5s | Streak tier reached |
| `blaze` | "Blaze." | ~0.5s | Streak tier reached |
| `inferno` | "Inferno." | ~0.5s | Streak tier reached |
| `eternal` | "Eternal." | ~0.8s | Streak tier reached |
| `defeated` | "Defeated." | ~0.8s | Boss killed |
| `appeared` | "[Boss] has appeared." | ~1.5s | Boss spawns (record 4: "Procrastination has appeared", etc.) |
| `noted` | "Noted." | ~0.6s | Discovery earned |
| `you_returned` | "You returned." | ~1s | First open after 3+ day absence |
| `the_forge_is_yours` | "The Forge is yours." | ~1.5s | 90-day completion |
| `thirty` | "Thirty." | ~0.6s | 30-day streak |
| `sixty` | "Sixty." | ~0.6s | 60-day streak |
| `ninety` | "Ninety." | ~0.6s | 90-day streak |

**Total files: ~22** (15 base + 4 boss variants + day milestones)

---

## Recording Strategy

**Option 1: Fiverr/VO marketplace ($50-150)**
- Search: "deep cinematic narrator male" or "audiobook female dark tone"
- Provide script + reference (link Solo Leveling system voice clips)
- Turnaround: 2-3 days
- Quality: professional, broadcast-ready

**Option 2: AI voice clone ($0 — ElevenLabs free tier)**
- Use a cinematic preset voice
- Generate all clips in minutes
- Quality: very good for short phrases, may lack the "human pause" between words
- Risk: may sound slightly synthetic on sustained vowels

**Option 3: Record yourself + process**
- Speak slowly in a quiet room
- Process heavily (pitch down 2-3 semitones, add reverb/compression)
- Cost: $0, time: 1 hour
- Quality: depends on your voice and processing skill

**Recommendation:** Option 1 or 2. Budget $100 for a Fiverr VO. The voice IS the brand. It's worth $100.

---

## Implementation

### File: `RNF/Core/ForgeVoice.swift`

```swift
import AVFoundation

enum ForgeVoice {
    private static var player: AVAudioPlayer?

    static var isEnabled: Bool {
        UserDefaults.standard.string(forKey: "rnf_forge_voice") != "off"
    }

    static func speak(_ clipName: String) {
        guard isEnabled else { return }
        guard !isDeviceSilent() else { return }
        guard withinDailyLimit() else { return }

        guard let url = Bundle.main.url(forResource: clipName, withExtension: "caf") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 0.75
        player?.play()
    }

    private static func withinDailyLimit() -> Bool {
        let key = "rnf_voice_\(todayKey())"
        let count = UserDefaults.standard.integer(forKey: key)
        guard count < 2 else { return false }
        UserDefaults.standard.set(count + 1, forKey: key)
        return true
    }

    private static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private static func isDeviceSilent() -> Bool {
        AVAudioSession.sharedInstance().outputVolume == 0
    }
}
```

### Trigger Points

| Location | Call |
|----------|------|
| Voice enabled in settings | `ForgeVoice.speak("activated")` — bypasses daily limit |
| Morning intention opens | `ForgeVoice.speak("day_\(streak + 1)")` or generic `"day"` clip |
| Level up | `ForgeVoice.speak("level_\(level)")` or generic `"level"` clip |
| Streak tier change | `ForgeVoice.speak(tierName.lowercased())` |
| Boss spawns | `ForgeVoice.speak("boss_\(bossType)")` |
| Boss defeated | `ForgeVoice.speak("defeated")` |
| 90-day complete | `ForgeVoice.speak("the_forge_is_yours")` |
| Discovery earned | `ForgeVoice.speak("noted")` |
| Streak 30/60/90 | `ForgeVoice.speak("thirty"/"sixty"/"ninety")` |
| Return after 3+ days | `ForgeVoice.speak("you_returned")` |

---

## Settings UI

In Profile → Settings:

```
The Forge Voice
├── Off (default)
├── Voice I  (deep male)
└── Voice II (deep female)
```

When toggled on: immediately plays "activated" clip as confirmation.

Two voice packs means two sets of ~22 clips. Ship both in the app bundle (~500KB total for compressed .caf at mono 44.1kHz).

---

## Rules

- Off by default. User must activate (mirrors lore).
- Max 2 utterances per calendar day. Scarcity is sacred.
- Never plays when device volume is 0.
- Never plays during active workout timer (would interrupt focus).
- Never conversational. User cannot respond or interact with the voice.
- Clips are ≤2 seconds. The voice says its piece and disappears.

---

## Acceptance Criteria

- AC-1: Voice MUST be pre-recorded audio, NOT text-to-speech
- AC-2: Voice MUST be off by default
- AC-3: Max 2 plays per calendar day (enforced via UserDefaults counter)
- AC-4: MUST NOT play when device volume is 0
- AC-5: MUST NOT play during active workout/focus timer
- AC-6: Enabling voice MUST immediately play "activated" clip
- AC-7: Two voice options MUST be available (male/female)
- AC-8: Total audio asset size MUST be <1MB
- AC-9: All clips MUST be ≤2 seconds duration
- AC-10: Audio MUST NOT interrupt other audio (music, podcasts) — use `.ambient` category
