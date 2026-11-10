//
//  BackButtonStyle+Environment.swift
//  OnboardingKit
//

import SwiftUI

/// A type-erased back button style, used to store any style in the environment.
///
/// Created by ``SwiftUI/View/backButtonStyle(_:)``; apps never need to use it directly.
struct AnyBackButtonStyle {
    /// Whether the style is ``DefaultBackButtonStyle``.
    ///
    /// With `.perStep`, `true` keeps the native `NavigationStack` back button, and
    /// any other style replaces it. With `.pinned` there is no native button: the
    /// flag only picks the drawn button's vertical-toolbar behavior.
    let usesNativeButton: Bool

    private let makeBody: (BackButtonConfiguration) -> AnyView

    init<Style: BackButtonStyle>(_ style: Style) {
        usesNativeButton = style is DefaultBackButtonStyle
        makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: BackButtonConfiguration) -> AnyView {
        makeBody(configuration)
    }
}

extension EnvironmentValues {
    /// The style used to draw the onboarding back button. Defaults to `.automatic`.
    @Entry var backButtonStyle = AnyBackButtonStyle(.automatic)
}

extension View {
    /// Sets the style of the onboarding back button.
    ///
    /// Any style other than `.automatic` replaces the native back button; without
    /// it the system offers no swipe-back gesture or history menu.
    /// With `onboardingChrome(.pinned)` the button is always drawn by the style,
    /// `.automatic` included.
    ///
    /// ```swift
    /// OnboardingView(provider: provider) { ... }
    ///     .backButtonStyle(CircleBackButtonStyle())
    /// ```
    public func backButtonStyle<Style: BackButtonStyle>(_ style: Style) -> some View {
        environment(\.backButtonStyle, AnyBackButtonStyle(style))
    }
}
