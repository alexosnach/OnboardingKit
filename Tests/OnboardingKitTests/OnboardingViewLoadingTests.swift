//
//  OnboardingViewLoadingTests.swift
//  OnboardingKitTests
//
//  `OnboardingView` hosted in a real window: it shows the loading style while
//  the provider waits, asks the provider once, starts the flow with the given
//  analytics and flow id, and calls `onComplete` exactly once — also for an
//  empty flow, which it never tries to show.
//

import SwiftUI
import UIKit
import Testing
@testable import OnboardingKit

// MARK: - Test doubles

private final class RecordingAnalytics: OnboardingAnalytics {
    private(set) var events: [OnboardingAnalyticsEvent] = []
    func track(_ event: OnboardingAnalyticsEvent) { events.append(event) }
}

/// A provider that answers after `delay` and counts its calls.
private final class StubProvider: OnboardingFlowProvider {
    let flow: OnboardingFlow
    let delay: Duration
    private(set) var calls = 0

    init(_ flow: OnboardingFlow, delay: Duration = .zero) {
        self.flow = flow
        self.delay = delay
    }

    func makeFlow() async -> OnboardingFlow {
        calls += 1
        if delay > .zero { try? await Task.sleep(for: delay) }
        return flow
    }
}

private final class LoadingCounter {
    var bodiesMade = 0
}

/// A loading style that counts how often it is drawn.
private struct CountingLoadingStyle: OnboardingLoadingStyle {
    let counter: LoadingCounter
    func makeBody(configuration: OnboardingLoadingConfiguration) -> some View {
        counter.bodiesMade += 1
        return Text("Loading")
    }
}

private struct PlainStep: OnboardingStep {
    let id: String
    var content: some View { Text(id) }
}

/// A step that moves on by itself as soon as it is shown, like a step
/// whose view model finished right away.
private struct AutoContinueStep: OnboardingStep {
    let id: String
    var content: some View { AutoContinueView() }
}

private struct AutoContinueView: View {
    @Environment(\.onboardingNext) private var next
    var body: some View { Text("auto").onAppear { next() } }
}

// MARK: - Tests

@MainActor
@Suite("OnboardingView loading", .serialized)
struct OnboardingViewLoadingTests {

    @Test func showsLoadingStyleWhileProviderWaits() async throws {
        let provider = StubProvider(OnboardingFlow(steps: [PlainStep(id: "a")], flowID: nil), delay: .seconds(2))
        let counter = LoadingCounter()
        let analytics = RecordingAnalytics()

        try await host(OnboardingView(provider: provider, analytics: analytics) {}
            .onboardingLoadingStyle(CountingLoadingStyle(counter: counter))) {
            try await waitUntil { provider.calls == 1 }
            #expect(counter.bodiesMade > 0)
            #expect(analytics.events.isEmpty) // no flow yet, nothing started
        }
    }

    @Test func startsTheLoadedFlowWithItsIDAndAnalytics() async throws {
        let provider = StubProvider(OnboardingFlow(steps: [PlainStep(id: "a"), PlainStep(id: "b")], flowID: "variant_b"))
        let analytics = RecordingAnalytics()

        try await host(OnboardingView(provider: provider, analytics: analytics) {}) {
            try await waitUntil { analytics.events.count >= 2 }
            #expect(analytics.events.map(\.kind) == [
                .started, .stepShown(OnboardingStepInfo(id: "a", index: 0, total: 2)),
            ])
            #expect(analytics.events.allSatisfy { $0.flowID == "variant_b" })
        }
    }

    @Test func asksTheProviderOnlyOnce() async throws {
        let provider = StubProvider(OnboardingFlow(steps: [PlainStep(id: "a")], flowID: nil))
        let analytics = RecordingAnalytics()

        try await host(OnboardingView(provider: provider, analytics: analytics) {}) {
            try await waitUntil { !analytics.events.isEmpty }
            try await Task.sleep(for: .milliseconds(300)) // let any extra re-render happen
            #expect(provider.calls == 1)
        }
    }

    @Test func callsOnCompleteOnceWhenTheLastStepIsPassed() async throws {
        let provider = StubProvider(OnboardingFlow(steps: [AutoContinueStep(id: "only")], flowID: nil))
        let analytics = RecordingAnalytics()
        var completions = 0

        try await host(OnboardingView(provider: provider, analytics: analytics) { completions += 1 }) {
            try await waitUntil { completions > 0 }
            try await Task.sleep(for: .milliseconds(300))
            #expect(completions == 1)
            #expect(analytics.events.last?.kind == .completed)
        }
    }

    /// The contract forbids it, but a broken provider must not crash the app.
    @Test func emptyFlowCompletesAtOnceWithoutShowingSteps() async throws {
        let provider = StubProvider(OnboardingFlow(steps: [], flowID: nil))
        let analytics = RecordingAnalytics()
        var completions = 0

        try await host(OnboardingView(provider: provider, analytics: analytics) { completions += 1 }) {
            try await waitUntil { completions > 0 }
            try await Task.sleep(for: .milliseconds(300))
            #expect(completions == 1)
            #expect(analytics.events.isEmpty)
        }
    }

    /// The user leaves before the provider answers (the app closed the cover):
    /// the late answer starts nothing and completes nothing.
    @Test func lateAnswerAfterTheViewIsGoneIsDropped() async throws {
        let provider = StubProvider(OnboardingFlow(steps: [PlainStep(id: "a")], flowID: nil), delay: .milliseconds(500))
        let analytics = RecordingAnalytics()
        var completions = 0

        try await host(OnboardingView(provider: provider, analytics: analytics) { completions += 1 }) {
            try await waitUntil { provider.calls == 1 }
        }
        try await Task.sleep(for: .milliseconds(800))
        #expect(analytics.events.isEmpty)
        #expect(completions == 0)
    }

    // MARK: - Hosting

    /// Shows `view` in a window for the duration of `body`, then removes it.
    private func host(_ view: some View, _ body: () async throws -> Void) async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        window.rootViewController = UIHostingController(rootView: view)
        window.isHidden = false
        try await body()
        window.rootViewController = nil
        window.isHidden = true
    }

    private func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            guard ContinuousClock.now < deadline else {
                Issue.record("Condition not met in time")
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}
