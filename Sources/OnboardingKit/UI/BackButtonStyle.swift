//
//  BackButtonStyle.swift
//  OnboardingKit
//

import SwiftUI

/// The data a back button style needs to draw itself.
public struct BackButtonConfiguration {
    /// Returns to the previous step. Call it from the style's button.
    ///
    /// The style does not know how going back works: the onboarding provides this action.
    public let back: () -> Void

    /// Creates a configuration, for previews and tests of a style.
    public init(back: @escaping () -> Void) {
        self.back = back
    }
}

/// Defines how the onboarding back button looks.
///
/// For light and dark appearance, see "Light and dark appearance" in ``ProgressBarStyle``:
/// use adaptive colors such as `Color(light:dark:)`, or read `colorScheme` in the returned view.
///
/// By default the onboarding uses the native back button of `NavigationStack`.
/// A custom style replaces it with its own button on the leading side
/// of the navigation bar. With `onboardingChrome(.pinned)` nothing is pushed, so
/// there is no native button: the style always draws it (`.automatic` draws a chevron).
///
/// Whether the button is visible on a step is decided by
/// ``StepConfiguration/isBackButtonShown``, not by the style.
/// It is never shown on the first step.
///
/// - Important: A custom style hides the native button, and without it the system
///   offers no swipe-back gesture or long-press history menu. Keep the default
///   style with `.perStep` chrome if you need them.
///
/// ```swift
/// struct CircleBackButtonStyle: BackButtonStyle {
///     func makeBody(configuration: BackButtonConfiguration) -> some View {
///         Button(action: configuration.back) {
///             Image(systemName: "chevron.backward.circle.fill")
///         }
///         .accessibilityLabel("Back")
///     }
/// }
/// ```
///
/// ## The vertical toolbar (iPhone Duo)
///
/// On iOS 27.1 and later, when the onboarding draws the back button itself (any
/// custom style, or `.automatic` with `.pinned`), it sets the item's axis behavior:
/// `.verticalPreferred` for `.automatic`, `.automatic` for a custom style, so for
/// a custom style the system decides whether it moves to the side bar. With
/// `.perStep` and `.automatic`, the native button is used, and where it goes is the
/// system's decision. Unlike Skip, there is no opt-in.
///
/// A style can read `@Environment(\.toolbarVerticalEdge)` (iOS 27.1 and later),
/// but it describes the whole toolbar, not this button: as observed, it is set even when the
/// button stays in the top bar. So it cannot tell where a custom button ended up.
/// An icon-only style looks right in both bars.
public protocol BackButtonStyle {
    /// The type of view produced by the style.
    associatedtype Body: View

    /// Creates the back button for the given configuration.
    @ViewBuilder func makeBody(configuration: BackButtonConfiguration) -> Body
}
