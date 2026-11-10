//
//  SkipButtonStyle.swift
//  OnboardingKit
//

import SwiftUI

/// The data a Skip button style needs to draw itself.
public struct SkipButtonConfiguration {
    /// Skips the current step. Call it from the style's button.
    ///
    /// The style does not know how skipping works: the onboarding provides this action.
    public let skip: () -> Void

    /// Creates a configuration, for previews and tests of a style.
    public init(skip: @escaping () -> Void) {
        self.skip = skip
    }
}

/// Defines how the onboarding Skip button looks.
///
/// For light and dark appearance, see "Light and dark appearance" in ``ProgressBarStyle``:
/// use adaptive colors such as `Color(light:dark:)`, or read `colorScheme` in the returned view.
///
/// A style draws the whole button: its text, icon and colors.
/// Whether the button is visible on a step is decided by
/// ``StepConfiguration/isSkipButtonShown``, not by the style.
///
/// ```swift
/// struct NotNowSkipButtonStyle: SkipButtonStyle {
///     func makeBody(configuration: SkipButtonConfiguration) -> some View {
///         Button("Not now", action: configuration.skip)
///             .foregroundStyle(.secondary)
///     }
/// }
/// ```
///
/// ## The vertical toolbar (iPhone Duo)
///
/// On devices with a vertical toolbar, Skip stays in the top bar by default: the
/// onboarding gives its item `axisBehavior(.horizontalOnly)`. When the app calls
/// ``SwiftUI/View/skipButtonPrefersSideBar(_:)``, the item gets `axisBehavior(.verticalPreferred)`
/// instead, and the system may move Skip to the side bar.
/// Whether it does is the system's decision, not the onboarding's. The side bar is
/// narrow, so a style should draw a symbol for it, not a word.
///
/// A style decides what to draw from two environment values:
/// - `toolbarVerticalEdge` (iOS 27.1 and later): the edge of the vertical toolbar,
///   or `nil` when the screen has none. It describes the whole toolbar, not this
///   button: as observed, it is set even when Skip itself stays in the top bar.
/// - `skipButtonPrefersSideBar`: whether the app let Skip move to the side bar.
///
/// Skip can be in the side bar only when both are true, so draw the symbol only
/// then. Checking only `toolbarVerticalEdge` would draw the symbol in the top bar
/// of an app that did not opt in. Both being true means only that Skip *may* be in
/// the side bar: neither value tells where the system finally put it.
///
/// `makeBody` cannot read the environment, so put the logic in a separate view
/// and return it from the style. Keep the title in the `Label` so VoiceOver still
/// reads it when only the symbol is shown:
///
/// ```swift
/// struct SideBarNotNowSkipButtonStyle: SkipButtonStyle {
///     func makeBody(configuration: SkipButtonConfiguration) -> some View {
///         NotNowSkipButton(skip: configuration.skip)
///     }
/// }
///
/// private struct NotNowSkipButton: View {
///     let skip: () -> Void
///
///     var body: some View {
///         Button(action: skip) {
///             // The vertical toolbar exists only from iOS 27.1.
///             if #available(iOS 27.1, *) {
///                 SideBarAwareLabel()
///             } else {
///                 Text("Not now")
///             }
///         }
///     }
/// }
///
/// @available(iOS 27.1, *)
/// private struct SideBarAwareLabel: View {
///     @Environment(\.toolbarVerticalEdge) private var verticalEdge
///     @Environment(\.skipButtonPrefersSideBar) private var prefersSideBar
///
///     var body: some View {
///         if prefersSideBar && verticalEdge != nil {
///             // In the side bar: the symbol only.
///             Label("Not now", systemImage: "xmark")
///                 .labelStyle(.iconOnly)
///         } else {
///             // In the top bar: the title.
///             Text("Not now")
///         }
///     }
/// }
/// ```
///
/// The default style, `.automatic`, does exactly this with the `chevron.forward` symbol.
/// This works with both `.perStep` and `.pinned` chrome. Before iOS 27.1, on
/// devices without a vertical toolbar, or without the opt-in, the button is
/// always in the top bar.
public protocol SkipButtonStyle {
    /// The type of view produced by the style.
    associatedtype Body: View

    /// Creates the Skip button for the given configuration.
    @ViewBuilder func makeBody(configuration: SkipButtonConfiguration) -> Body
}
