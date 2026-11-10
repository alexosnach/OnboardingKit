//
//  ProgressBarStyle+Environment.swift
//  OnboardingKit
//

import SwiftUI

/// A type-erased progress bar style, used to store any style in the environment.
///
/// Created by ``SwiftUI/View/progressBarStyle(_:)``; apps never need to use it directly.
struct AnyProgressBarStyle {
    private let makeBody: (ProgressBarConfiguration) -> AnyView

    init<Style: ProgressBarStyle>(_ style: Style) {
        makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: ProgressBarConfiguration) -> AnyView {
        makeBody(configuration)
    }
}

extension EnvironmentValues {
    /// The style used to draw the onboarding progress bar. Defaults to `.line`.
    @Entry var progressBarStyle = AnyProgressBarStyle(.line)
}

extension View {
    /// Sets the style of the onboarding progress bar.
    ///
    /// ```swift
    /// OnboardingView(provider: provider) { ... }
    ///     .progressBarStyle(.segmented)   // the default is `.line`
    /// ```
    public func progressBarStyle<Style: ProgressBarStyle>(_ style: Style) -> some View {
        environment(\.progressBarStyle, AnyProgressBarStyle(style))
    }
}
