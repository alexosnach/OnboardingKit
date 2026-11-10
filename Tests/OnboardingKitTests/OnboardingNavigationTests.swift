//
//  OnboardingNavigationTests.swift
//  OnboardingKitTests
//

import SwiftUI
import Testing
@testable import OnboardingKit

private struct StubStep: OnboardingStep {
    let id: String
    var content: some View { EmptyView() }
}

private func makeCoordinator(stepsCount: Int, advancedBy moves: Int = 0) -> OnboardingCoordinator {
    let coordinator = OnboardingCoordinator(
        steps: (0..<stepsCount).map { StubStep(id: "step_\($0)") }
    )
    for _ in 0..<moves { coordinator.next() }
    return coordinator
}

@Suite("OnboardingNavigationPath")
struct OnboardingNavigationPathTests {

    // MARK: - Coordinator → NavigationStack

    @Test(arguments: [
        (0, []),
        (1, [1]),
        (2, [1, 2]),
        (4, [1, 2, 3, 4])
    ])
    func pathListsStepsAboveRoot(currentIndex: Int, expected: [Int]) {
        #expect(OnboardingNavigationPath.path(for: currentIndex) == expected)
    }

    /// The invariant the whole bridge relies on.
    @Test(arguments: 0...10)
    func pathLengthEqualsCurrentIndex(currentIndex: Int) {
        #expect(OnboardingNavigationPath.path(for: currentIndex).count == currentIndex)
    }

    // MARK: - NavigationStack → coordinator

    @Test func singleNativeBackMovesCoordinatorBackOnce() {
        let coordinator = makeCoordinator(stepsCount: 3, advancedBy: 2) // on step 2

        OnboardingNavigationPath.apply([1], to: coordinator)

        #expect(coordinator.currentIndex == 1)
    }

    /// Long-press on the back button can pop several steps at once.
    @Test func poppingToRootMovesCoordinatorToFirstStep() {
        let coordinator = makeCoordinator(stepsCount: 4, advancedBy: 3) // on step 3

        OnboardingNavigationPath.apply([], to: coordinator)

        #expect(coordinator.currentIndex == 0)
    }

    @Test func unchangedPathDoesNothing() {
        let coordinator = makeCoordinator(stepsCount: 3, advancedBy: 1)

        OnboardingNavigationPath.apply([1], to: coordinator)

        #expect(coordinator.currentIndex == 1)
    }

    /// Forward navigation must go through the coordinator, never through the path.
    @Test func longerPathDoesNotMoveCoordinatorForward() {
        let coordinator = makeCoordinator(stepsCount: 3)

        OnboardingNavigationPath.apply([1, 2], to: coordinator)

        #expect(coordinator.currentIndex == 0)
        #expect(coordinator.isCompleted == false)
    }

    /// Round trip: what the stack shows after going back matches the coordinator.
    @Test func pathStaysInSyncAfterGoingBack() {
        let coordinator = makeCoordinator(stepsCount: 3, advancedBy: 2)

        OnboardingNavigationPath.apply([1], to: coordinator)

        #expect(OnboardingNavigationPath.path(for: coordinator.currentIndex) == [1])
    }
}

@Suite("OnboardingNavigationAction")
struct OnboardingNavigationActionTests {

    @Test func callingActionRunsHandler() {
        var calls = 0
        let action = OnboardingNavigationAction { calls += 1 }

        action()
        action()

        #expect(calls == 2)
    }

    /// Outside `OnboardingView` the environment actions are harmless no-ops.
    @Test func defaultEnvironmentActionsDoNotCrash() {
        let environment = EnvironmentValues()

        environment.onboardingNext()
        environment.onboardingSkip()
    }

    @Test func actionsDriveCoordinatorLikeOnboardingViewDoes() {
        let coordinator = makeCoordinator(stepsCount: 3)
        let next = OnboardingNavigationAction { coordinator.next() }
        let skip = OnboardingNavigationAction { coordinator.skip() }

        next()
        skip()

        #expect(coordinator.currentIndex == 2)
    }
}
