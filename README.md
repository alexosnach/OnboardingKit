# OnboardingKit

A SwiftUI framework for step-by-step onboarding flows on iOS. You write the
screens; OnboardingKit handles the navigation, the back button, the progress
bar, Skip, analytics events and the loading state.

- **Any screen is a step.** A step is a small type that returns a SwiftUI view.
- **Native navigation bar.** The system back button, glass buttons, RTL and iPhone Duo work out of the box.
- **Progress bar.** A line or a segment per step, or your own style. Colors are configurable.
- **Skip.** On the trailing side, shown only on the steps you allow.
- **Per-step chrome.** Every step decides whether it shows the back button, the progress bar and Skip.
- **Flow providers.** The order of steps can come from code or from remote config, with a loading screen while it loads.
- **Analytics funnel.** Start, step shown, continued, skipped, back and completed, sent to your analytics.
- **Lifecycle hooks.** A step can know when it becomes current and when it leaves.

## Requirements

- iOS 26+
- Xcode 26+ (Swift 6.2 tools)

## Installation

### Xcode

1. **File → Add Package Dependencies…**
2. Enter `https://github.com/alexosnach/OnboardingKit`
3. Choose **Up to Next Major Version** from `0.1.1` and add the `OnboardingKit` library to your app target.

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/alexosnach/OnboardingKit", from: "0.1.1"),
],
targets: [
    .target(name: "MyApp", dependencies: ["OnboardingKit"]),
]
```

## Quick start

### 1. Write the steps

A step has an `id` (used in analytics), an optional `configuration` and the
`content` to show. The step moves on by calling the `onboardingNext` action from
the environment.

```swift
import SwiftUI
import OnboardingKit

struct WelcomeStep: OnboardingStep {
    let id = "welcome"
    let configuration = StepConfiguration(isBackButtonShown: false)

    var content: some View { WelcomeView() }
}

struct WelcomeView: View {
    @Environment(\.onboardingNext) private var next

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome!").font(.largeTitle.bold())
            Button("Continue") { next() }
                .buttonStyle(.borderedProminent)
        }
    }
}

struct NameStep: OnboardingStep {
    let id = "name"
    let configuration = StepConfiguration(isSkipButtonShown: true)

    var content: some View { NameView() }
}
```

`StepConfiguration` defaults: back button shown, progress bar shown, Skip hidden.
Set only what differs.

### 2. Describe the flow

A provider returns the steps in the order they are shown. `flowID` names the
flow in analytics, for example an A/B test variant.

```swift
struct AppFlowProvider: OnboardingFlowProvider {
    func makeFlow() async -> OnboardingFlow {
        OnboardingFlow(steps: [WelcomeStep(), NameStep()], flowID: "main_v1")
    }
}
```

### 3. Show the onboarding

```swift
@main
struct MyApp: App {
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            if isOnboardingCompleted {
                ContentView()
            } else {
                OnboardingView(provider: AppFlowProvider()) {
                    isOnboardingCompleted = true
                }
            }
        }
    }
}
```

`onComplete` is called once, when the user moves forward from the last step.
OnboardingKit stores nothing: remembering that the onboarding is done is up to
the app.

Present `OnboardingView` at the root or in a `fullScreenCover`, not inside
another `NavigationStack`: it owns its own stack.

## Customization

All styles are set with view modifiers on `OnboardingView` (or any view above it).

### Progress bar

```swift
OnboardingView(provider: AppFlowProvider()) { ... }
    .progressBarStyle(.segmented)                                       // one segment per step
    .progressBarStyle(.line(filledColor: .purple, emptyColor: .purple.opacity(0.2)))
```

Your own style:

```swift
struct DotsProgressBarStyle: ProgressBarStyle {
    func makeBody(configuration: ProgressBarConfiguration) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<configuration.total, id: \.self) { index in
                Circle()
                    .fill(index <= configuration.currentIndex ? Color.accentColor : .secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

.progressBarStyle(DotsProgressBarStyle())
```

`ProgressBarConfiguration` gives `currentIndex`, `total`, `completedCount` and `fraction`.

### Skip and back buttons

```swift
struct TextSkipButtonStyle: SkipButtonStyle {
    func makeBody(configuration: SkipButtonConfiguration) -> some View {
        Button("Not now", action: configuration.skip)
    }
}

.skipButtonStyle(TextSkipButtonStyle())
.backButtonStyle(MyBackButtonStyle())   // conforms to BackButtonStyle, calls configuration.back
.skipButtonPrefersSideBar()             // iPhone Duo: let the system move Skip to the vertical bar
```

With the default back button style, the native system button is kept, with the
swipe-back gesture and the history menu.

### Chrome placement

```swift
.onboardingChrome(.perStep)   // default: each step has its own navigation bar and slides with it
.onboardingChrome(.pinned)    // one bar for the whole flow; only the content slides
```

### Loading screen

Shown while `makeFlow()` runs.

```swift
struct BrandLoadingStyle: OnboardingLoadingStyle {
    func makeBody(configuration: OnboardingLoadingConfiguration) -> some View {
        Image("Logo")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

.onboardingLoadingStyle(BrandLoadingStyle())
```

## Analytics

Implement `OnboardingAnalytics` and pass it to `OnboardingView`. Every event has
a ready `name` and `parameters` for your analytics SDK.

```swift
struct AppAnalytics: OnboardingAnalytics {
    func track(_ event: OnboardingAnalyticsEvent) {
        Analytics.log(event.name, parameters: event.parameters)
    }
}

OnboardingView(provider: AppFlowProvider(), analytics: AppAnalytics()) { ... }
```

| Event | `name` |
|---|---|
| `.started` | `onboarding_started` |
| `.stepShown` | `onboarding_step_shown` |
| `.stepContinued` | `onboarding_step_continued` |
| `.stepSkipped` | `onboarding_step_skipped` |
| `.stepBack` | `onboarding_step_back` |
| `.completed` | `onboarding_completed` |

Step events carry the step `id`, `index` and `total`; every event carries the
`flowID`. Use `event.kind` to switch over the events yourself.

## Remote flows

`makeFlow()` is `async`, so the flow can come from remote config. The provider
must always return a flow: wait with your own timeout and fall back to a
built-in flow.

```swift
struct RemoteFlowProvider: OnboardingFlowProvider {
    func makeFlow() async -> OnboardingFlow {
        guard let variant = try? await config.onboardingVariant(timeout: .seconds(2)) else {
            return defaultFlow
        }
        let steps = variant.stepIDs.compactMap(makeStep)   // drop unknown ids
        return steps.isEmpty ? defaultFlow : OnboardingFlow(steps: steps, flowID: variant.name)
    }
}
```

## Step lifecycle

Adopt `OnboardingStepLifecycle` when a step needs to react to becoming current,
for example to start an animation or request a permission.

```swift
extension NotificationsStep: OnboardingStepLifecycle {
    func didBecomeCurrent() { /* the step is on screen */ }
    func didResignCurrent() { /* the user moved on or went back */ }
}
```

## Environment values for steps

| Value | What it is |
|---|---|
| `\.onboardingNext` | Moves to the next step (completes the flow on the last one). |
| `\.onboardingSkip` | Skips the step; moves like Next, reported as `stepSkipped`. |
| `\.onboardingStepInfo` | The step's `id`, `index` and `total`. |
| `\.onboardingFlowID` | The `flowID` of the current flow. |

## Localization

The built-in texts ("Skip", "Back", "Loading...") are in English. For other
wording or languages, provide your own Skip, back button or loading style.

## License

MIT. See [LICENSE](LICENSE).
