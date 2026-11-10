//
//  SkipButtonStyle+Environment.swift
//  OnboardingKit
//

import SwiftUI

/// A type-erased Skip button style, used to store any style in the environment.
///
/// Created by ``SwiftUI/View/skipButtonStyle(_:)``; apps never need to use it directly.
struct AnySkipButtonStyle {
    private let makeBody: (SkipButtonConfiguration) -> AnyView

    init<Style: SkipButtonStyle>(_ style: Style) {
        makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: SkipButtonConfiguration) -> AnyView {
        makeBody(configuration)
    }
}

extension EnvironmentValues {
    /// The style used to draw the onboarding Skip button. Defaults to `.automatic`.
    @Entry var skipButtonStyle = AnySkipButtonStyle(.automatic)

    /// Whether the Skip button may move into the vertical toolbar on devices that
    /// have one, such as iPhone Duo. Defaults to `false`.
    @Entry var skipButtonPrefersSideBar = false
}

extension View {
    /// Sets the style of the onboarding Skip button.
    ///
    /// Applies only to the Skip button, not to buttons inside the steps' content.
    ///
    /// ```swift
    /// OnboardingView(provider: provider) { ... }
    ///     .skipButtonStyle(NotNowSkipButtonStyle())
    /// ```
    public func skipButtonStyle<Style: SkipButtonStyle>(_ style: Style) -> some View {
        environment(\.skipButtonStyle, AnySkipButtonStyle(style))
    }

    /// Lets the Skip button move into the vertical toolbar on devices that have one,
    /// such as iPhone Duo.
    ///
    /// Off by default: the Skip item has `axisBehavior(.horizontalOnly)`, so the
    /// button always stays in the top bar. When on, the item has
    /// `axisBehavior(.verticalPreferred)`, and the system may move the button to
    /// the vertical bar; whether it does is the system's decision. On a screen
    /// with a vertical toolbar the default style then draws a symbol instead of
    /// the title.
    ///
    /// A custom style should show a symbol only when both are true:
    /// `@Environment(\.skipButtonPrefersSideBar)` and
    /// `@Environment(\.toolbarVerticalEdge) != nil`. The second alone is not enough:
    /// it describes the whole toolbar and is set even when Skip stays in the top
    /// bar. See "The vertical toolbar" in ``SkipButtonStyle`` for an example.
    ///
    /// Works with both chrome placements, `.perStep` and `.pinned`: both use the
    /// system navigation bar. Has no effect before iOS 27.1, which introduced the
    /// vertical toolbar, and on devices without a vertical toolbar.
    ///
    /// ```swift
    /// OnboardingView(provider: provider) { ... }
    ///     .skipButtonPrefersSideBar()
    /// ```
    ///
    /// - Parameter prefersSideBar: Whether the button may move into the vertical bar.
    public func skipButtonPrefersSideBar(_ prefersSideBar: Bool = true) -> some View {
        environment(\.skipButtonPrefersSideBar, prefersSideBar)
    }
}
