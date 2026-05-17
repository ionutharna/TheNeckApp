import Foundation
import CoreMotion
import Combine

@MainActor
final class TiltSampler: ObservableObject {
    @Published private(set) var currentFlexionDegrees: Double = 0
    @Published private(set) var isActive: Bool = false
    @Published private(set) var samples: [PitchSample] = []

    private let motionManager = CMMotionManager()
    private var simulatorTimer: Timer?

    func start() {
        guard !isActive else { return }
        #if targetEnvironment(simulator)
        startSimulatorMode()
        #else
        startRealMode()
        #endif
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        simulatorTimer?.invalidate()
        simulatorTimer = nil
        isActive = false
    }

    func flushSamples() -> [PitchSample] {
        let out = samples
        samples = []
        return out
    }

    private func startRealMode() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let pitchRad = motion.attitude.pitch
            let pitchDeg = pitchRad * 180 / .pi
            let flexion = Self.flexionFromPhonePitch(pitchDeg)
            self.currentFlexionDegrees = flexion
            self.samples.append(PitchSample(timestamp: Date(), pitchDegrees: flexion))
        }
        isActive = true
    }

    private func startSimulatorMode() {
        isActive = true
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let t = Date().timeIntervalSince1970
                let oscillation = sin(t / 4.0)
                let flexion = 25 + 20 * oscillation
                self.currentFlexionDegrees = flexion
                self.samples.append(PitchSample(timestamp: Date(), pitchDegrees: flexion))
            }
        }
    }

    static func flexionFromPhonePitch(_ phonePitchDegrees: Double) -> Double {
        let estimated = 90 - abs(phonePitchDegrees)
        return max(0, min(90, estimated))
    }
}
