//
//  ChromeVisibilityTests.swift
//  OnboardingKitTests
//

import Testing
@testable import OnboardingKit

/// The visibility rules shared by `.perStep` and `.pinned`.
@Suite("ChromeVisibility")
struct ChromeVisibilityTests {

    @Test func defaultConfigurationShowsBackAndProgressButNotSkip() {
        let visibility = ChromeVisibility(configuration: StepConfiguration(), index: 1)

        #expect(visibility.isBackButtonVisible)
        #expect(visibility.isProgressBarVisible)
        #expect(visibility.isSkipButtonVisible == false)
    }

    /// Nowhere to go back to on the first step, whatever the configuration says.
    @Test func backIsNeverVisibleOnFirstStep() {
        let visibility = ChromeVisibility(
            configuration: StepConfiguration(isBackButtonShown: true),
            index: 0
        )

        #expect(visibility.isBackButtonVisible == false)
    }

    @Test func stepCanHideBack() {
        let visibility = ChromeVisibility(
            configuration: StepConfiguration(isBackButtonShown: false),
            index: 2
        )

        #expect(visibility.isBackButtonVisible == false)
    }

    @Test func stepCanShowSkip() {
        let visibility = ChromeVisibility(
            configuration: StepConfiguration(isSkipButtonShown: true),
            index: 0
        )

        #expect(visibility.isSkipButtonVisible)
    }

    @Test func stepCanHideProgress() {
        let visibility = ChromeVisibility(
            configuration: StepConfiguration(isProgressBarShown: false),
            index: 1
        )

        #expect(visibility.isProgressBarVisible == false)
    }
}
