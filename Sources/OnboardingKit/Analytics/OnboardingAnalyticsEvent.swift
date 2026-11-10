//
//  OnboardingAnalyticsEvent.swift
//  OnboardingKit
//
//  Created by alex on 09/11/2026.
//

import Foundation

/// An event as analytics receives it: what happened and in which flow.
///
/// New fields are added here, so adapters keep compiling when the event grows.
public struct OnboardingAnalyticsEvent {
    /// What happened, with typed data: use it for logic.
    public let kind: OnboardingEvent

    /// ``OnboardingFlow/flowID`` of the flow the provider returned, for example a
    /// variant of an A/B test; `nil` when the flow has none.
    public let flowID: String?

    /// Creates an event, for tests of an analytics implementation.
    public init(kind: OnboardingEvent, flowID: String?) {
        self.kind = kind
        self.flowID = flowID
    }
}

extension OnboardingAnalyticsEvent {
    /// The event's name for analytics systems: snake_case with the `onboarding_` prefix.
    public var name: String {
        switch kind {
        case .started: "onboarding_started"
        case .stepShown: "onboarding_step_shown"
        case .stepContinued: "onboarding_step_continued"
        case .stepSkipped: "onboarding_step_skipped"
        case .stepBack: "onboarding_step_back"
        case .completed: "onboarding_completed"
        }
    }

    /// The event's data as a flat dictionary for analytics systems, ready to send.
    ///
    /// Keys: `flow_id` when the flow has one; `step_id`, `step_index` and
    /// `step_count` for events about a step. Values are `String` or `Int`.
    /// To use other names, build them from `step` and `flowID` instead.
    public var parameters: [String: Any] {
        var result: [String: Any] = [:]

        if let flowID {
            result["flow_id"] = flowID
        }

        if let step {
            result["step_id"] = step.id
            result["step_index"] = step.index
            result["step_count"] = step.total
        }

        return result
    }

    /// The step the event is about; `nil` for events about the whole flow.
    public var step: OnboardingStepInfo? {
        switch kind {
        case .stepShown(let step), .stepContinued(let step), .stepSkipped(let step), .stepBack(let step):
            step
        case .started, .completed:
            nil
        }
    }
}
