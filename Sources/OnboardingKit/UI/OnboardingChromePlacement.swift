//
//  OnboardingChromePlacement.swift
//  OnboardingKit
//

import SwiftUI

/// Where the onboarding chrome — back button, progress bar and Skip — is drawn.
///
/// A closed set defined by the onboarding, so it is an `enum`.
public enum OnboardingChromePlacement {

    /// Each step has its own system navigation bar. The default.
    ///
    /// The chrome slides in and out together with the step, as part of the
    /// system's push and pop. With the default back button style (`.automatic`),
    /// the native back button is kept, and with it the swipe-back gesture and the
    /// long-press history menu. A custom ``BackButtonStyle`` replaces the native
    /// button even here.
    case perStep

    /// One navigation bar for the whole onboarding that never moves.
    ///
    /// Only the step content slides during transitions; the back button,
    /// progress bar and Skip stay in place and appear or disappear according to
    /// each step's ``StepConfiguration``.
    ///
    /// It is still the system navigation bar: the steps are shown on one screen
    /// instead of being pushed, so the system lays out the bar as usual — next to
    /// the status bar, with glass buttons, in the vertical bar of iPhone Duo,
    /// mirrored in right-to-left languages.
    ///
    /// - Important: Nothing is pushed, so the back button is always drawn by
    ///   ``BackButtonStyle`` (`.automatic` draws a system-looking chevron), and the
    ///   swipe-back gesture and history menu are not available.
    ///   Content slides only for moves made through the onboarding (Continue,
    ///   Skip and back); a move made by calling the coordinator directly is not
    ///   animated.
    case pinned
}

extension EnvironmentValues {
    /// Where the onboarding chrome is drawn. Defaults to `.perStep`.
    @Entry var onboardingChromePlacement: OnboardingChromePlacement = .perStep
}

extension View {
    /// Sets where the onboarding chrome is drawn.
    ///
    /// ```swift
    /// OnboardingView(provider: provider) { ... }
    ///     .onboardingChrome(.pinned)
    /// ```
    public func onboardingChrome(_ placement: OnboardingChromePlacement) -> some View {
        environment(\.onboardingChromePlacement, placement)
    }
}
