//
//  OnboardingUsageScenarioTests.swift
//  OnboardingKitTests
//
//  Scenarios from how apps actually use the framework: mixed step types,
//  duplicate ids, round trips, calls after completion and observation.
//

import Observation
import SwiftUI
import Testing
@testable import OnboardingKit

private struct TextStep: OnboardingStep {
    let id: String
    var content: some View { Text(id) }
}

/// A step with its own configuration and stored state, like a real app step.
private struct FormStep: OnboardingStep {
    let id: String
    let configuration: StepConfiguration
    var placeholder = "Name"
    var content: some View { TextField(placeholder, text: .constant("")) }
}

/// A step implemented as a class, which the protocol does not forbid.
private final class ClassStep: OnboardingStep {
    let id = "class"
    var content: some View { EmptyView() }
}

/// Runs `action` and reports whether observers of `read` were notified.
private func notifies(
    reading read: @escaping () -> Void,
    when action: () -> Void
) -> Bool {
    var changed = false
    withObservationTracking(read) { changed = true }
    action()
    return changed
}

@Suite("Usage scenarios")
struct OnboardingUsageScenarioTests {

    // MARK: - Steps

    @Test func mixedStepTypesKeepTheirOwnConfiguration() {
        let coordinator = OnboardingCoordinator(steps: [
            TextStep(id: "welcome"),
            FormStep(id: "name", configuration: .init(isSkipButtonShown: true)),
            ClassStep(),
            FormStep(id: "age", configuration: .init(isBackButtonShown: false, isProgressBarShown: false))
        ])
        let visited = (0..<coordinator.steps.count).map { _ in
            defer { coordinator.next() }
            return (
                coordinator.steps[coordinator.currentIndex].id,
                ChromeVisibility(
                    configuration: coordinator.steps[coordinator.currentIndex].configuration,
                    index: coordinator.currentIndex
                )
            )
        }

        #expect(visited.map(\.0) == ["welcome", "name", "class", "age"])
        #expect(visited[0].1.isBackButtonVisible == false)
        #expect(visited[1].1.isSkipButtonVisible)
        #expect(visited[2].1 == .init(configuration: .init(), index: 2))
        #expect(visited[3].1.isBackButtonVisible == false)
        #expect(visited[3].1.isProgressBarVisible == false)
        #expect(coordinator.isCompleted)
    }

    /// Ids are not used for navigation, so duplicates (a common copy-paste
    /// mistake) do not break the flow.
    @Test func duplicateIdsStillNavigateByPosition() {
        let coordinator = OnboardingCoordinator(steps: [
            TextStep(id: "same"), TextStep(id: "same"), TextStep(id: "same")
        ])
        coordinator.next()
        coordinator.next()
        coordinator.back()

        #expect(coordinator.currentIndex == 1)
        #expect(coordinator.isCompleted == false)
    }

    @Test func stepsKeepTheOrderTheyWereGiven() {
        let ids = (0..<20).map { "step_\($0)" }
        let coordinator = OnboardingCoordinator(steps: ids.map(TextStep.init))
        #expect(coordinator.steps.map(\.id) == ids)
    }

    // MARK: - Navigation sequences

    @Test func fullRoundTripReturnsToStart() {
        let coordinator = OnboardingCoordinator(steps: (0..<5).map { TextStep(id: "\($0)") })
        for _ in 0..<4 { coordinator.next() }
        for _ in 0..<4 { coordinator.back() }

        #expect(coordinator.currentIndex == 0)
        #expect(coordinator.isCompleted == false)
    }

    @Test func extraBackCallsNeverGoBelowFirstStep() {
        let coordinator = OnboardingCoordinator(steps: (0..<3).map { TextStep(id: "\($0)") })
        coordinator.next()
        for _ in 0..<10 { coordinator.back() }
        #expect(coordinator.currentIndex == 0)
    }

    /// A user going back and forth, skipping some steps, finishes exactly once.
    @Test func mixedNextSkipBackSequence() {
        let coordinator = OnboardingCoordinator(steps: (0..<4).map { TextStep(id: "\($0)") })
        coordinator.next()   // 1
        coordinator.skip()   // 2
        coordinator.back()   // 1
        coordinator.skip()   // 2
        coordinator.next()   // 3
        #expect(coordinator.currentIndex == 3)
        #expect(coordinator.isCompleted == false)

        coordinator.skip()   // complete
        #expect(coordinator.isCompleted)
    }

    /// Double taps on Continue after the last step must not move or "uncomplete" the flow.
    @Test func callsAfterCompletionKeepItCompleted() {
        let coordinator = OnboardingCoordinator(steps: (0..<2).map { TextStep(id: "\($0)") })
        coordinator.next()
        coordinator.next()
        coordinator.next()
        coordinator.skip()

        #expect(coordinator.isCompleted)
        #expect(coordinator.currentIndex == 1)
    }

    /// Completion is final: going back after it moves the index but does not
    /// reopen the flow. The app shows its main screen once `isCompleted` is true.
    @Test func backAfterCompletionDoesNotReopenTheFlow() {
        let coordinator = OnboardingCoordinator(steps: (0..<2).map { TextStep(id: "\($0)") })
        coordinator.next()
        coordinator.next()
        coordinator.back()

        #expect(coordinator.isCompleted)
    }

    @Test func emptyFlowIgnoresEveryAction() {
        let coordinator = OnboardingCoordinator(steps: [])
        coordinator.next()
        coordinator.skip()
        coordinator.back()

        #expect(coordinator.currentIndex == 0)
        #expect(coordinator.isCompleted)
        #expect(OnboardingNavigationPath.path(for: coordinator.currentIndex).isEmpty)
    }

    // MARK: - Navigation stack sync

    /// The path stays equal to the coordinator through any sequence of actions.
    @Test func pathMatchesCoordinatorAfterEveryAction() {
        let coordinator = OnboardingCoordinator(steps: (0..<4).map { TextStep(id: "\($0)") })
        let actions: [() -> Void] = [
            coordinator.next, coordinator.next, coordinator.back,
            coordinator.skip, coordinator.next, coordinator.back, coordinator.back
        ]
        for action in actions {
            action()
            #expect(OnboardingNavigationPath.path(for: coordinator.currentIndex).count == coordinator.currentIndex)
        }
    }

    /// A long-press on the native back button can pop several steps at once.
    @Test func popToMiddleStepFromHistoryMenu() {
        let coordinator = OnboardingCoordinator(steps: (0..<5).map { TextStep(id: "\($0)") })
        for _ in 0..<4 { coordinator.next() }

        OnboardingNavigationPath.apply([1, 2], to: coordinator)

        #expect(coordinator.currentIndex == 2)
    }

    // MARK: - Observation (what makes SwiftUI refresh)

    @Test func nextNotifiesObserversOfCurrentIndex() {
        let coordinator = OnboardingCoordinator(steps: (0..<3).map { TextStep(id: "\($0)") })
        #expect(notifies(reading: { _ = coordinator.currentIndex }, when: coordinator.next))
    }

    @Test func backNotifiesObserversOfCurrentIndex() {
        let coordinator = OnboardingCoordinator(steps: (0..<3).map { TextStep(id: "\($0)") })
        coordinator.next()
        #expect(notifies(reading: { _ = coordinator.currentIndex }, when: coordinator.back))
    }

    /// The app swaps onboarding for its main screen by observing `isCompleted`.
    @Test func finishingNotifiesObserversOfCompletion() {
        let coordinator = OnboardingCoordinator(steps: [TextStep(id: "only")])
        #expect(notifies(reading: { _ = coordinator.isCompleted }, when: coordinator.next))
    }

    /// Ignored actions do not cause pointless redraws.
    @Test func backOnFirstStepDoesNotNotify() {
        let coordinator = OnboardingCoordinator(steps: (0..<3).map { TextStep(id: "\($0)") })
        #expect(notifies(reading: { _ = coordinator.currentIndex }, when: coordinator.back) == false)
    }

    // MARK: - Environment defaults

    @Test func chromeIsPerStepByDefault() {
        #expect(EnvironmentValues().onboardingChromePlacement == .perStep)
    }

    @Test func environmentValuesCanBeOverridden() {
        var environment = EnvironmentValues()
        environment.onboardingChromePlacement = .pinned
        environment.skipButtonPrefersSideBar = true
        var calls = 0
        environment.onboardingNext = OnboardingNavigationAction { calls += 1 }

        environment.onboardingNext()

        #expect(environment.onboardingChromePlacement == .pinned)
        #expect(environment.skipButtonPrefersSideBar)
        #expect(calls == 1)
    }
}
