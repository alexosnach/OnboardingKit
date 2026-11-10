//
//  SegmentedProgressBarStyle.swift
//  OnboardingKit
//
//  Created by alex on 07/11/2026.
//

import SwiftUI

/// A progress bar made of one segment per step.
///
/// Fills one segment per reached step: on step N of M, N segments are filled.
/// The number of segments follows the number of steps automatically.
///
/// Use the shorthand `.segmented` for the default colors, or
/// `.segmented(filledColor:emptyColor:)` to set your own:
///
/// ```swift
/// OnboardingView(provider: provider) { ... }
///     .progressBarStyle(.segmented(filledColor: .purple, emptyColor: .purple.opacity(0.2)))
/// ```
public struct SegmentedProgressBarStyle: ProgressBarStyle {

    /// The color of reached steps.
    public let filledColor: Color

    /// The color of steps not reached yet.
    public let emptyColor: Color

    /// Creates the style. Both colors are optional and fall back to ``ProgressBarDefaults``.
    public init(
        filledColor: Color = ProgressBarDefaults.filledColor,
        emptyColor: Color = ProgressBarDefaults.emptyColor
    ) {
        self.filledColor = filledColor
        self.emptyColor = emptyColor
    }

    public func makeBody(configuration: ProgressBarConfiguration) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<configuration.total, id: \.self) { index in
                Capsule()
                    .fill(color(forSegment: index, configuration: configuration))
                    .frame(height: ProgressBarDefaults.height)
            }
        }
    }

    /// The color of one segment: filled if the step is reached, empty otherwise.
    func color(forSegment index: Int, configuration: ProgressBarConfiguration) -> Color {
        index < configuration.completedCount ? filledColor : emptyColor
    }
}

extension ProgressBarStyle where Self == SegmentedProgressBarStyle {
    /// A progress bar made of one segment per step, in the default colors.
    public static var segmented: Self { .init() }

    /// A progress bar made of one segment per step, in the given colors.
    ///
    /// - Parameters:
    ///   - filledColor: The color of reached steps. Defaults to the accent color.
    ///   - emptyColor: The color of steps not reached yet.
    public static func segmented(
        filledColor: Color = ProgressBarDefaults.filledColor,
        emptyColor: Color = ProgressBarDefaults.emptyColor
    ) -> Self {
        .init(filledColor: filledColor, emptyColor: emptyColor)
    }
}

#Preview("Default colors") {
    let style: some ProgressBarStyle = .segmented

    style
        .makeBody(configuration: .init(currentIndex: 3, total: 10))
        .padding()
}

#Preview("Custom colors") {
    let style: some ProgressBarStyle = .segmented(filledColor: .purple, emptyColor: .purple.opacity(0.2))

    style
        .makeBody(configuration: .init(currentIndex: 3, total: 10))
        .padding()
}
