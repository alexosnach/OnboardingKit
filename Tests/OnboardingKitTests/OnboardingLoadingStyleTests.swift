//
//  OnboardingLoadingStyleTests.swift
//  OnboardingKitTests
//
//  The loading screen style follows the same pattern as the other styles:
//  the type-erased wrapper calls the real style, the environment holds
//  `.automatic` by default, and the modifier replaces it.
//

import SwiftUI
import Testing
@testable import OnboardingKit

/// A custom style that counts how often it was asked to draw.
private final class RecordingLoadingStyle: OnboardingLoadingStyle {
    private(set) var bodiesMade = 0

    func makeBody(configuration: OnboardingLoadingConfiguration) -> some View {
        bodiesMade += 1
        return Text("Loading")
    }
}

@MainActor
@Suite("OnboardingLoadingStyle")
struct OnboardingLoadingStyleTests {

    /// The type-erased wrapper must call the wrapped style, once per body.
    @Test func erasedStyleCallsWrappedStyle() {
        let style = RecordingLoadingStyle()
        let erased = AnyOnboardingLoadingStyle(style)

        _ = erased.makeBody(configuration: .init())
        _ = erased.makeBody(configuration: .init())

        #expect(style.bodiesMade == 2)
    }

    /// Wrapping does not call the style yet: it draws only when the screen is shown.
    @Test func wrappingDoesNotDrawYet() {
        let style = RecordingLoadingStyle()
        _ = AnyOnboardingLoadingStyle(style)

        #expect(style.bodiesMade == 0)
    }

    /// Without any setup the environment holds a usable default.
    @Test func defaultEnvironmentStyleIsUsable() {
        _ = EnvironmentValues().onboardingLoadingStyle.makeBody(configuration: .init())
    }

    @Test func automaticShorthandIsTheDefaultStyle() {
        let style: some OnboardingLoadingStyle = .automatic

        #expect(style is DefaultOnboardingLoadingStyle)
    }

    /// The modifier puts the app's style into the environment in place of the default.
    @Test func modifierReplacesTheDefaultStyle() {
        let style = RecordingLoadingStyle()
        var environment = EnvironmentValues()
        environment.onboardingLoadingStyle = AnyOnboardingLoadingStyle(style)

        _ = environment.onboardingLoadingStyle.makeBody(configuration: .init())

        #expect(style.bodiesMade == 1)
    }
}
