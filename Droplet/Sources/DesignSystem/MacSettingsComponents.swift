import SwiftUI

struct MacNavigationHeader: View {
    let title: String
    let theme: Theme
    let backAction: () -> Void
    var trailingSystemImage: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack {
            Button(action: backAction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textColor.opacity(0.7))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textColor)

            Spacer()

            if let trailingSystemImage, let trailingAction {
                Button(action: trailingAction) {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 14, height: 14)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.backgroundColor)
    }
}

struct MacSettingsSection<Content: View>: View {
    let title: String
    let theme: Theme
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(theme.textColor.opacity(0.5))
                .textCase(.uppercase)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.textColor.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(theme.textColor.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

struct MacSettingRow<Content: View>: View {
    let label: String
    let theme: Theme
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(theme.textColor)

            Spacer()

            content()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

struct MacToggleRow: View {
    let label: String
    let theme: Theme
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(theme.textColor)

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

struct MacSettingsSliderRow: View {
    let label: String
    let valueText: String
    let theme: Theme
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    var step: Double = 0.01

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textColor)

                Spacer()

                Text(valueText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textColor.opacity(0.58))
                    .monospacedDigit()
            }

            Slider(value: $value, in: range, step: step)
                .tint(theme.workAccent)
                .controlSize(.small)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

struct MacThemeSwatchButton: View {
    let option: Theme
    let currentTheme: Theme
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(option.backgroundColor)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(option.workAccent)

                        Circle()
                            .fill(option.breakAccent)
                    }
                    .frame(width: 34, height: 14)
                }
                .frame(height: 34)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(
                            isSelected ? option.workAccent : option.textColor.opacity(isHovering ? 0.32 : 0.18),
                            lineWidth: isSelected ? 2 : 1
                        )
                )

                Text(option.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(currentTheme.textColor.opacity(isSelected ? 1 : 0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .contentShape(Rectangle())
            .scaleEffect(isHovering ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(option.rawValue)
    }
}

struct MacSettingsActionButton: View {
    let title: String
    let systemImage: String
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(theme.backgroundColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(theme.workAccent)
                )
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func macSettingsPicker(width: CGFloat) -> some View {
        labelsHidden()
            .frame(width: width)
            .controlSize(.small)
    }

    func macInlineTextField(theme: Theme, width: CGFloat) -> some View {
        textFieldStyle(.plain)
            .font(.system(size: 12))
            .foregroundColor(theme.textColor)
            .frame(width: width)
            .multilineTextAlignment(.center)
            .padding(4)
            .background(theme.textColor.opacity(0.1))
            .cornerRadius(4)
    }
}
