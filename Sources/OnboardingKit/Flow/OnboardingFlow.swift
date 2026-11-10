//
//  OnboardingFlow.swift
//  OnboardingKit
//
//  Created by alex on 09/11/2026.
//

import Foundation

/// The flow to show: its steps and the identifier analytics reports.
///
/// Returned by ``OnboardingFlowProvider``. It holds what the flow is made of;
/// where its events go (``OnboardingAnalytics``) is given separately.
public struct OnboardingFlow {
    /// The steps, in display order. Must not be empty.
    public let steps: [any OnboardingStep]

    /// Identifies the flow in analytics, for example a variant of an A/B test;
    /// sent as `flow_id` with every event. `nil` when the app does not tell flows apart.
    public let flowID: String?

    /// Creates a flow from its steps, in the order they are shown.
    public init(steps: [any OnboardingStep], flowID: String? = nil) {
        self.steps = steps
        self.flowID = flowID
    }
}
