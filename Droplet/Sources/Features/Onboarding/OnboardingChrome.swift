import SwiftUI

// MARK: - Carousel helper

extension View {
    func carouselPage(index: Int, current: Int) -> some View {
        self
            .frame(width: 540)
            .offset(x: CGFloat(index - current) * 540)
            .animation(.easeInOut(duration: 0.32), value: current)
    }
}

// MARK: - Chrome (top bar + bottom bar)

extension OnboardingView {

    var topBar: some View {
        HStack {
            Spacer()
            if currentPage < lastPageIndex {
                Button("Skip") { complete() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(previewTheme.textColor.opacity(0.35))
            } else {
                Color.clear.frame(width: 1, height: 14)
            }
        }
        .frame(height: 38)
        .padding(.horizontal, 22)
    }

    var bottomBar: some View {
        HStack(alignment: .center) {
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<Self.pageCount, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage
                              ? previewTheme.workAccent
                              : previewTheme.textColor.opacity(0.2))
                        .frame(
                            width:  i == currentPage ? 7 : 5,
                            height: i == currentPage ? 7 : 5
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }

            Spacer()

            if currentPage > 0 && currentPage < lastPageIndex {
                Button(action: previous) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(previewTheme.textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(previewTheme.textColor.opacity(0.08))
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }

            if currentPage < lastPageIndex {
                Button(action: advance) {
                    HStack(spacing: 5) {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(previewTheme.backgroundColor)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(previewTheme.workAccent)
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }
}

// MARK: - Shared onboarding controls

struct OnboardingChoiceButton: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 1) {
                    Text(title)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .opacity(0.65)
                    }
                }

                Spacer(minLength: 0)
            }
            .foregroundColor(isSelected ? theme.workAccent : theme.textColor.opacity(0.72))
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity)
            .frame(height: subtitle == nil ? 30 : 36)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? theme.workAccent.opacity(0.16) : theme.textColor.opacity(isHovering ? 0.1 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(isSelected ? theme.workAccent.opacity(0.72) : theme.textColor.opacity(isHovering ? 0.18 : 0.08), lineWidth: isSelected ? 1.3 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

struct OnboardingToggleRow: View {
    let title: String
    let subtitle: String
    let theme: Theme
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textColor)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(theme.textColor.opacity(0.55))
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(theme.textColor.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(theme.textColor.opacity(0.08), lineWidth: 1)
        )
    }
}

struct OnboardingPanel<Content: View>: View {
    let theme: Theme
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 8) {
            content()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(theme.textColor.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(theme.textColor.opacity(0.08), lineWidth: 1))
    }
}
