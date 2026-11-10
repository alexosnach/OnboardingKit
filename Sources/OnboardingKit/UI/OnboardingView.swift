//
//  OnboardingView.swift
//  OnboardingKit
//
//  Created by alex on 09/11/2026.
//

import SwiftUI

/// The onboarding: loads its flow, shows it and reports when it is done.
///
/// ```swift
/// @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted = false
///
/// if isOnboardingCompleted {
///     MainView()
/// } else {
///     OnboardingView(provider: StaticFlowProvider(), analytics: AppAnalytics()) {
///         isOnboardingCompleted = true
///     }
/// }
/// ```
///
/// When it appears it asks `provider` for the flow once and shows the loading
/// screen (``SwiftUI/View/onboardingLoadingStyle(_:)``) until the flow comes. How long that
/// may take is the provider's decision. Then it creates the flow's
/// ``OnboardingCoordinator`` with `analytics` and shows the steps (see
/// ``OnboardingFlowView`` for the navigation bar, progress bar, Skip and back).
///
/// ## Customizing the look
///
/// Every part the onboarding draws itself has a style; set it on this view.
/// Each modifier changes one part, and anything not set keeps its default:
///
/// | Modifier | What it changes | Default |
/// |---|---|---|
/// | ``SwiftUI/View/onboardingLoadingStyle(_:)`` | The screen shown while the provider loads the flow | `.automatic`: an activity indicator |
/// | ``SwiftUI/View/progressBarStyle(_:)`` | The progress bar in the navigation bar | `.line`; also built in: `.segmented` |
/// | ``SwiftUI/View/skipButtonStyle(_:)`` | The Skip button | `.automatic`: a system button titled "Skip" |
/// | ``SwiftUI/View/backButtonStyle(_:)`` | The back button | `.automatic`: the native back button in `.perStep`, a chevron in `.pinned` |
/// | ``SwiftUI/View/onboardingChrome(_:)`` | Whether each step has its own navigation bar, or one bar stays in place | `.perStep` |
/// | ``SwiftUI/View/skipButtonPrefersSideBar(_:)`` | Whether Skip may move to the vertical bar on iPhone Duo | off |
///
/// ```swift
/// OnboardingView(provider: provider) { ... }
///     .onboardingLoadingStyle(BrandLoadingStyle())
///     .progressBarStyle(.segmented)
///     .skipButtonStyle(NotNowSkipButtonStyle())
/// ```
///
/// A custom style is a type that adopts the style's protocol
/// (``OnboardingLoadingStyle``, ``ProgressBarStyle``, ``SkipButtonStyle``,
/// ``BackButtonStyle``); each protocol's documentation has an example. Colors
/// for light and dark appearance: `Color(light:dark:)`.
///
/// Which items a step shows (back, progress bar, Skip) is not a style: each
/// step sets it in its ``StepConfiguration``. The step's content is the step's own view.
///
/// The onboarding saves nothing. Whether it was completed is the app's to
/// remember; on the next launch the app decides whether to show it at all,
/// and the provider is not called when it is not shown.
///
/// Present it outside of any other `NavigationStack` — as the app root or in a
/// `fullScreenCover` — because it owns its own stack and SwiftUI does not
/// support nested stacks.
///
/// ## Texts and localization
///
/// The built-in Skip button and the back button's accessibility label say
/// "Skip" and "Back", and the default loading screen says "Loading...", all in
/// English. For other wording or languages, set a custom ``SwiftUI/View/skipButtonStyle(_:)``, ``SwiftUI/View/backButtonStyle(_:)``
/// or ``SwiftUI/View/onboardingLoadingStyle(_:)``.
public struct OnboardingView: View {
    @Environment(\.onboardingLoadingStyle) private var loadingStyle

    private let provider: any OnboardingFlowProvider
    private let analytics: OnboardingAnalytics
    private let onComplete: () -> Void

    /// The loaded flow; `nil` while the provider has not answered yet.
    @State private var coordinator: OnboardingCoordinator?

    /// Creates the onboarding.
    ///
    /// - Parameters:
    ///   - provider: Decides which flow to show; asked once, when the view appears.
    ///   - analytics: Receives the flow's events. Defaults to none.
    ///   - onComplete: Called once, when the user moves forward from the last step.
    ///     Also called, without showing any step, if the provider returns an empty
    ///     flow (which breaks its contract). Remember the completion here and stop
    ///     showing the onboarding.
    public init(
        provider: any OnboardingFlowProvider,
        analytics: OnboardingAnalytics = NoOpOnboardingAnalytics(),
        onComplete: @escaping () -> Void
    ) {
        self.provider = provider
        self.analytics = analytics
        self.onComplete = onComplete
    }

    public var body: some View {
        Group {
            if let coordinator {
                OnboardingFlowView(coordinator: coordinator)
                    .onChange(of: coordinator.isCompleted) { _, isCompleted in
                        if isCompleted { onComplete() }
                    }
            } else {
                loadingStyle.makeBody(configuration: .init())
            }
        }
        // `.task` is cancelled when the view goes away, so a late answer is dropped.
        .task { await load() }
    }

    private func load() async {
        guard coordinator == nil else { return }
        let flow = await provider.makeFlow()
        guard !Task.isCancelled else { return }

        let loaded = OnboardingCoordinator(steps: flow.steps, flowID: flow.flowID, analytics: analytics)
        // An empty flow is completed at once; `onChange` would never see it change,
        // and `OnboardingFlowView` cannot show it.
        if loaded.isCompleted {
            onComplete()
        } else {
            coordinator = loaded
        }
    }
}
