//
//  SkipButtonStyleTests.swift
//  OnboardingKitTests
//

import SwiftUI
import Testing
@testable import OnboardingKit

/// A custom style that records the configuration it was given.
private final class RecordingSkipButtonStyle: SkipButtonStyle {
    private(set) var receivedConfiguration: SkipButtonConfiguration?

    func makeBody(configuration: SkipButtonConfiguration) -> some View {
        receivedConfiguration = configuration
        return EmptyView()
    }
}

private struct StubStep: OnboardingStep {
    let id: String
    var content: some View { EmptyView() }
}

@Suite("SkipButtonStyle")
struct SkipButtonStyleTests {

    /// The type-erased wrapper must hand the configuration to the real style unchanged.
    @Test func erasedStylePassesConfigurationToWrappedStyle() {
        let style = RecordingSkipButtonStyle()
        var skipped = 0

        _ = AnySkipButtonStyle(style).makeBody(configuration: .init(skip: { skipped += 1 }))
        style.receivedConfiguration?.skip()

        #expect(style.receivedConfiguration != nil)
        #expect(skipped == 1)
    }

    /// A custom style triggers skipping only through the provided action,
    /// and that action drives the coordinator exactly like `skip()`.
    @Test func styleActionSkipsCurrentStep() {
        let coordinator = OnboardingCoordinator(steps: [
            StubStep(id: "a"), StubStep(id: "b"), StubStep(id: "c")
        ])
        let style = RecordingSkipButtonStyle()

        _ = AnySkipButtonStyle(style).makeBody(configuration: .init(skip: { coordinator.skip() }))
        style.receivedConfiguration?.skip()

        #expect(coordinator.currentIndex == 1)
    }

    /// Outside a custom setup, the environment falls back to the system-looking default.
    @Test func defaultEnvironmentStyleIsUsable() {
        let environment = EnvironmentValues()

        _ = environment.skipButtonStyle.makeBody(configuration: .init(skip: {}))
    }

    @Test func automaticShorthandIsTheDefaultStyle() {
        let style: some SkipButtonStyle = .automatic

        #expect(style is DefaultSkipButtonStyle)
    }
}

@Suite("Skip button side bar")
struct SkipButtonSideBarTests {

    /// Opt-in: by default the system keeps the text-only Skip button in the top bar.
    @Test func sideBarIsOffByDefault() {
        #expect(EnvironmentValues().skipButtonPrefersSideBar == false)
    }
}
