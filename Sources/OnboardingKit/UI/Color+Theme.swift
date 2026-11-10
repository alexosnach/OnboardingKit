//
//  Color+Theme.swift
//  OnboardingKit
//

import SwiftUI
import UIKit

extension Color {
    /// A color that switches between two colors with the light and dark appearance.
    ///
    /// The color adapts on its own: when the system theme changes, every view that
    /// uses it redraws with the matching color. Nothing needs to read `colorScheme`.
    ///
    /// Works with every onboarding style, built-in or custom, because a style
    /// only receives a `Color`:
    ///
    /// ```swift
    /// OnboardingView(provider: provider) { ... }
    ///     .progressBarStyle(.line(
    ///         filledColor: Color(light: .indigo, dark: .mint),
    ///         emptyColor: Color(light: .black.opacity(0.1), dark: .white.opacity(0.2))
    ///     ))
    /// ```
    ///
    /// For colors from an asset catalog, set their dark variant in the catalog instead;
    /// they adapt the same way.
    ///
    /// - Parameters:
    ///   - light: The color used with the light appearance.
    ///   - dark: The color used with the dark appearance.
    public init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}
