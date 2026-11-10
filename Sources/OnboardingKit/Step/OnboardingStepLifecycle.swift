//
//  OnboardingStepLifecycle.swift
//  OnboardingKit
//
//  Created by alex on 09/11/2026.
//

import Foundation

/// A step that wants to know when it becomes and stops being the current one.
///
/// Adopt it on a step that needs it; a step without it gets no calls.
///
/// A step is a value, created once by the provider, so the hooks cannot change
/// the step itself. Forward them to an object the step holds, such as its
/// view model, and give the same object to the content:
///
/// ```swift
/// struct PaywallStep: OnboardingStep, OnboardingStepLifecycle {
///     let id = "paywall"
///     let model: PaywallModel  // a class, shared with the view
///
///     var content: some View { PaywallView(model: model) }
///
///     func didBecomeCurrent() { model.startTimer() }
///     func didResignCurrent() { model.stopTimer() }
/// }
/// ```
///
/// For work tied to the view being on screen, use `onAppear` and `task` in the
/// content instead: the hooks follow the flow, not the screen.
///
/// The calls follow the flow's state, not the screen: for Continue, Skip and a
/// back button they come before the transition animation, so a step that became
/// current may not be visible yet; a swipe back changes the state only when the
/// gesture ends.
/// They come on the main thread, in order: the previous step resigns, then the
/// next one becomes current. A cancelled swipe
/// back changes nothing, so it makes no calls. Going back several steps at once
/// (the back button's menu in `.perStep` with the native back button) moves one
/// step at a time, so each step in between becomes current and then resigns at once.
public protocol OnboardingStepLifecycle {
    /// The step became the current one: the onboarding started on it,
    /// or the user moved to it.
    func didBecomeCurrent()

    /// The step stopped being the current one: the user moved away from it,
    /// or the onboarding completed on it.
    func didResignCurrent()
}
