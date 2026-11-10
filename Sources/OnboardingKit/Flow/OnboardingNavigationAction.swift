//
//  OnboardingNavigationAction.swift
//  OnboardingKit
//

import SwiftUI

/// An action a step calls to move the onboarding flow.
///
/// Read it from the environment and call it like a function,
/// the same way as `DismissAction`:
///
/// ```swift
/// @Environment(\.onboardingNext) private var next
///
/// Button("Continue") { next() }
/// ```
///
/// The step does not know who handles the action or where the flow goes next.
public struct OnboardingNavigationAction {
    private let handler: () -> Void

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    public func callAsFunction() {
        handler()
    }
}

extension EnvironmentValues {
    /// Moves to the next step, or completes the onboarding on the last step.
    ///
    /// Provided by ``OnboardingView``. Outside of it the action does nothing.
    @Entry public var onboardingNext = OnboardingNavigationAction {}

    /// Skips the current step.
    ///
    /// Provided by ``OnboardingView``. Outside of it the action does nothing.
    @Entry public var onboardingSkip = OnboardingNavigationAction {}
}
