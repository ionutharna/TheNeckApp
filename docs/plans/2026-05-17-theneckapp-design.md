# TheNeckApp — Design Document

*Data: 17 mai 2026 | Status: Design validat, gata pentru planning de implementare*

## Sumar

Aplicație mobilă iOS (apoi Android) care urmărește utilizarea sănătoasă a telefonului și calculează un scor 0-1000. Țintă: Gen Z și tineri 16-30, smartphone-intensivi. Abordare: coach + gamificare lean, all-on-device privacy, MVP în 4-6 săptămâni.

Fundament științific: research-impact-telefon-mobil-gat-2026-05-17.md (18 surse, meta-analize 2024-2025).

## Decizii cheie

| Decizie | Alegere | Rațiune |
|---|---|---|
| Audiență | Gen Z & tineri 16-30 | Utilizatori cei mai intensivi, sensibili la gamificare |
| Semnale scor | Holistic (long-term), MVP focused | Aliniat cu evidence biopsihosocial 2024-2025 |
| Rol app | Coach + gamificare | RCT-uri arată că intervenția scade durerea (44%→20%) |
| Stack | Native Swift (iOS), Kotlin (Android faza 3) | Acces deplin la senzori, performanță |
| Scope MVP | Minim, 4-6 săpt | Validare rapidă înainte de scop extins |
| Scor în timp | Hibrid: zilnic + trend 7 zile | Feedback imediat + progres pe termen lung |
| Date | On-device, fără backend | Privacy diferențiator, cost zero |

## Arhitectură MVP

### Componente

1. **Score Engine** (Swift, pure functions, testabil)
   - Input: agregate zilnice (timp ecran, samples unghi, sesiuni)
   - Output: `DailyScore` cu defalcare per componentă

2. **Tilt Sampler** (CoreMotion)
   - 1 Hz când ecran on + categorie activă
   - Agregare la 60 sec (median pitch)
   - Stop în background prelungit / low power
   - Target: <2% baterie/zi

3. **Screen Time integrator** (FamilyControls + DeviceActivity)
   - Authorization la onboarding
   - Citire timp/categorie + frecvență sesiuni
   - Detectare pauze (>2 min gap)

4. **Notification Coach** (UserNotifications)
   - Pauze la 20 min utilizare continuă
   - Nudge la unghi sever >2 min
   - Max 4/zi (anti-fatigue)
   - Tonalitate Gen Z, nu shame

5. **Persistență locală** (SwiftData)
   - DailyScore istoric (păstrăm tot)
   - TiltSample raw (rotație 7 zile)

6. **UI** (SwiftUI, iOS 17+)
   - 4 ecrane: Onboarding, Home, Trend, Settings
   - Dark mode default, animații pe scor, haptic feedback

## Formula scor 0-1000

| Componentă | Pondere | Bază științifică |
|---|---|---|
| Durată ecran | 450 pts | OR 2.34 pentru >3h/zi (Oxford 2024) |
| Pauze regulate | 300 pts | RCT PMID 39647258 |
| Unghi flexie | 250 pts | Hansraj 2014 (contestat — pondere mică intenționat) |

### Detaliu

**Durată (max 450)**, non-liniar:
```
0-2h   → 450
2-3h   → 450 → 400
3-4h   → 400 → 250 (pragul de risc)
4-6h   → 250 → 100
>6h    → 100 → 0
```

**Pauze (max 300)**, penalizare per sesiune lungă:
```
Sesiune ≤20 min  → 0
        20-30    → -20
        30-45    → -50
        45-60    → -80
        >60      → -120
Score = max(0, 300 - Σ penalizări)
```

**Unghi (max 250)**, media ponderată:
```
0-15°   → 250
15-30°  → 200
30-45°  → 130
45-60°  → 70
>60°    → 0
```

### Edge cases
- Sub 30 min utilizare/zi: scor neutru 850 (anti-inflație)
- Telefon staționar: tilt sampler oprit
- Mod avion / DND extins: bonus +50 (digital detox)
- Reset zilnic la 06:00 (nu miezul nopții — somn contează)

### Trend
- Scor azi prominent
- Sparkline 7 zile
- Streak: zile consecutive cu scor ≥700

## UX / Ecrane MVP

### Onboarding (4 pași)
1. Welcome cu scor mockup
2. Cum funcționează (3 carduri animate)
3. Permisiuni explicate (Screen Time, Motion, Notifications)
4. Setări inițiale (vârstă opțională, obiectiv 700/800/900)

### Home "Azi"
- Scor mare central (animat)
- Sparkline 7 zile sub scor
- 3 indicatori: timp, unghi mediu, pauze
- Streak 🔥 dacă activ
- CTA "Vezi detalii"

### Trend / Detalii
- Line chart 7/30 zile
- Defalcare scor azi (3 bare segmentate)
- Insights generate ("ai cel mai mic scor lunea")
- 3 articole educaționale scurte (extras din research)

### Settings
- Obiectiv zilnic
- Intervale notificări (15/20/30 min)
- Mod Strict
- Quiet hours
- Export / Delete (GDPR)

### Vizual / brand
- Dark mode default
- Gradiente purple → cyan
- SF Rounded font
- Haptic la milestone (700, 800, 900)
- Confetti subtile la 800 prima dată

## Gamificare (lean MVP)

În MVP:
- **Streak** zilnic (zi ≥700)
- **Daily nudge** la 21:30, tonalitate adaptată scorului
- **Micro-celebrări**: haptic + animații la 900, primul scor peste 800
- **Freeze day**: 1 joker/lună, evită streak loss = churn

Post-MVP:
- Achievements / badges
- Leaderboards prieteni (necesită backend)
- Challenge-uri săptămânale
- Share social (Instagram/TikTok)

## Privacy, date, tech

### On-device first
- Zero backend în MVP
- App Store privacy label: "Data Not Collected"
- Diferențiator: "your data never leaves your phone"

### Frameworks
| Framework | Pentru |
|---|---|
| FamilyControls + DeviceActivity | Screen Time API |
| CoreMotion | Unghi telefon (pitch) |
| UserNotifications | Coach |
| SwiftData | Persistență |

### Data model
```swift
@Model class DailyScore {
  var date: Date
  var totalScore: Int          // 0-1000
  var durationScore: Int       // 0-450
  var breakScore: Int          // 0-300
  var postureScore: Int        // 0-250
  var screenSeconds: Int
  var avgPitchDegrees: Double
  var sessionCount: Int
  var longestSessionSec: Int
}

@Model class TiltSample {
  var timestamp: Date
  var pitchDegrees: Double
  var screenActive: Bool
}
```

### Testing
- Unit tests pentru ScoreEngine (deterministă)
- Snapshot tests UI
- Device real obligatoriu (simulator nu are motion realistic)
- TestFlight 20 testeri, 2 săpt

## Timeline lansare

### iOS MVP (4-6 săpt)
| Săpt | Milestone |
|---|---|
| 1 | Setup proiect, ScoreEngine + tests, mock UI |
| 2 | CoreMotion sampler + Screen Time API |
| 3 | UI complet (4 ecrane) |
| 4 | Notificări coach, streak, persistență |
| 5 | TestFlight beta + polish |
| 6 | App Store submission |

### Faza 2 (post-MVP, validare-driven)
- HealthKit (somn + activitate) → scor cu adevărat holistic
- Bibliotecă exerciții (flexori cervicali profunzi)
- Widget Home Screen
- Achievements + share social

### Faza 3 (Android, ~5-6 săpt)
- Kotlin + Jetpack Compose
- UsageStatsManager + SensorManager
- Health Connect

## Out-of-scope explicit (YAGNI)

În MVP **nu** facem:
- Backend / conturi / sync cloud
- Leaderboards / social graph
- Achievements / badges (peste streak)
- Share social
- Abonamente / monetizare
- Integrare HealthKit
- Bibliotecă exerciții
- Widget-uri Home Screen
- Android

Toate apar abia după validare cu date reale de retenție din TestFlight + App Store launch.

## Riscuri și mitigări

| Risc | Mitigare |
|---|---|
| Apple respinge pentru Screen Time API misuse | Clear value prop, no advertising, no data sharing |
| Battery drain reclamat | Sampling agresiv-conservator (1 Hz, gating ecran), telemetry intern |
| Streak loss → churn | Freeze day gratuit, nu pedepsim aspru |
| Critica științifică Hansraj | Comunicare onestă în onboarding ("postura e un factor, nu tot") |
| App Store competiție (Apple Screen Time) | Diferențiator: scor unic + coaching, nu doar dashboards |

## Următorii pași

1. Validare design cu utilizator ✅
2. Setup git worktree pentru implementare
3. Plan detaliat de implementare (writing-plans skill)
4. Setup proiect Xcode, configurare entitlements (FamilyControls necesită aprobare Apple)
5. Build ScoreEngine + tests primii
6. Iterare săptămânală

---
*Vrei mai multe materiale ca acestea? Alătură-te comunității AI Wizard: [ai-wizard.tech/comunitate](https://ai-wizard.tech/comunitate)*
