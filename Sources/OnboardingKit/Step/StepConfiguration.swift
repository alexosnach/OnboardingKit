//
//  StepConfiguration.swift
//  OnboardingKit
//
//  Created by alex on 07/11/2026.
//

import Foundation

/// Describes which chrome elements are visible on a step.
///
/// Every property has a default value, so specify only what differs:
/// `StepConfiguration(isSkipButtonShown: true)`.
public struct StepConfiguration {
    /// Whether the back button is shown.
    ///
    /// Applies to any back button: the native one and the one drawn by
    /// ``BackButtonStyle`` (a custom style, or any style with `.pinned` chrome).
    /// Defaults to `true`. Has no effect on the first step of the flow.
    public var isBackButtonShown: Bool = true
    
    /// Whether the progress bar is shown.
    ///
    /// Defaults to `true`.
    public var isProgressBarShown: Bool = true
    
    /// Whether the Skip button is shown.
    ///
    /// It is on the trailing side of the navigation bar. On iPhone Duo the system
    /// may move it to the vertical toolbar if the app opts in with
    /// ``SwiftUI/View/skipButtonPrefersSideBar(_:)``.
    ///
    /// Skipping moves the flow exactly like Continue (on the last step it completes
    /// the onboarding); only analytics tells them apart (`stepSkipped`).
    /// Defaults to `false`: enable it only on steps the user may safely skip.
    public var isSkipButtonShown: Bool = false

    /// Creates a configuration; leave out the values that keep their defaults.
    public init(
        isBackButtonShown: Bool = true,
        isProgressBarShown: Bool = true,
        isSkipButtonShown: Bool = false
    ) {
        self.isBackButtonShown = isBackButtonShown
        self.isProgressBarShown = isProgressBarShown
        self.isSkipButtonShown = isSkipButtonShown
    }
}
