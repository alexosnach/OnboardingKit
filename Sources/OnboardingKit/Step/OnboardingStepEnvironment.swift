//
//  OnboardingStepEnvironment.swift
//  OnboardingKit
//

import SwiftUI

extension EnvironmentValues {
    /// The step this content belongs to: its `id`, position and the number of steps.
    ///
    /// Provided by ``OnboardingView`` to every step's content; `nil` outside of it.
    /// Use it to tie the step's own analytics events to the onboarding funnel,
    /// with the same values the onboarding sends as `step_id`, `step_index`
    /// and `step_count`:
    ///
    /// ```swift
    /// @Environment(\.onboardingStepInfo) private var step
    /// @Environment(\.onboardingFlowID) private var flowID
    ///
    /// .task { viewModel.configure(step: step, flowID: flowID) }
    /// ```
    @Entry public var onboardingStepInfo: OnboardingStepInfo?

    /// ``OnboardingFlow/flowID`` of the flow being shown, sent to analytics as `flow_id`.
    ///
    /// Provided by ``OnboardingView``; `nil` outside of it or when the flow has none.
    @Entry public var onboardingFlowID: String?
}
