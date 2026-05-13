import SwiftUI
import UIKit

// MARK: - Splash Screen
struct SplashScreenView: View {

    /// Вызывается после анимации выезда вправо (перед показом основного UI).
    var onFinished: () -> Void = {}

    @State private var slideOffset: CGFloat = 0
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack {
                Color(hex: "#2D5ED7")
                    .ignoresSafeArea()

                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("KET")
                        Text("TIK")
                    }
                    .font(splashTitleFont(size: min(56, width * 0.13)))
                    .foregroundColor(.white)
                    .tracking(1)

                    SpeedLinesView()
                        .padding(.horizontal, 10)

                    Image("BusLogo")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .scaledToFit()
                        .frame(height: min(100, width * 0.24))
                }
                .offset(x: slideOffset)
            }
            .onAppear {
                guard !hasStarted else { return }
                hasStarted = true
                let offscreen = width * 0.55 + 200
                slideOffset = -offscreen

                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.85)) {
                        slideOffset = 0
                    }
                }

                let dwellAfterEnter: TimeInterval = 1.85
                let exitDuration: TimeInterval = 0.65
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85 + dwellAfterEnter) {
                    withAnimation(.easeIn(duration: exitDuration)) {
                        slideOffset = offscreen
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration + 0.05) {
                        onFinished()
                    }
                }
            }
        }
    }

    private func splashTitleFont(size: CGFloat) -> Font {
        let candidates = ["AKONY", "Akony", "AKONY-Regular", "Akony-Regular"]
        for name in candidates where UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: .black, design: .rounded)
    }
}

// MARK: - Speed lines (между текстом и автобусом)
private struct SpeedLinesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: CGFloat(18 - i * 3), height: 2)
            }
        }
        .frame(height: 72, alignment: .center)
    }
}

#Preview {
    SplashScreenView()
}
