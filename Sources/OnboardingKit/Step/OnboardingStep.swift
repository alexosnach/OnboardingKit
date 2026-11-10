//
//  OnboardingStep.swift
//  OnboardingKit
//
//  Created by alex on 07/11/2026.
//

import SwiftUI

/// A single screen of the onboarding flow.
///
/// A step describes *what* to show: its identity, content and chrome configuration.
/// It does not decide *where* the flow goes next: the order of steps comes from
/// ``OnboardingFlowProvider``, and the onboarding moves through them.
///
/// The step is created by the provider, so dependencies (services, a model
/// shared between steps) come through its initializer; see ``OnboardingFlowProvider``.
///
/// ## Implementing a step
///
/// ```swift
/// struct WelcomeStep: OnboardingStep {
///     let id = "welcome"
///
///     var content: some View {
///         WelcomeView()
///     }
/// }
/// ```
///
/// Do not declare `typealias Content`: it is inferred from `content`.
///
/// ## Moving to the next step
///
/// The step decides *when* it is done and tells the flow through the
/// ``SwiftUI/EnvironmentValues/onboardingNext`` environment action (``SwiftUI/EnvironmentValues/onboardingSkip`` works the same way):
///
/// - When the user decides (a button), call the action from the view:
///
///   ```swift
///   struct WelcomeView: View {
///       @Environment(\.onboardingNext) private var next
///
///       var body: some View {
///           Button("Continue") { next() }
///       }
///   }
///   ```
///
/// - When a view model decides (a server response, a timer), pass the action
///   to it as a closure, so the view model stays independent of SwiftUI:
///
///   ```swift
///   .onAppear { viewModel.onFinished = { next() } }
///   ```
///
/// The actions work only inside ``OnboardingView``; elsewhere they do nothing.
///
/// There is no action to go back or to leave the onboarding early: going back
/// is the back button's job, and the onboarding ends only by moving forward
/// from the last step. A step that ends the flow early, for example "I already
/// have an account", is placed last, or the app stops showing ``OnboardingView``.
///
/// ## Writing the content
///
/// The content is responsible for its own padding and scrolling. Wrap long
/// content in a `ScrollView`: the onboarding does not scroll it. The navigation bar, progress
/// bar, Skip and back buttons are drawn around the content, never inside it.
///
/// ## Sending the step's own analytics events
///
/// The onboarding reports only the funnel (see ``OnboardingEvent``). Events inside
/// the step, such as the answer to a permission request, the step sends to the
/// app's analytics itself. To tie them to the funnel, read the step's place from
/// the environment and send the same `flow_id` and `step_id`:
///
/// ```swift
/// @Environment(\.onboardingStepInfo) private var step
/// @Environment(\.onboardingFlowID) private var flowID
///
/// // In the view model, after the permission request:
/// analytics.send("notifications_permission", parameters: [
///     "flow_id": flowID ?? "", "step_id": step?.id ?? "", "granted": granted,
/// ])
/// ```
///
/// Keep `id` when only the step's look or text changes between A/B variants:
/// the variant is told apart by `flow_id`.
public protocol OnboardingStep {
    /// The type of view displayed by the step.
    associatedtype Content: View
    
    /// A stable identifier of the step.
    ///
    /// Must be unique within a flow and must not change between app versions,
    /// because analytics reports it: the coordinator sends it as
    /// ``OnboardingStepInfo/id`` (`step_id` in ``OnboardingAnalyticsEvent/parameters``).
    /// Navigation does not use it: steps are told apart by their index.
    /// Do not use generated values such as `UUID()`.
    var id: String { get }
    
    /// The chrome elements visible on this step.
    ///
    /// Defaults to `StepConfiguration()` when not implemented.
    var configuration: StepConfiguration { get }
    
    /// The view displayed inside the onboarding chrome.
    ///
    /// Provide only the screen content. The navigation bar, progress bar
    /// and Skip button are rendered by the onboarding container.
    ///
    /// Content that scrolls under the navigation bar gets a soft edge, without
    /// a line (see ``StepScrollEdge``). To change it for this step, set
    /// `scrollEdgeEffectStyle(_:for:)` or `scrollEdgeEffectHidden(_:for:)` inside the content.
    @ViewBuilder var content: Content { get }
}

extension OnboardingStep {
    public var configuration: StepConfiguration { .init() }
}
