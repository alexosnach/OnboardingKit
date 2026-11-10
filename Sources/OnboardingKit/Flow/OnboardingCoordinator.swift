//
//  OnboardingCoordinator.swift
//  OnboardingKit
//
//  Created by alex on 07/11/2026.
//

import Foundation
import Observation

/// Decides which step of the onboarding flow is shown.
///
/// The coordinator holds the navigation state and changes it in response to
/// `next()`, `skip()` and `back()`. It contains no UI: views observe its state
/// and render the current step.
///
/// On `start()`, on every change of the current step and on completion it
/// calls the steps that adopt ``OnboardingStepLifecycle`` and reports the funnel
/// to ``OnboardingAnalytics`` (see ``OnboardingEvent`` for the events and their order).
///
/// The state can be read from outside but is changed only by the coordinator itself.
@Observable
final class OnboardingCoordinator {
    /// The steps of the flow, in display order.
    let steps: [any OnboardingStep]
    
    /// Identifies the flow in analytics, for example a variant of an A/B test.
    let flowID: String?

    /// Receives the flow's events.
    private let analytics: OnboardingAnalytics

    /// Whether the onboarding has finished.
    ///
    /// Becomes `true` when moving forward from the last step,
    /// or immediately on creation if `steps` is empty.
    ///
    /// Completion is final: once `true`, it never becomes `false` again,
    /// even if `back()` is called afterwards. Show the app's main screen when it is set.
    private(set) var isCompleted: Bool = false 

    /// The index of the current step in `steps`.
    ///
    /// Always a valid index while `steps` is not empty.
    /// Stays on the last step after the onboarding is completed.
    ///
    /// Every change tells the steps: the old one resigns, then the new one becomes current;
    /// then analytics gets `stepShown` for the new step.
    private(set) var currentIndex: Int = 0 {
        didSet {
            lifecycle(of: oldValue)?.didResignCurrent()
            lifecycle(of: currentIndex)?.didBecomeCurrent()
            track(.stepShown(currentStepInfo))
        }
    }

    /// Whether `start()` was called. Not part of the UI state.
    @ObservationIgnored private var isStarted = false

    /// Creates a coordinator for the given steps.
    ///
    /// An empty flow has nothing to show, so it is completed immediately.
    init(steps: [any OnboardingStep], flowID: String? = nil, analytics: OnboardingAnalytics = NoOpOnboardingAnalytics()) {
        self.steps = steps
        self.flowID = flowID
        self.analytics = analytics

        if steps.isEmpty {
            isCompleted = true
        }
    }

    /// Moves to the next step, or completes the onboarding on the last step.
    ///
    /// Reported as `stepContinued` for the step the user leaves.
    func next() {
        moveForward(reportedAs: OnboardingEvent.stepContinued)
    }

    /// Skips the current step.
    ///
    /// Navigates exactly like `next()`; the difference is only in meaning:
    /// it is reported as `stepSkipped` instead of `stepContinued`.
    func skip() {
        moveForward(reportedAs: OnboardingEvent.stepSkipped)
    }

    /// Returns to the previous step.
    ///
    /// Has no effect on the first step or after completion.
    /// Reported as `stepBack` for the step the user leaves.
    func back() {
        guard !isCompleted, currentIndex > 0 else { return }
        track(.stepBack(currentStepInfo))
        currentIndex -= 1
    }

    /// The single place that decides how the flow moves forward.
    private func moveForward(reportedAs action: (OnboardingStepInfo) -> OnboardingEvent) {
        guard !steps.isEmpty, !isCompleted else { return }
        track(action(currentStepInfo))

        if steps.count - 1 > currentIndex {
            currentIndex += 1
        } else {
            isCompleted = true
            lifecycle(of: currentIndex)?.didResignCurrent()
            track(.completed)
        }
    }

    /// Starts the onboarding on the first step: the step becomes current, and
    /// analytics gets `started`, then `stepShown` for it.
    ///
    /// `started` is reported only here, only once and only on the first step.
    /// Later calls do nothing, and so do calls after completion (an empty flow
    /// reports nothing).
    ///
    /// - Important: Call it only on the first step, when the onboarding is shown.
    ///   ``OnboardingFlowView`` does it in `onAppear`, once ``OnboardingView`` has loaded
    ///   the flow, so the app does not need to.
    func start() {
        guard !isStarted, !isCompleted else { return }
        isStarted = true
        lifecycle(of: currentIndex)?.didBecomeCurrent()
        track(.started)
        track(.stepShown(currentStepInfo))
    }

    /// The step at `index`, if it wants lifecycle calls.
    private func lifecycle(of index: Int) -> OnboardingStepLifecycle? {
        steps[index] as? OnboardingStepLifecycle
    }
    
    /// The step at `index` with its place in the flow, as analytics reports it.
    ///
    /// - Precondition: `index` is a valid index of `steps`.
    func stepInfo(at index: Int) -> OnboardingStepInfo {
        OnboardingStepInfo(id: steps[index].id, index: index, total: steps.count)
    }

    private var currentStepInfo: OnboardingStepInfo { stepInfo(at: currentIndex) }

    private func track(_ kind: OnboardingEvent) {
        analytics.track(OnboardingAnalyticsEvent(kind: kind, flowID: flowID))
    }
}
