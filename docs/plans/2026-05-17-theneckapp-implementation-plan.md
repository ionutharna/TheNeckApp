# TheNeckApp — Plan Detaliat Implementare iOS MVP

*Data: 17 mai 2026 | Bazat pe: 2026-05-17-theneckapp-design.md*

## Prerequisite

- macOS (Xcode 15+, iOS 17 SDK)
- Apple Developer Program ($99/an, necesar pentru FamilyControls)
- iPhone fizic (testare CoreMotion realistic — simulatorul nu funcționează)
- Git + GitHub repo

## Săptămâna 1 — Fundație

### Task 1.1: Submit Apple FamilyControls entitlement (zi 1, BLOCANT)
- Mergi la developer.apple.com → Certificates → Capabilities
- Cere acces FamilyControls cu justificare:
  > "TheNeckApp ajută utilizatorii să-și monitorizeze sănătatea cervicală analizând timpul de utilizare a telefonului. Folosim DeviceActivity pentru a măsura durata sesiunilor și frecvența pauzelor. Datele rămân pe dispozitiv, fără reclame, fără partajare cu terți."
- Review Apple: 5-14 zile. Începe restul în paralel.

### Task 1.2: Setup Xcode project (zi 1-2)
- Xcode → New Project → App → SwiftUI → iOS 17.0 minimum
- Bundle ID: `tech.aiwizard.theneckapp` (sau preferință)
- Capabilities adăugate (chiar dacă FamilyControls nu e încă aprobat):
  - Family Controls
  - Background Modes → Background fetch + Background processing
- Info.plist:
  - `NSMotionUsageDescription`: "Pentru a măsura unghiul de flexie al gâtului în timpul utilizării."
  - `NSUserActivityTypes` pentru DeviceActivity
- Estructură foldere:
  ```
  TheNeckApp/
  ├── App/                  (TheNeckAppApp.swift, root view)
  ├── Core/
  │   ├── ScoreEngine/      (pure logic, no UI)
  │   ├── Sensors/          (CoreMotion, ScreenTime)
  │   └── Persistence/      (SwiftData models)
  ├── Features/
  │   ├── Onboarding/
  │   ├── Home/
  │   ├── Trend/
  │   └── Settings/
  ├── Resources/            (assets, colors, fonts)
  └── Tests/
      └── ScoreEngineTests/
  ```

### Task 1.3: ScoreEngine — pure module (zi 2-4)

```swift
struct DailyAggregates {
    let screenSeconds: Int
    let sessions: [Session]
    let pitchSamples: [PitchSample]
    let dndExtendedMinutes: Int
}

struct Session {
    let startedAt: Date
    let durationSeconds: Int
}

struct PitchSample {
    let timestamp: Date
    let pitchDegrees: Double
}

struct DailyScore {
    let totalScore: Int          // 0-1000
    let durationScore: Int       // 0-450
    let breakScore: Int          // 0-300
    let postureScore: Int        // 0-250
    let bonuses: Int             // e.g. DND
}

enum ScoreEngine {
    static func calculate(_ aggregates: DailyAggregates) -> DailyScore {
        let duration = durationScore(seconds: aggregates.screenSeconds)
        let breaks = breakScore(sessions: aggregates.sessions)
        let posture = postureScore(samples: aggregates.pitchSamples)
        let bonus = aggregates.dndExtendedMinutes >= 60 ? 50 : 0
        // Edge case: under 30 min → neutral 850
        if aggregates.screenSeconds < 1800 {
            return DailyScore(totalScore: 850, ...)
        }
        let total = min(1000, duration + breaks + posture + bonus)
        return DailyScore(...)
    }

    static func durationScore(seconds: Int) -> Int {
        let hours = Double(seconds) / 3600.0
        switch hours {
        case ..<2.0: return 450
        case 2.0..<3.0: return Int(450 - (hours - 2) * 50)
        case 3.0..<4.0: return Int(400 - (hours - 3) * 150)
        case 4.0..<6.0: return Int(250 - (hours - 4) * 75)
        case 6.0...:    return max(0, Int(100 - (hours - 6) * 25))
        default: return 0
        }
    }
    // ... breakScore, postureScore
}
```

### Task 1.4: Unit tests ScoreEngine (zi 4-5)
Cazuri:
- `test_zeroUsage_returnsNeutral850()`
- `test_2hUsage_returnsMax450ForDuration()`
- `test_4hUsage_returnsAround325ForDuration()`
- `test_6hUsage_returns100ForDuration()`
- `test_8hUsage_returns50ForDuration()`
- `test_noBreaks_60minSession_returns180`
- `test_perfectBreaks_returns300()`
- `test_neutralAngle_returns250()`
- `test_30degAngle_returns200()`
- `test_60degAngle_returns70()`
- `test_dndOver60min_addsBonus50()`

Target: 90%+ coverage pe ScoreEngine.

### Task 1.5: Mock Home UI (zi 5-7)
- SwiftUI view cu sample DailyScore (847)
- Animație număr 0→847 la apariție (`.contentTransition(.numericText())`)
- Sparkline 7 zile cu date hardcoded
- 3 indicatori (timp, unghi, pauze)
- Streak 🔥 hardcoded la 3
- Dark mode, gradient purple→cyan
- Funcționează pe simulator (UI doar)

## Săptămâna 2 — Senzori

### Task 2.1: CoreMotion sampler
- `CMMotionManager`, 1 Hz, pitch din attitude
- Pornit doar când app în foreground SAU background task
- Gating: `UIScreen.main.isCaptured` + brightness
- Agregare in-memory la 60 sec → median pitch
- Push în SwiftData

### Task 2.2: DeviceActivity / Screen Time integration
- Necesită entitlement aprobat (vezi Task 1.1)
- `DeviceActivityCenter().startMonitoring(...)` cu schedule zilnic
- Extension de monitor (separate target!) — primește callback-uri
- Detectare sesiuni: gap >2 min = pauză

### Task 2.3: Persistență SwiftData
- Models `DailyScore`, `TiltSample` (din design doc)
- Rotation policy: TiltSample >7 zile = delete
- Background save la app termination

## Săptămâna 3 — UI complet

### Task 3.1: Onboarding (4 ecrane)
### Task 3.2: Home connectat la date reale
### Task 3.3: Trend / Detalii screen
### Task 3.4: Settings screen

## Săptămâna 4 — Coach + gamificare

### Task 4.1: Local notifications
- `UNUserNotificationCenter`, scheduling smart
- Detectare sesiune continuă >20 min → notificare
- Max 4/zi (counter zilnic in SwiftData)

### Task 4.2: Streak logic
- Daily check la 06:00 (BGAppRefreshTask)
- Increment dacă scor azi ≥700
- Freeze day (1/lună, manual din Settings)

### Task 4.3: Micro-celebrări
- Haptic feedback (`UIImpactFeedbackGenerator`)
- Confetti la 800+ prima dată

## Săptămâna 5 — TestFlight

### Task 5.1: App Store Connect setup
### Task 5.2: TestFlight build + 20 testeri invite
### Task 5.3: Fix bugs / polish based on feedback
### Task 5.4: Privacy nutrition label

## Săptămâna 6 — App Store submission

### Task 6.1: Marketing assets
- Screenshots (6.7", 6.5", 5.5")
- App preview video (15-30 sec)
- Descriere ASO-friendly
### Task 6.2: Review submission
### Task 6.3: Launch plan

## Riscuri timeline

| Risc | Probabilitate | Impact | Mitigare |
|---|---|---|---|
| FamilyControls aprobare >2 săpt | Medium | High | Submit ziua 1, dezvolt logica fără |
| Apple review respinge | Medium | High | TestFlight extensive, follow guidelines |
| Battery drain >2% | Medium | Medium | Conservative sampling, telemetry |
| Bugs CoreMotion pe device | Low | Medium | Test pe min 3 modele iPhone diferite |

## Definition of Done — MVP

- [ ] ScoreEngine 90%+ test coverage
- [ ] 4 ecrane funcționale (Onboarding, Home, Trend, Settings)
- [ ] Screen Time + CoreMotion integrate
- [ ] Streak + notificări coach funcționale
- [ ] TestFlight cu min 20 testeri, 2 săpt feedback
- [ ] App Store submission aprobată
- [ ] Privacy label "Data Not Collected"
- [ ] Battery <2%/zi măsurat

---
*Vrei mai multe materiale ca acestea? Alătură-te comunității AI Wizard: [ai-wizard.tech/comunitate](https://ai-wizard.tech/comunitate)*
