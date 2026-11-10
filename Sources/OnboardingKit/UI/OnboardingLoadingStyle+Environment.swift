//
//  OnboardingLoadingStyle+Environment.swift
//  OnboardingKit
//

import SwiftUI

/// A type-erased ``OnboardingLoadingStyle``, so any style can be stored in the environment.
struct AnyOnboardingLoadingStyle {
    private let makeBody: (OnboardingLoadingConfiguration) -> AnyView

    init<Style: OnboardingLoadingStyle>(_ style: Style) {
        makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: OnboardingLoadingConfiguration) -> AnyView {
        makeBody(configuration)
    }
}

extension EnvironmentValues {
    /// The style used to draw the onboarding's loading screen. Defaults to `.automatic`.
    @Entry var onboardingLoadingStyle = AnyOnboardingLoadingStyle(.automatic)
}

extension View {
    /// Sets the style of the screen shown while the onboarding waits for its flow.
    ///
    /// ```swift
    /// OnboardingView(...)
    ///     .onboardingLoadingStyle(BrandLoadingStyle())
    /// ```
    public func onboardingLoadingStyle<Style: OnboardingLoadingStyle>(_ style: Style) -> some View {
        environment(\.onboardingLoadingStyle, AnyOnboardingLoadingStyle(style))
    }
}
