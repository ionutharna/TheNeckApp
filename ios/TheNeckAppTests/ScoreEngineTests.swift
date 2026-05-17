import Testing
import Foundation
@testable import TheNeckApp

@Suite("ScoreEngine — duration component")
struct DurationScoreTests {
    @Test("Under 2h returns max 450")
    func underTwoHours() {
        #expect(ScoreEngine.durationScore(seconds: 0) == 450)
        #expect(ScoreEngine.durationScore(seconds: 3600) == 450)
        #expect(ScoreEngine.durationScore(seconds: 7199) == 450)
    }

    @Test("At 3h returns 400")
    func threeHours() {
        #expect(ScoreEngine.durationScore(seconds: 10800) == 400)
    }

    @Test("At 4h returns 250 (risk threshold)")
    func fourHours() {
        #expect(ScoreEngine.durationScore(seconds: 14400) == 250)
    }

    @Test("At 6h returns 100")
    func sixHours() {
        #expect(ScoreEngine.durationScore(seconds: 21600) == 100)
    }

    @Test("At 8h returns 50")
    func eightHours() {
        #expect(ScoreEngine.durationScore(seconds: 28800) == 50)
    }

    @Test("At 10h+ returns 0")
    func tenPlusHours() {
        #expect(ScoreEngine.durationScore(seconds: 36000) == 0)
        #expect(ScoreEngine.durationScore(seconds: 50000) == 0)
    }
}

@Suite("ScoreEngine — break component")
struct BreakScoreTests {
    @Test("No sessions returns full 300")
    func noSessions() {
        #expect(ScoreEngine.breakScore(sessions: []) == 300)
    }

    @Test("Sessions under 20 min: no penalty")
    func shortSessions() {
        let sessions = [
            PhoneSession(startedAt: Date(), durationSeconds: 600),
            PhoneSession(startedAt: Date(), durationSeconds: 1100)
        ]
        #expect(ScoreEngine.breakScore(sessions: sessions) == 300)
    }

    @Test("One 60min session: -120 penalty")
    func oneLongSession() {
        let sessions = [PhoneSession(startedAt: Date(), durationSeconds: 3600)]
        #expect(ScoreEngine.breakScore(sessions: sessions) == 180)
    }

    @Test("Multiple long sessions cap at 0")
    func manyLongSessions() {
        let sessions = (0..<5).map { _ in
            PhoneSession(startedAt: Date(), durationSeconds: 3600)
        }
        #expect(ScoreEngine.breakScore(sessions: sessions) == 0)
    }
}

@Suite("ScoreEngine — posture component")
struct PostureScoreTests {
    private func sample(_ pitch: Double) -> PitchSample {
        PitchSample(timestamp: Date(), pitchDegrees: pitch)
    }

    @Test("No samples returns max 250")
    func noSamples() {
        #expect(ScoreEngine.postureScore(samples: []) == 250)
    }

    @Test("Neutral (10°) returns 250")
    func neutral() {
        #expect(ScoreEngine.postureScore(samples: [sample(10)]) == 250)
    }

    @Test("Mild flexion (20°) returns 200")
    func mild() {
        #expect(ScoreEngine.postureScore(samples: [sample(20)]) == 200)
    }

    @Test("Moderate flexion (35°) returns 130")
    func moderate() {
        #expect(ScoreEngine.postureScore(samples: [sample(35)]) == 130)
    }

    @Test("Severe flexion (55°) returns 70")
    func severe() {
        #expect(ScoreEngine.postureScore(samples: [sample(55)]) == 70)
    }

    @Test("Extreme flexion (70°) returns 0")
    func extreme() {
        #expect(ScoreEngine.postureScore(samples: [sample(70)]) == 0)
    }
}

@Suite("ScoreEngine — full daily calculation")
struct DailyScoreTests {
    @Test("Under 30 min usage returns neutral 850")
    func lowUsage() {
        let agg = DailyAggregates(
            screenSeconds: 1000,
            sessions: [],
            pitchSamples: [],
            dndExtendedMinutes: 0
        )
        #expect(ScoreEngine.calculate(agg).totalScore == 850)
    }

    @Test("Perfect day reaches 1000")
    func perfectDay() {
        let agg = DailyAggregates(
            screenSeconds: 3600,
            sessions: [PhoneSession(startedAt: Date(), durationSeconds: 600)],
            pitchSamples: [PitchSample(timestamp: Date(), pitchDegrees: 10)],
            dndExtendedMinutes: 0
        )
        let score = ScoreEngine.calculate(agg)
        #expect(score.totalScore == 1000)
        #expect(score.durationScore == 450)
        #expect(score.breakScore == 300)
        #expect(score.postureScore == 250)
    }

    @Test("DND ≥60 min adds bonus 50")
    func dndBonus() {
        let agg = DailyAggregates(
            screenSeconds: 3600,
            sessions: [PhoneSession(startedAt: Date(), durationSeconds: 600)],
            pitchSamples: [PitchSample(timestamp: Date(), pitchDegrees: 10)],
            dndExtendedMinutes: 90
        )
        let score = ScoreEngine.calculate(agg)
        #expect(score.bonus == 50)
        #expect(score.totalScore == 1000)
    }

    @Test("Heavy use day: 5h, two long sessions, 40° angle")
    func heavyDay() {
        let agg = DailyAggregates(
            screenSeconds: 18000,
            sessions: [
                PhoneSession(startedAt: Date(), durationSeconds: 2700),
                PhoneSession(startedAt: Date(), durationSeconds: 3000)
            ],
            pitchSamples: [PitchSample(timestamp: Date(), pitchDegrees: 40)],
            dndExtendedMinutes: 0
        )
        let score = ScoreEngine.calculate(agg)
        #expect(score.durationScore == 175)
        #expect(score.breakScore == 140)
        #expect(score.postureScore == 130)
        #expect(score.totalScore == 445)
    }
}
