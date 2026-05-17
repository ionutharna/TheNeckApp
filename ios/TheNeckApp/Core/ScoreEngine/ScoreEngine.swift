import Foundation

enum ScoreEngine {
    static let lowUsageThresholdSec = 1800
    static let neutralLowUsageScore = 850
    static let dndBonusThresholdMin = 60
    static let dndBonusPoints = 50

    static func calculate(_ aggregates: DailyAggregates) -> DailyScore {
        if aggregates.screenSeconds < lowUsageThresholdSec {
            return DailyScore(
                totalScore: neutralLowUsageScore,
                durationScore: 450,
                breakScore: 300,
                postureScore: 100,
                bonus: 0
            )
        }
        let duration = durationScore(seconds: aggregates.screenSeconds)
        let breaks = breakScore(sessions: aggregates.sessions)
        let posture = postureScore(samples: aggregates.pitchSamples)
        let bonus = aggregates.dndExtendedMinutes >= dndBonusThresholdMin ? dndBonusPoints : 0
        let total = min(1000, duration + breaks + posture + bonus)
        return DailyScore(
            totalScore: total,
            durationScore: duration,
            breakScore: breaks,
            postureScore: posture,
            bonus: bonus
        )
    }

    static func durationScore(seconds: Int) -> Int {
        let hours = Double(seconds) / 3600.0
        switch hours {
        case ..<2.0:
            return 450
        case 2.0..<3.0:
            return Int((450 - (hours - 2) * 50).rounded())
        case 3.0..<4.0:
            return Int((400 - (hours - 3) * 150).rounded())
        case 4.0..<6.0:
            return Int((250 - (hours - 4) * 75).rounded())
        default:
            return max(0, Int((100 - (hours - 6) * 25).rounded()))
        }
    }

    static func breakScore(sessions: [PhoneSession]) -> Int {
        var penalty = 0
        for session in sessions {
            let minutes = Double(session.durationSeconds) / 60.0
            switch minutes {
            case ..<20: penalty += 0
            case 20..<30: penalty += 20
            case 30..<45: penalty += 50
            case 45..<60: penalty += 80
            default: penalty += 120
            }
        }
        return max(0, 300 - penalty)
    }

    static func postureScore(samples: [PitchSample]) -> Int {
        guard !samples.isEmpty else { return 250 }
        let avgPitch = samples.map(\.pitchDegrees).reduce(0, +) / Double(samples.count)
        switch avgPitch {
        case ..<15: return 250
        case 15..<30: return 200
        case 30..<45: return 130
        case 45..<60: return 70
        default: return 0
        }
    }
}
