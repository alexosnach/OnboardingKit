//
//  OnboardingFlowProvider.swift
//  OnboardingKit
//
//  Created by alex on 09/11/2026.
//

import Foundation

/// Decides which flow the onboarding shows.
///
/// The app implements it: a fixed list of steps, or a list built from a remote
/// configuration (for example, a variant of an A/B test). The onboarding does
/// not know where the flow comes from and runs no experiments itself.
///
/// A remote implementation maps the identifiers it receives to the app's step
/// types; what to do with an unknown identifier is its decision.
///
/// The provider is also where steps get what they need: it creates them, so it
/// passes services and shared models to their initializers. To share answers
/// between steps, give them one model object and read it in `onComplete`:
///
/// ```swift
/// struct StaticFlowProvider: OnboardingFlowProvider {
///     let answers: OnboardingAnswers  // an @Observable class owned by the app
///
///     func makeFlow() async -> OnboardingFlow {
///         OnboardingFlow(steps: [
///             WelcomeStep(),
///             NameStep(answers: answers),
///             NotificationsStep(),
///         ], flowID: nil)
///     }
/// }
/// ```
///
/// A remote provider waits for its configuration with a timeout and falls back
/// to a built-in flow:
///
/// ```swift
/// struct RemoteFlowProvider: OnboardingFlowProvider {
///     let config: RemoteConfig
///     let answers: OnboardingAnswers
///
///     func makeFlow() async -> OnboardingFlow {
///         guard let variant = try? await config.onboardingVariant(timeout: .seconds(2)) else {
///             return defaultFlow
///         }
///         let steps = variant.stepIDs.compactMap(makeStep)  // drops unknown ids
///         return steps.isEmpty ? defaultFlow : OnboardingFlow(steps: steps, flowID: variant.name)
///     }
///
///     private func makeStep(id: String) -> (any OnboardingStep)? {
///         switch id {
///         case "welcome": WelcomeStep()
///         case "name": NameStep(answers: answers)
///         default: nil
///         }
///     }
///
///     private var defaultFlow: OnboardingFlow { ... }
/// }
/// ```
///
/// While `makeFlow()` runs, ``OnboardingView`` shows its loading screen
/// (``SwiftUI/View/onboardingLoadingStyle(_:)``).
public protocol OnboardingFlowProvider {
    /// Returns the flow to show.
    ///
    /// Every implementation must keep these promises:
    /// - It always returns a flow and never fails. If the flow depends on the
    ///   network, the implementation waits up to its own timeout and, on a
    ///   timeout or an error, returns its default flow.
    /// - The flow has at least one step.
    /// - The result stays valid for the whole pass: a newer configuration that
    ///   arrives later applies to the next showing of the onboarding, not to this one.
    func makeFlow() async -> OnboardingFlow
}
