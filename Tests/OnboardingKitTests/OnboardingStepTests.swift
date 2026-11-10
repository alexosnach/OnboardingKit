//
//  OnboardingStepTests.swift
//  OnboardingKitTests
//

import SwiftUI
import Testing
@testable import OnboardingKit

/// A step that relies on the protocol's default configuration.
private struct DefaultConfigurationStep: OnboardingStep {
    let id = "default"
    var content: some View { EmptyView() }
}

/// A step that overrides the configuration.
private struct CustomConfigurationStep: OnboardingStep {
    let id = "custom"
    let configuration = StepConfiguration(isSkipButtonShown: true)
    var content: some View { EmptyView() }
}

@Suite("StepConfiguration")
struct StepConfigurationTests {

    /// Locks the documented defaults: changing one of them is a breaking change.
    @Test func defaultValuesMatchDocumentation() {
        let configuration = StepConfiguration()

        #expect(configuration.isBackButtonShown == true)
        #expect(configuration.isProgressBarShown == true)
        #expect(configuration.isSkipButtonShown == false)
    }

    @Test func overridingOneValueKeepsOtherDefaults() {
        let configuration = StepConfiguration(isSkipButtonShown: true)

        #expect(configuration.isSkipButtonShown == true)
        #expect(configuration.isBackButtonShown == true)
        #expect(configuration.isProgressBarShown == true)
    }
}

@Suite("OnboardingStep")
struct OnboardingStepTests {

    @Test func stepWithoutConfigurationUsesDefaults() {
        let configuration = DefaultConfigurationStep().configuration

        #expect(configuration.isBackButtonShown == true)
        #expect(configuration.isProgressBarShown == true)
        #expect(configuration.isSkipButtonShown == false)
    }

    /// Checks that a stored property wins over the protocol extension default,
    /// including when the step is accessed through `any OnboardingStep`
    /// (exactly how the coordinator stores steps).
    @Test func customConfigurationOverridesDefaultEvenThroughExistential() {
        let step: any OnboardingStep = CustomConfigurationStep()

        #expect(step.configuration.isSkipButtonShown == true)
    }
}
