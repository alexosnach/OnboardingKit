//
//  ReadmeExamplesTests.swift
//  OnboardingKitTests
//

import SwiftUI
import Testing
import OnboardingKit  // not @testable: the README examples must build with the public API alone

// MARK: - The code from README.md

private struct WelcomeStep: OnboardingStep {
    let id = "welcome"
    let configuration = StepConfiguration(isBackButtonShown: false)

    var content: some View { WelcomeView() }
}

private struct WelcomeView: View {
    @Environment(\.onboardingNext) private var next

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome!").font(.largeTitle.bold())
            Button("Continue") { next() }
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct NameStep: OnboardingStep {
    let id = "name"
    let configuration = StepConfiguration(isSkipButtonShown: true)

    var content: some View { NameView() }
}

private struct NameView: View {
    @Environment(\.onboardingSkip) private var skip
    @Environment(\.onboardingStepInfo) private var stepInfo
    @Environment(\.onboardingFlowID) private var flowID

    var body: some View {
        Button("Skip") { skip() }
    }
}

private struct AppFlowProvider: OnboardingFlowProvider {
    func makeFlow() async -> OnboardingFlow {
        OnboardingFlow(steps: [WelcomeStep(), NameStep()], flowID: "main_v1")
    }
}

private struct DotsProgressBarStyle: ProgressBarStyle {
    func makeBody(configuration: ProgressBarConfiguration) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<configuration.total, id: \.self) { index in
                Circle()
                    .fill(index <= configuration.currentIndex ? Color.accentColor : .secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

private struct TextSkipButtonStyle: SkipButtonStyle {
    func makeBody(configuration: SkipButtonConfiguration) -> some View {
        Button("Not now", action: configuration.skip)
    }
}

private struct TextBackButtonStyle: BackButtonStyle {
    func makeBody(configuration: BackButtonConfiguration) -> some View {
        Button("Back", action: configuration.back)
    }
}

private struct BrandLoadingStyle: OnboardingLoadingStyle {
    func makeBody(configuration: OnboardingLoadingConfiguration) -> some View {
        Image(systemName: "sparkles")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private final class RecordingAnalytics: OnboardingAnalytics {
    var names: [String] = []

    func track(_ event: OnboardingAnalyticsEvent) {
        names.append(event.name)
        _ = event.parameters
        _ = event.kind
    }
}

extension NameStep: OnboardingStepLifecycle {
    func didBecomeCurrent() {}
    func didResignCurrent() {}
}

// MARK: - Checks

@MainActor
@Suite("README examples")
struct ReadmeExamplesTests {

    @Test func quickStartAndCustomizationBuild() {
        let view = OnboardingView(provider: AppFlowProvider(), analytics: RecordingAnalytics()) {}
            .progressBarStyle(.segmented)
            .progressBarStyle(.line(filledColor: .purple, emptyColor: .purple.opacity(0.2)))
            .progressBarStyle(DotsProgressBarStyle())
            .skipButtonStyle(TextSkipButtonStyle())
            .backButtonStyle(TextBackButtonStyle())
            .skipButtonPrefersSideBar()
            .onboardingChrome(.pinned)
            .onboardingLoadingStyle(BrandLoadingStyle())
        _ = view
    }

    @Test func providerReturnsTheStepsInOrder() async {
        let flow = await AppFlowProvider().makeFlow()
        #expect(flow.steps.map(\.id) == ["welcome", "name"])
        #expect(flow.flowID == "main_v1")
    }

    @Test func publicInitializersAreAvailable() {
        let configuration = ProgressBarConfiguration(currentIndex: 1, total: 4)
        #expect(configuration.completedCount == 2)  // step 2 of 4 fills two segments
        #expect(OnboardingStepInfo(id: "name", index: 1, total: 2).total == 2)
        #expect(StepConfiguration().isSkipButtonShown == false)
        NoOpOnboardingAnalytics().track(OnboardingAnalyticsEvent(kind: .started, flowID: nil))
    }
}
