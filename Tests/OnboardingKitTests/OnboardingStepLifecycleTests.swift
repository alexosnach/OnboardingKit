//
//  OnboardingStepLifecycleTests.swift
//  OnboardingKitTests
//
//  The coordinator tells steps adopting `OnboardingStepLifecycle` when they
//  become and stop being current: once per change, resign before become,
//  nothing on creation, and nothing after completion.
//

import SwiftUI
import Testing
@testable import OnboardingKit

/// The calls of every spy step, in the order they came.
private final class Journal {
    var entries: [String] = []
}

/// A step that writes its lifecycle calls to a shared journal.
private struct SpyStep: OnboardingStep, OnboardingStepLifecycle {
    let id: String
    let journal: Journal
    var content: some View { Text(id) }

    func didBecomeCurrent() { journal.entries.append("become:\(id)") }
    func didResignCurrent() { journal.entries.append("resign:\(id)") }
}

/// A step without lifecycle hooks.
private struct PlainStep: OnboardingStep {
    let id: String
    var content: some View { Text(id) }
}

@MainActor
struct OnboardingStepLifecycleTests {
    private let journal = Journal()

    private func coordinator(_ ids: [String]) -> OnboardingCoordinator {
        OnboardingCoordinator(steps: ids.map { SpyStep(id: $0, journal: journal) })
    }

    // MARK: - start()

    @Test func creatingTheCoordinatorCallsNothing() {
        _ = coordinator(["welcome", "name"])
        #expect(journal.entries.isEmpty)
    }

    @Test func startMakesTheFirstStepCurrent() {
        coordinator(["welcome", "name"]).start()
        #expect(journal.entries == ["become:welcome"])
    }

    @Test func startCountsOnlyOnce() {
        let flow = coordinator(["welcome", "name"])
        flow.start()
        flow.start()
        #expect(journal.entries == ["become:welcome"])
    }

    @Test func startOnEmptyFlowDoesNothing() {
        OnboardingCoordinator(steps: []).start()
        #expect(journal.entries.isEmpty)
    }

    // MARK: - Moving between steps

    @Test func nextResignsTheOldStepBeforeTheNewOneBecomesCurrent() {
        let flow = coordinator(["welcome", "name"])
        flow.start()
        journal.entries.removeAll()

        flow.next()

        #expect(journal.entries == ["resign:welcome", "become:name"])
    }

    @Test func skipMakesTheSameCallsAsNext() {
        let flow = coordinator(["welcome", "name"])
        flow.start()
        journal.entries.removeAll()

        flow.skip()

        #expect(journal.entries == ["resign:welcome", "become:name"])
    }

    @Test func backMakesTheReverseCalls() {
        let flow = coordinator(["welcome", "name"])
        flow.start()
        flow.next()
        journal.entries.removeAll()

        flow.back()

        #expect(journal.entries == ["resign:name", "become:welcome"])
    }

    @Test func backOnFirstStepCallsNothing() {
        let flow = coordinator(["welcome", "name"])
        flow.start()
        journal.entries.removeAll()

        flow.back()

        #expect(journal.entries.isEmpty)
    }

    @Test func wholeFlowGivesEveryStepOneBecomeAndOneResign() {
        let flow = coordinator(["welcome", "name", "age"])
        flow.start()
        flow.next()
        flow.next()
        flow.next()

        #expect(journal.entries == [
            "become:welcome",
            "resign:welcome", "become:name",
            "resign:name", "become:age",
            "resign:age",
        ])
    }

    /// Flows of 0 to 3 steps, straight through: each step becomes current
    /// once and resigns once, in order.
    @Test(arguments: 0...3)
    func straightThroughGivesEveryStepOnePair(count: Int) {
        let ids = (0..<count).map { "step\($0)" }
        let flow = coordinator(ids)
        flow.start()
        for _ in 0..<count { flow.next() }

        #expect(journal.entries == ids.flatMap { ["become:\($0)", "resign:\($0)"] })
        #expect(flow.isCompleted)
    }

    // MARK: - Completion

    @Test func completingResignsTheLastStepWithoutBecome() {
        let flow = coordinator(["welcome"])
        flow.start()
        journal.entries.removeAll()

        flow.next()

        #expect(flow.isCompleted)
        #expect(journal.entries == ["resign:welcome"])
    }

    @Test func actionsAfterCompletionCallNothing() {
        let flow = coordinator(["welcome", "name"])
        flow.start()
        flow.next()
        flow.next()
        journal.entries.removeAll()

        flow.next()
        flow.skip()
        flow.back()
        flow.start()

        #expect(journal.entries.isEmpty)
        #expect(flow.currentIndex == 1)
    }

    // MARK: - Steps without hooks

    @Test func stepsWithoutHooksAreSkippedQuietly() {
        let flow = OnboardingCoordinator(steps: [
            SpyStep(id: "welcome", journal: journal),
            PlainStep(id: "plain"),
            SpyStep(id: "age", journal: journal),
        ])
        flow.start()
        flow.next()
        flow.next()
        flow.back()

        #expect(journal.entries == [
            "become:welcome",
            "resign:welcome",
            "become:age",
            "resign:age",
        ])
    }
}
