//
//  OnboardingAnalytics.swift
//  OnboardingKit
//
//  Created by alex on 09/11/2026.
//

import Foundation

/// Receives the onboarding's funnel events.
///
/// The app implements it as an adapter to its own analytics: send
/// `event.name` and `event.parameters` as they are, or build its own names
/// from the typed fields (`event.kind`, `event.step`, `event.flowID`).
///
/// ```swift
/// struct AppAnalytics: OnboardingAnalytics {
///     func track(_ event: OnboardingAnalyticsEvent) {
///         AnalyticsManager.shared.send(event.name, parameters: event.parameters)
///     }
/// }
///
/// OnboardingView(provider: provider, analytics: AppAnalytics()) { ... }
/// ```
///
/// `flow_id` comes from the ``OnboardingFlow`` the provider returned.
///
/// Only the funnel comes here. Events inside a step (a permission answer, a
/// choice) the step sends to the app's analytics itself, with `flow_id` and
/// `step_id` read from ``SwiftUI/EnvironmentValues/onboardingFlowID`` and ``SwiftUI/EnvironmentValues/onboardingStepInfo`` in the environment.
///
/// Events come on the main thread, synchronously, at the moment the flow's
/// state changes: before the transition animation (a swipe back changes the
/// state only when the gesture ends). Keep `track(_:)` fast;
/// send to the network from your analytics manager, not from here.
public protocol OnboardingAnalytics {
    /// Called once for every event of the flow, in the order they happen.
    func track(_ event: OnboardingAnalyticsEvent)
}

/// Analytics that ignores every event: the default when the app passes none.
public struct NoOpOnboardingAnalytics: OnboardingAnalytics {
    public func track(_ event: OnboardingAnalyticsEvent) {}
    /// Creates the analytics that drops every event.
    public init() {}
}
