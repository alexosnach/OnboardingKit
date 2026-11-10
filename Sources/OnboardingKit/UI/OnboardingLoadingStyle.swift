//
//  OnboardingLoadingStyle.swift
//  OnboardingKit
//
//  Created by alex on 09/11/2026.
//

import SwiftUI

/// The data a loading style needs to draw itself.
///
/// Empty for now: the loading screen only waits. It is kept as a type, like the
/// configurations of the other styles, so fields can be added later without
/// breaking the styles apps have written.
public struct OnboardingLoadingConfiguration {
    /// Creates an empty configuration, for previews and tests of a style.
    public init() {}

}

/// Defines how the screen looks while the onboarding waits for its flow
/// from ``OnboardingFlowProvider``.
///
/// The style draws the whole screen, edge to edge: background, indicator and
/// any text or logo. How long the wait may take is decided by the provider
/// (its timeout), not by the style.
///
/// For light and dark appearance, see "Light and dark appearance" in ``ProgressBarStyle``:
/// use adaptive colors such as `Color(light:dark:)`, or read `colorScheme` in the returned view.
///
/// ```swift
/// struct BrandLoadingStyle: OnboardingLoadingStyle {
///     func makeBody(configuration: OnboardingLoadingConfiguration) -> some View {
///         VStack(spacing: 16) {
///             Image("Logo")
///             ProgressView()
///         }
///         .frame(maxWidth: .infinity, maxHeight: .infinity)
///         .background(Color.brandBackground)
///     }
/// }
/// ```
public protocol OnboardingLoadingStyle {
    /// The type of view produced by the style.
    associatedtype Body: View

    /// Creates the loading screen for the given configuration.
    @ViewBuilder func makeBody(configuration: OnboardingLoadingConfiguration) -> Body
}
