//
//  OnboardingAnalyticsTests.swift
//  OnboardingKitTests
//
//  The coordinator reports the funnel: started, every step shown, what the
//  user did on it, and completed. Commands that change nothing report nothing.
//

import SwiftUI
import Testing
@testable import OnboardingKit

/// Records every event it receives.
private final class SpyAnalytics: OnboardingAnalytics {
    var events: [OnboardingAnalyticsEvent] = []
    var kinds: [OnboardingEvent] { events.map(\.kind) }

    func track(_ event: OnboardingAnalyticsEvent) { events.append(event) }
}

private struct PlainStep: OnboardingStep {
    let id: String
    var content: some View { Text(id) }
}

@MainActor
struct OnboardingAnalyticsTests {
    private let analytics = SpyAnalytics()

    private func coordinator(_ ids: [String], flowID: String? = nil) -> OnboardingCoordinator {
        OnboardingCoordinator(steps: ids.map(PlainStep.init), flowID: flowID, analytics: analytics)
    }

    private func info(_ id: String, _ index: Int, of total: Int) -> OnboardingStepInfo {
        OnboardingStepInfo(id: id, index: index, total: total)
    }

    // MARK: - The funnel

    @Test func creatingTheCoordinatorReportsNothing() {
        _ = coordinator(["welcome", "name"])
        #expect(analytics.events.isEmpty)
    }

    @Test func startReportsStartedAndTheFirstStep() {
        coordinator(["welcome", "name"]).start()
        #expect(analytics.kinds == [.started, .stepShown(info("welcome", 0, of: 2))])
    }

    @Test func startReportsOnlyOnce() {
        let flow = coordinator(["welcome", "name"])
        flow.start()
        flow.start()
        #expect(analytics.kinds.count == 2)
    }

    @Test func wholeFlowReportsTheFunnelInOrder() {
        let flow = coordinator(["welcome", "name", "age"])
        flow.start()
        flow.next()
        flow.skip()
        flow.back()
        flow.next()
        flow.next()

        #expect(analytics.kinds == [
            .started,
            .stepShown(info("welcome", 0, of: 3)),
            .stepContinued(info("welcome", 0, of: 3)),
            .stepShown(info("name", 1, of: 3)),
            .stepSkipped(info("name", 1, of: 3)),
            .stepShown(info("age", 2, of: 3)),
            .stepBack(info("age", 2, of: 3)),
            .stepShown(info("name", 1, of: 3)),
            .stepContinued(info("name", 1, of: 3)),
            .stepShown(info("age", 2, of: 3)),
            .stepContinued(info("age", 2, of: 3)),
            .completed,
        ])
    }

    // MARK: - Flows of 0 to 3 steps

    /// Going straight through: started, then each step shown and continued, then completed.
    @Test(arguments: 0...3)
    func straightThroughReportsEveryStep(count: Int) {
        let ids = (0..<count).map { "step\($0)" }
        let flow = coordinator(ids)
        flow.start()
        for _ in 0..<count { flow.next() }

        var expected: [OnboardingEvent] = []
        if count > 0 {
            expected.append(.started)
            for index in 0..<count {
                let step = info(ids[index], index, of: count)
                expected += [.stepShown(step), .stepContinued(step)]
            }
            expected.append(.completed)
        }
        #expect(analytics.kinds == expected)
        #expect(flow.isCompleted)
    }

    /// Back from every step to the first, then forward again: one back and one
    /// shown per move, never below the first step.
    @Test(arguments: 1...3)
    func backToTheFirstStepAndForwardAgain(count: Int) {
        let ids = (0..<count).map { "step\($0)" }
        let flow = coordinator(ids)
        flow.start()
        for _ in 0..<(count - 1) { flow.next() }
        analytics.events.removeAll()

        for _ in 0..<count { flow.back() }  // one more than possible

        var expected: [OnboardingEvent] = []
        for index in stride(from: count - 1, to: 0, by: -1) {
            expected += [.stepBack(info(ids[index], index, of: count)), .stepShown(info(ids[index - 1], index - 1, of: count))]
        }
        #expect(analytics.kinds == expected)
        #expect(flow.currentIndex == 0)
        #expect(!flow.isCompleted)
    }

    /// Skip on every step ends the flow like next, only reported as skipped.
    @Test(arguments: 1...3)
    func skippingEveryStepCompletes(count: Int) {
        let flow = coordinator((0..<count).map { "step\($0)" })
        flow.start()
        for _ in 0..<count { flow.skip() }

        let skipped = analytics.kinds.filter { if case .stepSkipped = $0 { true } else { false } }
        #expect(skipped.count == count)
        #expect(analytics.kinds.last == .completed)
        #expect(flow.isCompleted)
    }

    // MARK: - Commands that change nothing

    @Test func backOnFirstStepReportsNothing() {
        let flow = coordinator(["welcome", "name"])
        flow.start()
        analytics.events.removeAll()

        flow.back()

        #expect(analytics.events.isEmpty)
    }

    @Test func actionsAfterCompletionReportNothing() {
        let flow = coordinator(["welcome"])
        flow.start()
        flow.next()
        analytics.events.removeAll()

        flow.next()
        flow.skip()
        flow.back()
        flow.start()

        #expect(analytics.events.isEmpty)
    }

    @Test func emptyFlowReportsNothing() {
        let flow = coordinator([])
        flow.start()
        flow.next()
        #expect(analytics.events.isEmpty)
    }

    // MARK: - Flow id

    @Test func everyEventCarriesTheFlowID() {
        let flow = coordinator(["welcome"], flowID: "variant_b")
        flow.start()
        flow.next()

        #expect(analytics.events.count == 4)
        #expect(analytics.events.allSatisfy { $0.flowID == "variant_b" })
    }

    @Test func flowIDIsOptional() {
        coordinator(["welcome"]).start()
        #expect(analytics.events.allSatisfy { $0.flowID == nil })
    }

    @Test func coordinatorWithoutAnalyticsStillWorks() {
        let flow = OnboardingCoordinator(steps: [PlainStep(id: "welcome")])
        flow.start()
        flow.next()
        #expect(flow.isCompleted)
    }
    /// Steps read `onboardingStepInfo` from the environment to tie their own events
    /// to the funnel, so it must be the same value the coordinator reports.
    @Test func stepInfoMatchesWhatAnalyticsReports() {
        let flow = coordinator(["welcome", "name", "age"])
        flow.start()
        flow.next()
        #expect(flow.stepInfo(at: 1) == info("name", 1, of: 3))
        #expect(analytics.kinds.last == .stepShown(flow.stepInfo(at: 1)))
    }
}

/// The flat form that analytics systems receive.
struct OnboardingAnalyticsEventTests {
    private let step = OnboardingStepInfo(id: "name", index: 1, total: 6)

    @Test(arguments: [
        (OnboardingEvent.started, "onboarding_started"),
        (.stepShown(OnboardingStepInfo(id: "a", index: 0, total: 1)), "onboarding_step_shown"),
        (.stepContinued(OnboardingStepInfo(id: "a", index: 0, total: 1)), "onboarding_step_continued"),
        (.stepSkipped(OnboardingStepInfo(id: "a", index: 0, total: 1)), "onboarding_step_skipped"),
        (.stepBack(OnboardingStepInfo(id: "a", index: 0, total: 1)), "onboarding_step_back"),
        (.completed, "onboarding_completed"),
    ])
    func eachEventHasItsName(kind: OnboardingEvent, name: String) {
        #expect(OnboardingAnalyticsEvent(kind: kind, flowID: nil).name == name)
    }

    @Test func stepEventHasFlowAndStepParameters() {
        let parameters = OnboardingAnalyticsEvent(kind: .stepShown(step), flowID: "variant_b").parameters

        #expect(parameters.count == 4)
        #expect(parameters["flow_id"] as? String == "variant_b")
        #expect(parameters["step_id"] as? String == "name")
        #expect(parameters["step_index"] as? Int == 1)
        #expect(parameters["step_count"] as? Int == 6)
    }

    @Test func flowEventHasNoStepParameters() {
        let parameters = OnboardingAnalyticsEvent(kind: .completed, flowID: "variant_b").parameters
        #expect(parameters.keys.sorted() == ["flow_id"])
    }

    @Test func eventWithoutFlowIDHasNoFlowParameter() {
        let parameters = OnboardingAnalyticsEvent(kind: .stepBack(step), flowID: nil).parameters
        #expect(parameters["flow_id"] == nil)
        #expect(parameters.count == 3)
    }

}
