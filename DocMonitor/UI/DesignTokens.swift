import SwiftUI

enum AppFont {

    // MARK: - Scale

    // Panel title — "DocMonitor"
    static let title: Font         = .system(size: 14, weight: .semibold)

    // Primary row text — container name, image tag, service name
    static let body: Font          = .system(size: 14)

    // Buttons, inputs, form actions
    static let action: Font        = .system(size: 13)
    
    // Label status compose
    static let statusCompose: Font = .system(size: 12)

    // Section headers, badges, secondary info
    static let caption: Font       = .system(size: 11)

    // Section labels, form section titles, metadata
    static let label: Font         = .system(size: 10, weight: .semibold)

    // Secondary metadata — image ID, size, age
    static let metadata: Font      = .system(size: 10)

    // Chevrons, small controls
    static let micro: Font         = .system(size: 10, weight: .medium)

    // Build output console
    static let mono: Font          = .system(size: 9, design: .monospaced)
}

// MARK: - Icon Sizes

enum AppIcon {
    
    // Terminal icon
    static let terminalIcon: CGFloat = 17

    // Row SVG icons — docker, container, image, compose
    static let rowIcon: CGFloat      = 16
    
    // Trashs
    static let trashIcon: Font       = .system(size: 13)

    // Status dot — service running indicator
    static let statusDot: CGFloat    = 9

    // Compose status dot
    static let composeDot: CGFloat   = 8
}

// MARK: - Surfaces

enum AppSurface {
    // White background for grouped cards (Services, Containers, Compose, Images)
    static let cardFill:   Double = 0.20
    static let cardStroke: Double = 0.30
}

// MARK: - Foreground

enum AppForeground {
    // Placeholder opacity in macOS 27 (in macOS 26, `.tertiary` remains unchanged).
    static let placeholderOpacity: Double = 0.25

    static var placeholder: AnyShapeStyle {
        if #available(macOS 27, *) {
            return AnyShapeStyle(Color.primary.opacity(placeholderOpacity))
        } else {
            return AnyShapeStyle(HierarchicalShapeStyle.tertiary)
        }
    }
}

// MARK: - Control Sizes

enum AppControl {
    // Toggle switch scale relative to .mini
    // Used in ContainerRow and ComposeProjectRow
    static let switchControlSize: ControlSize = .small
}
