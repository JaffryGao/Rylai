// LiquidGlassBackground.swift
// Rylai — macOS 26 Liquid Glass Background

import SwiftUI
import AppKit

// MARK: - Liquid Glass Background (macOS 26 Compatible)

struct LiquidGlassBackground: View {
    var intensity: Double = 0.85
    var cornerRadius: CGFloat = 20
    var tintColor: Color = .clear

    var body: some View {
        if #available(macOS 26.0, *) {
            LiquidGlassNative(intensity: intensity, cornerRadius: cornerRadius)
        } else {
            LiquidGlassFallback(intensity: intensity, cornerRadius: cornerRadius)
        }
    }
}

// MARK: - macOS 26 Native Liquid Glass

@available(macOS 26.0, *)
struct LiquidGlassNative: View {
    var intensity: Double
    var cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.clear)
            .glassEffect(.regular)
            .opacity(intensity)
    }
}

// MARK: - Backward Compatible (NSVisualEffectView Wrapper)

struct LiquidGlassFallback: NSViewRepresentable {
    var intensity: Double
    var cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .contentBackground  // Control Center style
        view.blendingMode = .behindWindow    // Capture behind content
        view.state = .active
        view.wantsLayer = true
        view.alphaValue = intensity
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.alphaValue = intensity
    }
}

// MARK: - Glass Card Container (translucent bg + thin border, avoids .glassEffect white block)

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 10
    var edgeInsets: EdgeInsets
    var intensity: Double = 0.85
    @ViewBuilder var content: () -> Content

    /// Uniform padding
    init(
        cornerRadius: CGFloat = 10,
        padding: CGFloat = 16,
        intensity: Double = 0.85,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.edgeInsets = EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
        self.intensity = intensity
        self.content = content
    }

    /// Custom EdgeInsets
    init(
        cornerRadius: CGFloat = 10,
        insets: EdgeInsets,
        intensity: Double = 0.85,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.edgeInsets = insets
        self.intensity = intensity
        self.content = content
    }

    var body: some View {
        content()
            .padding(edgeInsets)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.25),
                                .white.opacity(0.08),
                                .clear,
                                .white.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
    }
}

// MARK: - Pointer Cursor Modifier

struct PointerCursorModifier: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension View {
    func pointerCursor() -> some View {
        modifier(PointerCursorModifier())
    }
}

// MARK: - Liquid Glass Button

struct LiquidButton: View {
    var title: String
    var icon: String?
    var emoji: String?
    var action: () -> Void
    var isActive: Bool = false
    var accentColor: Color = .blue

    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Group {
                if let emoji {
                    // Two-line layout: emoji on top + text below
                    VStack(spacing: 2) {
                        Text(emoji)
                            .font(.system(size: 18))
                        Text(title)
                            .font(.system(size: 10, weight: .medium))
                    }
                } else {
                    HStack(spacing: 6) {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                    }
                }
            }
            .foregroundStyle(isActive ? accentColor : .primary)
            .frame(maxWidth: emoji != nil ? .infinity : nil)
            .padding(.horizontal, emoji != nil ? 6 : 14)
            .padding(.vertical, emoji != nil ? 8 : 8)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: emoji != nil ? 10 : 20, style: .continuous)
                        .fill(accentColor.opacity(0.2))
                        .overlay {
                            RoundedRectangle(cornerRadius: emoji != nil ? 10 : 20, style: .continuous)
                                .strokeBorder(accentColor.opacity(0.4), lineWidth: 1)
                        }
                } else {
                    RoundedRectangle(cornerRadius: emoji != nil ? 10 : 20, style: .continuous)
                        .fill(isHovered ? Color.primary.opacity(0.1) : Color.primary.opacity(0.04))
                        .overlay {
                            RoundedRectangle(cornerRadius: emoji != nil ? 10 : 20, style: .continuous)
                                .strokeBorder(.white.opacity(isHovered ? 0.2 : 0.08), lineWidth: 0.5)
                        }
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .pointerCursor()
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Glass Divider

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.15), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}

// MARK: - Ghost Icon Button (with hover feedback)

struct GhostIconButton: View {
    let icon: String
    let size: CGFloat
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .padding(8)
                .background {
                    Circle()
                        .fill(isHovered ? Color.primary.opacity(0.1) : .clear)
                }
                .contentShape(Circle())
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .pointerCursor()
        .onHover { isHovered = $0 }
    }
}

// MARK: - Liquid Glass Toggle Style

struct LiquidToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack(spacing: 8) {
                // Track
                    ZStack {
                        Capsule()
                            .fill(configuration.isOn ? Color.blue.opacity(0.2) : Color.primary.opacity(0.08))
                            .frame(width: 44, height: 24)

                        // Inner border
                        Capsule()
                            .strokeBorder(configuration.isOn ? Color.blue.opacity(0.4) : Color.white.opacity(0.15), lineWidth: 1)
                            .frame(width: 44, height: 24)

                        // Thumb
                        Circle()
                            .fill(configuration.isOn ? Color.blue : Color.gray)
                            .frame(width: 18, height: 18)
                            .shadow(color: configuration.isOn ? .blue.opacity(0.4) : .black.opacity(0.2), radius: 3)
                            .offset(x: configuration.isOn ? 10 : -10)
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isOn)
    }
}

// MARK: - Custom Toggle Component (with icon and label)

struct LiquidToggle: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(LiquidToggleStyle())
                .frame(width: 44, height: 24)
                .pointerCursor()
        }
    }
}

// MARK: - Ghost Text Button (text-based ghost button with hover feedback)

struct GhostTextButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .primary
    var fontSize: CGFloat = 11
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: fontSize - 1))
                }
                Text(title)
                    .font(.system(size: fontSize, weight: .medium))
            }
            .foregroundStyle(isHovered ? color : color.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(isHovered ? color.opacity(0.12) : color.opacity(0.05))
            }
            .contentShape(Capsule())
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .pointerCursor()
        .onHover { isHovered = $0 }
    }
}

// MARK: - Blurred Wallpaper Background (deprecated, use LiquidGlassBackgroundView)

struct BlurredWallpaperBackground: View {
    var blurRadius: CGFloat = 40
    var opacity: Double = 0.6

    var body: some View {
        GeometryReader { geometry in
            if let screen = NSScreen.main,
               let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen),
               let nsImage = NSImage(contentsOf: wallpaperURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: blurRadius)
                    .opacity(opacity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(.black.opacity(0.5))
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - System-level Liquid Glass Background (NSVisualEffectView live capture)

struct LiquidGlassBackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .contentBackground  // Control Center style material
        view.blendingMode = .behindWindow    // Capture content behind window
        view.state = .active                 // Always active
        view.wantsLayer = true
        view.layer?.cornerRadius = 0
        view.layer?.cornerCurve = .continuous
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // No updates needed
    }
}
