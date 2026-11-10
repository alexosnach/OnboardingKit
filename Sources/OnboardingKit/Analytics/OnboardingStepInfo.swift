//
//  OnboardingStepInfo.swift
//  OnboardingKit
//
//  Created by alex on 09/11/2026.
//

import Foundation

/// The step an event is about, with its place in the flow.
///
/// The step's content reads the same value from `@Environment(\.onboardingStepInfo)`,
/// so its own events can carry the same `step_id` as the funnel.
public struct OnboardingStepInfo: Equatable {
    /// The step's stable ``OnboardingStep/id``.
    public let id: String

    /// The step's position in the flow, starting at 0.
    public let index: Int

    /// The number of steps in the flow.
    public let total: Int

    /// Creates the position of a step, for tests of an analytics implementation.
    public init(id: String, index: Int, total: Int) {
        self.id = id
        self.index = index
        self.total = total
    }
}
