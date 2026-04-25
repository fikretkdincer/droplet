import SwiftUI
import AppKit

struct EyeRestOverlayView: View {
    @State private var remainingSeconds = 20
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Blurred background
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(spacing: 12) {
                    Text("20-20-20 Rule")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("You've been working for 20 minutes.\nLook at something 20 feet (6 meters) away to rest your eyes.")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                
                // Countdown circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(remainingSeconds) / 20.0)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: remainingSeconds)
                    
                    Text("\(remainingSeconds)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.top, 20)
                
                Button(action: {
                    onClose()
                }) {
                    Text("Skip")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(timer) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                onClose()
            }
        }
    }
}

/// Helper wrapper for NSVisualEffectView
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
