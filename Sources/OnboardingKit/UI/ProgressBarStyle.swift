//
//  ProgressBarStyle.swift
//  OnboardingKit
//

import SwiftUI

/// The data a progress bar style needs to draw itself.
///
/// Progress counts the current step as reached: on step N of M,
/// N segments are filled. The first step shows one segment,
/// the last step shows the bar full.
public struct ProgressBarConfiguration {
    /// The zero-based index of the current step.
    public let currentIndex: Int

    /// The total number of steps in the flow.
    public let total: Int

    /// The number of filled segments: step N of M fills N.
    ///
    /// Always within `0...total`, even for an out-of-range `currentIndex`
    /// (for example, one passed by a preview of a custom style).
    public var completedCount: Int {
        min(max(currentIndex + 1, 0), max(total, 0))
    }

    /// The completed part of the flow, from `0` to `1`.
    ///
    /// Use it for continuous styles (a line, a moving marker).
    /// Returns `0` for an empty flow.
    public var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(completedCount) / Double(total) 
    }

    /// Creates a configuration, for previews and tests of a style.
    public init(currentIndex: Int, total: Int) {
        self.currentIndex = currentIndex
        self.total = total
    }
}

/// Defines how the onboarding progress bar looks.
///
/// A style only draws the bar from the given configuration. Whether the bar
/// is visible on a step is decided by ``StepConfiguration/isProgressBarShown``.
///
/// ## Light and dark appearance
///
/// Colors that differ between themes need no extra code: use system colors,
/// asset catalog colors with a dark variant, or `Color(light:dark:)`.
///
/// When more than a color differs (a shadow only in light mode, another shape),
/// return a view that reads `@Environment(\.colorScheme)`. A style method cannot
/// read the environment itself, but the view it returns can:
///
/// ```swift
/// struct GlowProgressBarStyle: ProgressBarStyle {
///     func makeBody(configuration: ProgressBarConfiguration) -> some View {
///         GlowProgressBar(fraction: configuration.fraction)
///     }
/// }
///
/// private struct GlowProgressBar: View {
///     let fraction: Double
///     @Environment(\.colorScheme) private var colorScheme
///
///     var body: some View {
///         ProgressView(value: fraction)
///             .shadow(color: colorScheme == .dark ? .cyan : .clear, radius: 4)
///     }
/// }
/// ```
///
/// The same applies to ``SkipButtonStyle`` and ``BackButtonStyle``.
public protocol ProgressBarStyle {
    /// The type of view produced by the style.
    associatedtype Body: View

    /// Creates the progress bar for the given configuration.
    @ViewBuilder func makeBody(configuration: ProgressBarConfiguration) -> Body
}

/// The default colors and thickness shared by the built-in progress bar styles.
///
/// Defined once so `.line` and `.segmented` look consistent.
public enum ProgressBarDefaults {
    /// The color of the completed part: the app's accent color (`Color.accentColor`).
    /// Adapts to light and dark appearance, as the app's accent color does.
    public static let filledColor = Color.accentColor

    /// The color of the remaining part. Adapts to light and dark appearance.
    public static let emptyColor = Color.secondary.opacity(0.3)

    /// The thickness of the built-in bars.
    public static let height: CGFloat = 4
}
