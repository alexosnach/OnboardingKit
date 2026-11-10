//
//  OnboardingCoordinatorTests.swift
//  OnboardingKitTests
//

import SwiftUI
import Testing
@testable import OnboardingKit

/// A minimal step used only in tests: the coordinator does not care about content.
private struct StubStep: OnboardingStep {
    let id: String
    var content: some View { EmptyView() }
}

private func makeCoordinator(stepsCount: Int) -> OnboardingCoordinator {
    let steps = (0..<stepsCount).map { StubStep(id: "step_\($0)") }
    return OnboardingCoordinator(steps: steps)
}

@Suite("OnboardingCoordinator")
struct OnboardingCoordinatorTests {

    // MARK: - Initial state

    @Test func startsOnFirstStepAndNotCompleted() {
        let coordinator = makeCoordinator(stepsCount: 3)

        #expect(coordinator.currentIndex == 0)
        #expect(coordinator.isCompleted == false)
    }

    @Test func emptyFlowIsCompletedImmediately() {
        let coordinator = makeCoordinator(stepsCount: 0)

        #expect(coordinator.isCompleted)
    }

    // MARK: - next()

    @Test func nextMovesToFollowingStep() {
        let coordinator = makeCoordinator(stepsCount: 3)

        coordinator.next()

        #expect(coordinator.currentIndex == 1)
        #expect(coordinator.isCompleted == false)
    }

    @Test func nextOnLastStepCompletesAndKeepsIndexInBounds() {
        let coordinator = makeCoordinator(stepsCount: 3)

        coordinator.next() // 1
        coordinator.next() // 2 (last)
        coordinator.next() // complete

        #expect(coordinator.isCompleted)
        #expect(coordinator.currentIndex == 2)
    }

    @Test func singleStepFlowCompletesOnFirstNext() {
        let coordinator = makeCoordinator(stepsCount: 1)

        coordinator.next()

        #expect(coordinator.isCompleted)
        #expect(coordinator.currentIndex == 0)
    }

    @Test func extraNextCallsNeverLeaveBounds() {
        let coordinator = makeCoordinator(stepsCount: 3)

        for _ in 0..<10 { coordinator.next() }

        #expect(coordinator.currentIndex == 2)
        #expect(coordinator.isCompleted)
    }

    @Test func nextOnEmptyFlowDoesNotCrash() {
        let coordinator = makeCoordinator(stepsCount: 0)

        coordinator.next()

        #expect(coordinator.currentIndex == 0)
        #expect(coordinator.isCompleted)
    }

    // MARK: - skip()

    /// skip() and next() must navigate identically: this guards against
    /// the old bug where skip() missed the end-of-flow check.
    @Test(arguments: [1, 2, 3, 5])
    func skipNavigatesExactlyLikeNext(stepsCount: Int) {
        let viaNext = makeCoordinator(stepsCount: stepsCount)
        let viaSkip = makeCoordinator(stepsCount: stepsCount)

        for _ in 0...stepsCount {
            viaNext.next()
            viaSkip.skip()

            #expect(viaSkip.currentIndex == viaNext.currentIndex)
            #expect(viaSkip.isCompleted == viaNext.isCompleted)
        }
    }

    @Test func skipOnLastStepCompletes() {
        let coordinator = makeCoordinator(stepsCount: 2)

        coordinator.skip() // 1 (last)
        coordinator.skip() // complete

        #expect(coordinator.isCompleted)
        #expect(coordinator.currentIndex == 1)
    }

    // MARK: - back()

    @Test func backOnFirstStepHasNoEffect() {
        let coordinator = makeCoordinator(stepsCount: 3)

        coordinator.back()

        #expect(coordinator.currentIndex == 0)
    }

    @Test func backReturnsToPreviousStep() {
        let coordinator = makeCoordinator(stepsCount: 3)

        coordinator.next() // 1
        coordinator.next() // 2
        coordinator.back() // 1

        #expect(coordinator.currentIndex == 1)
    }

    @Test func backOnEmptyFlowDoesNotGoNegative() {
        let coordinator = makeCoordinator(stepsCount: 0)

        coordinator.back()

        #expect(coordinator.currentIndex == 0)
    }
}
