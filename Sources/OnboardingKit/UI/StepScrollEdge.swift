//
//  StepScrollEdge.swift
//  OnboardingKit
//

import SwiftUI

/// How a step's scrolling content looks under the onboarding navigation bar.
///
/// When content scrolls under the bar, the system blurs it so the back button,
/// progress bar and Skip stay readable (the scroll edge effect). The onboarding
/// owns the bar, so it decides how that edge looks for every step: `.soft`, a
/// blur that fades out, with no line. Left to the system, a wide screen such as
/// an unfolded iPhone Duo gets `.hard`, a band with a line across the screen.
///
/// A step can choose differently for itself: a modifier set inside the step is
/// closer to its scroll view, so it wins.
///
/// ```swift
/// ScrollView { … }
///     .scrollEdgeEffectStyle(.hard, for: .top)   // or .scrollEdgeEffectHidden(for: .top)
/// ```
enum StepScrollEdge {
    /// The style of the top edge, under the navigation bar.
    static let topStyle: ScrollEdgeEffectStyle = .soft
}

extension View {
    /// Applies the onboarding's top scroll edge style to a step's content.
    func stepScrollEdge() -> some View {
        scrollEdgeEffectStyle(StepScrollEdge.topStyle, for: .top)
    }
}
