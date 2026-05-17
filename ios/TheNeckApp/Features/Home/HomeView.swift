import SwiftUI

struct HomeView: View {
    @State private var animatedScore: Int = 0
    private let targetScore = 847
    private let trendValues = [720, 680, 810, 750, 830, 790, 847]

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

                Sparkline(values: trendValues)
                    .frame(height: 44)
                    .padding(.horizontal, 40)

                VStack(spacing: 12) {
                    StatRow(icon: "clock.fill",
                            label: "2h 14m",
                            status: "sub prag",
                            ok: true)
                    StatRow(icon: "iphone.gen3",
                            label: "18°",
                            status: "unghi bun",
                            ok: true)
                    StatRow(icon: "pause.circle.fill",
                            label: "4 pauze",
                            status: "1 sesiune 47m",
                            ok: false)
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
            withAnimation(.easeOut(duration: 1.6)) {
                animatedScore = targetScore
            }
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
