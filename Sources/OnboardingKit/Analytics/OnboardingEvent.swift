//
//  OnboardingEvent.swift
//  OnboardingKit
//
//  Created by alex on 09/11/2026.
//

import Foundation

/// What happened in the onboarding flow.
///
/// Every move between steps reports what the user did, then where they got to:
/// `stepContinued` for the step left, then `stepShown` for the step reached.
/// Actions that change nothing, such as back on the first step or anything
/// after completion, report nothing.
///
/// A full pass of a two-step flow reports:
/// `started`, `stepShown(0)`, `stepContinued(0)`, `stepShown(1)`, `stepContinued(1)`, `completed`.
///
/// There is no event for leaving the onboarding unfinished: the app can be
/// closed without notice. Count it as `started` without `completed`.
public enum OnboardingEvent: Equatable {
    /// The onboarding began. It is the first event of the flow and comes exactly
    /// once, when the first step is first shown, right before its `stepShown`.
    /// It is never reported again: not on a return to the first step, not anywhere else.
    case started
    /// The step became the current one: on start, or after any move to it.
    case stepShown(OnboardingStepInfo)
    /// The user moved forward from the step with ``SwiftUI/EnvironmentValues/onboardingNext``.
    case stepContinued(OnboardingStepInfo)
    /// The user moved forward from the step with the Skip button or ``SwiftUI/EnvironmentValues/onboardingSkip``.
    case stepSkipped(OnboardingStepInfo)
    /// The user went back from the step, with the back button or a swipe.
    /// Going back several steps at once (the native back button's menu) goes one
    /// step at a time: each step on the way reports `stepBack`, and each step in
    /// between also reports `stepShown`.
    case stepBack(OnboardingStepInfo)
    /// The user moved forward from the last step; comes after its
    /// `stepContinued` or `stepSkipped`, and is the last event of the flow.
    case completed
}
