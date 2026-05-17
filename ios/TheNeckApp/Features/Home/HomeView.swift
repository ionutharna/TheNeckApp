import SwiftUI

struct HomeView: View {
    @StateObject private var tilt = TiltSampler()
    @State private var animatedScore: Int = 0

    private let mockScreenSeconds = 8040
    private let mockSessions: [PhoneSession] = [
        PhoneSession(startedAt: Date(), durationSeconds: 1200),
        PhoneSession(startedAt: Date(), durationSeconds: 900),
        PhoneSession(startedAt: Date(), durationSeconds: 2820),
        PhoneSession(startedAt: Date(), durationSeconds: 600)
    ]

    private var liveScore: DailyScore {
        let agg = DailyAggregates(
            screenSeconds: mockScreenSeconds,
            sessions: mockSessions,
            pitchSamples: tilt.samples.suffix(60).map { $0 },
            dndExtendedMinutes: 0
        )
        return ScoreEngine.calculate(agg)
    }

    private var tiltStatusText: String {
        switch tilt.currentFlexionDegrees {
        case ..<15: return "unghi neutru"
        case 15..<30: return "unghi mediu"
        case 30..<45: return "flexie moderată"
        case 45..<60: return "flexie severă"
        default: return "extrem — ridică telefonul"
        }
    }

    private var tiltOk: Bool {
        tilt.currentFlexionDegrees < 30
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.18, blue: 0.78),
                    Color(red: 0.18, green: 0.58, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Bună dimineața, Ioan")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 20)

                VStack(spacing: 0) {
                    Text("\(animatedScore)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: Double(animatedScore)))
                    Text("/ 1000")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Sparkline(values: [720, 680, 810, 750, 830, 790, liveScore.totalScore])
                    .frame(height: 44)
                    .padding(.horizontal, 40)

                VStack(spacing: 12) {
                    StatRow(icon: "clock.fill",
                            label: "2h 14m",
                            status: "durată: \(liveScore.durationScore)/450",
                            ok: liveScore.durationScore > 300)
                    StatRow(icon: "iphone.gen3",
                            label: String(format: "%.0f°", tilt.currentFlexionDegrees),
                            status: tiltStatusText,
                            ok: tiltOk)
                    StatRow(icon: "pause.circle.fill",
                            label: "\(mockSessions.count) pauze",
                            status: "pauze: \(liveScore.breakScore)/300",
                            ok: liveScore.breakScore > 200)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 8) {
                    Text("🔥")
                    Text("streak: 3 zile")
                        .foregroundStyle(.white)
                        .font(.headline)
                }

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            tilt.start()
            withAnimation(.easeOut(duration: 1.6)) {
                animatedScore = liveScore.totalScore
            }
        }
        .onChange(of: tilt.currentFlexionDegrees) {
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedScore = liveScore.totalScore
            }
        }
        .onDisappear {
            tilt.stop()
        }
    }
}

private struct StatRow: View {
    let icon: String
    let label: String
    let status: String
    let ok: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .contentTransition(.numericText())
            Spacer()
            Text(ok ? "✓" : "⚠︎")
                .foregroundStyle(ok ? .green : .yellow)
            Text(status)
                .foregroundStyle(.white.opacity(0.75))
                .font(.caption)
        }
        .padding()
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct Sparkline: View {
    let values: [Int]

    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard let lo = values.min(),
                      let hi = values.max(),
                      hi > lo,
                      values.count > 1 else { return }
                let stepX = geo.size.width / CGFloat(values.count - 1)
                for (i, v) in values.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = geo.size.height * (1 - CGFloat(v - lo) / CGFloat(hi - lo))
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(.white,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }
}

#Preview {
    HomeView()
}
