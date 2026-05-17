import Foundation

struct PitchSample: Sendable, Equatable {
    let timestamp: Date
    let pitchDegrees: Double
}

struct PhoneSession: Sendable, Equatable {
    let startedAt: Date
    let durationSeconds: Int
}

struct DailyAggregates: Sendable, Equatable {
    let screenSeconds: Int
    let sessions: [PhoneSession]
    let pitchSamples: [PitchSample]
    let dndExtendedMinutes: Int
}

struct DailyScore: Sendable, Equatable {
    let totalScore: Int
    let durationScore: Int
    let breakScore: Int
    let postureScore: Int
    let bonus: Int
}
