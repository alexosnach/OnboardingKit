//
//  DefaultBackButtonStyle.swift
//  OnboardingKit
//

import SwiftUI

/// The default back button: the native back button of `NavigationStack`.
///
/// With this style and `.perStep` chrome, the onboarding keeps the system button,
/// so the swipe-back gesture, the long-press history menu and right-to-left
/// mirroring work as usual.
///
/// With `.perStep`, the onboarding does not call `makeBody` for this style: it
/// leaves the native button in place. With `.pinned`, where there is no native
/// button, `makeBody` draws a chevron with no frame of its own, so its look, size
/// and tap target come from the navigation bar (on iOS 26 and later, a glass button).
///
/// Use the shorthand `.automatic` to apply it.
public struct DefaultBackButtonStyle: BackButtonStyle {
    public init() {}

    public func makeBody(configuration: BackButtonConfiguration) -> some View {
        Button(action: configuration.back) {
            Image(systemName: "chevron.backward")
                .font(.title3.weight(.medium))
                // No own frame: the navigation bar gives it its look, size and tap target.
        }
        .accessibilityLabel(Text("Back", bundle: .module))
    }
}

extension BackButtonStyle where Self == DefaultBackButtonStyle {
    /// The default back button: the native one with `.perStep`, a chevron with `.pinned`.
    public static var automatic: Self { .init() }
}

#Preview {
    let style: some BackButtonStyle = .automatic

    style
        .makeBody(configuration: .init(back: {}))
        .padding()
}
