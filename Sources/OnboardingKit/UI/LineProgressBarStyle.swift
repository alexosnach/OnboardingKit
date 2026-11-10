//
//  LineProgressBarStyle.swift
//  OnboardingKit
//

import SwiftUI

/// A progress bar drawn as one continuous line. The default style.
///
/// The filled part takes `configuration.fraction` of the line: on step N of M
/// it covers N/M, so the first step already shows progress and the last step
/// shows a full line. It grows from the leading edge, so it mirrors
/// automatically in right-to-left languages. With `.pinned` chrome the fill
/// animates for moves made through the onboarding (Continue, Skip, back); a move
/// made by calling the coordinator directly is not animated. With `.perStep` each
/// step's bar slides in with its screen, already at that step's progress.
///
/// Use the shorthand `.line` for the default colors, or
/// `.line(filledColor:emptyColor:)` to set your own:
///
/// ```swift
/// OnboardingView(provider: provider) { ... }
///     .progressBarStyle(.line(filledColor: .purple, emptyColor: .purple.opacity(0.2)))
/// ```
public struct LineProgressBarStyle: ProgressBarStyle {

    /// The color of the completed part.
    public let filledColor: Color

    /// The color of the remaining part.
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
        Capsule()
            .fill(emptyColor)
            .overlay {
                FilledPart(fraction: configuration.fraction)
                    .fill(filledColor)
                    // Grows from the leading edge: from the right in right-to-left languages.
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .frame(height: ProgressBarDefaults.height)
    }
}

/// The completed part of the line: a capsule from the leading edge.
///
/// A shape, so it is drawn in the line's frame of every animation frame: it
/// stays attached to the line's edge while the line itself moves or resizes.
/// The fraction animates with the step change that sets it.
private struct FilledPart: Shape {
    var fraction: Double

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let width = rect.width * min(max(fraction, 0), 1)
        return Capsule().path(in: CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
    }
}

extension ProgressBarStyle where Self == LineProgressBarStyle {
    /// A continuous progress line in the default colors.
    public static var line: Self { .init() }

    /// A continuous progress line in the given colors.
    ///
    /// - Parameters:
    ///   - filledColor: The color of the completed part. Defaults to the accent color.
    ///   - emptyColor: The color of the remaining part.
    public static func line(
        filledColor: Color = ProgressBarDefaults.filledColor,
        emptyColor: Color = ProgressBarDefaults.emptyColor
    ) -> Self {
        .init(filledColor: filledColor, emptyColor: emptyColor)
    }
}

#Preview("Default colors") {
    let style: some ProgressBarStyle = .line

    style
        .makeBody(configuration: .init(currentIndex: 3, total: 10))
        .padding()
}

#Preview("Custom colors") {
    let style: some ProgressBarStyle = .line(filledColor: .purple, emptyColor: .purple.opacity(0.2))

    style
        .makeBody(configuration: .init(currentIndex: 3, total: 10))
        .padding()
}
