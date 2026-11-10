//
//  BackButtonStyleTests.swift
//  OnboardingKitTests
//

import SwiftUI
import Testing
@testable import OnboardingKit

/// A custom style that records the configuration it was given.
private final class RecordingBackButtonStyle: BackButtonStyle {
    private(set) var receivedConfiguration: BackButtonConfiguration?

    func makeBody(configuration: BackButtonConfiguration) -> some View {
        receivedConfiguration = configuration
        return EmptyView()
    }
}

private struct StubStep: OnboardingStep {
    let id: String
    var content: some View { EmptyView() }
}

@Suite("BackButtonStyle")
struct BackButtonStyleTests {

    /// The default keeps the native button: swipe-back and RTL keep working.
    @Test func defaultStyleKeepsNativeButton() {
        #expect(AnyBackButtonStyle(.automatic).usesNativeButton)
    }

    @Test func environmentDefaultKeepsNativeButton() {
        #expect(EnvironmentValues().backButtonStyle.usesNativeButton)
    }

    /// Any other style replaces the native button.
    @Test func customStyleReplacesNativeButton() {
        #expect(AnyBackButtonStyle(RecordingBackButtonStyle()).usesNativeButton == false)
    }

    @Test func erasedStylePassesConfigurationToWrappedStyle() {
        let style = RecordingBackButtonStyle()
        var calls = 0

        _ = AnyBackButtonStyle(style).makeBody(configuration: .init(back: { calls += 1 }))
        style.receivedConfiguration?.back()

        #expect(calls == 1)
    }

    /// A custom button goes back only through the provided action,
    /// and that action drives the coordinator exactly like `back()`.
    @Test func styleActionReturnsToPreviousStep() {
        let coordinator = OnboardingCoordinator(steps: [
            StubStep(id: "a"), StubStep(id: "b"), StubStep(id: "c")
        ])
        coordinator.next()
        coordinator.next()
        let style = RecordingBackButtonStyle()

        _ = AnyBackButtonStyle(style).makeBody(configuration: .init(back: { coordinator.back() }))
        style.receivedConfiguration?.back()

        #expect(coordinator.currentIndex == 1)
    }

    @Test func automaticShorthandIsTheDefaultStyle() {
        let style: some BackButtonStyle = .automatic

        #expect(style is DefaultBackButtonStyle)
    }
}
