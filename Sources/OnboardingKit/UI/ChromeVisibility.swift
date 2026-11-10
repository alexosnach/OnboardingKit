//
//  ChromeVisibility.swift
//  OnboardingKit
//

/// Which chrome elements are visible on a step.
///
/// The single place for the visibility rules, shared by both
/// ``OnboardingChromePlacement`` modes, so they can never disagree.
struct ChromeVisibility: Equatable {
    /// Whether the back button is visible.
    let isBackButtonVisible: Bool

    /// Whether the progress bar is visible.
    let isProgressBarVisible: Bool

    /// Whether the Skip button is visible.
    let isSkipButtonVisible: Bool

    /// The visibility for the step at `index` with the given configuration.
    ///
    /// The back button is never visible on the first step: there is nowhere to go back to.
    init(configuration: StepConfiguration, index: Int) {
        isBackButtonVisible = configuration.isBackButtonShown && index > 0
        isProgressBarVisible = configuration.isProgressBarShown
        isSkipButtonVisible = configuration.isSkipButtonShown
    }
}
