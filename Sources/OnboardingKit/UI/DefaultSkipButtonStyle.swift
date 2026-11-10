//
//  DefaultSkipButtonStyle.swift
//  OnboardingKit
//

import SwiftUI

/// The default Skip button: a standard system button in the navigation bar.
///
/// Uses no custom colors or fonts, so it looks like any native toolbar button
/// and follows the app's tint.
///
/// The title is the localization key `"Skip"`, looked up in the app's main bundle:
/// translate it in the app's String Catalog. For a different title, use a custom style.
///
/// On devices with a vertical toolbar (such as iPhone Duo), the button stays in the
/// top bar by default. When the app opts in with
/// ``SwiftUI/View/skipButtonPrefersSideBar(_:)``, the system may move it to the vertical bar. When
/// the app opted in and the screen has a vertical toolbar, the button shows the
/// `chevron.forward` symbol instead of the title, because a word does not fit the
/// narrow bar. VoiceOver still reads "Skip".
///
/// Use the shorthand `.automatic` to apply it.
public struct DefaultSkipButtonStyle: SkipButtonStyle {
    public init() {}

    public func makeBody(configuration: SkipButtonConfiguration) -> some View {
        DefaultSkipButton(skip: configuration.skip)
    }
}

/// The view of ``DefaultSkipButtonStyle``.
///
/// A separate view because it reads the environment, which a style method cannot.
private struct DefaultSkipButton: View {
    let skip: () -> Void

    var body: some View {
        Button(action: skip) {
            // The vertical toolbar exists only from iOS 27.1; earlier, always the title.
            if #available(iOS 27.1, *) {
                SideBarAwareSkipLabel()
            } else {
                Text("Skip", bundle: .module)
            }
        }
    }
}

/// The Skip label that switches to a symbol inside the vertical toolbar.
@available(iOS 27.1, *)
private struct SideBarAwareSkipLabel: View {
    /// The edge of the vertical toolbar, or `nil` when the screen has none.
    ///
    /// It describes the whole toolbar, not this button: it is set even when the
    /// button itself stays in the top bar.
    @Environment(\.toolbarVerticalEdge) private var verticalEdge

    /// Whether the app let the button move into the vertical toolbar.
    @Environment(\.skipButtonPrefersSideBar) private var prefersSideBar

    /// The symbol is used only when the button can actually be in the vertical bar.
    private var showsSymbol: Bool {
        prefersSideBar && verticalEdge != nil
    }

    var body: some View {
        if showsSymbol {
            Label { Text("Skip", bundle: .module) } icon: { Image(systemName: "chevron.forward") }
                .labelStyle(.iconOnly)
        } else {
            Text("Skip", bundle: .module)
        }
    }
}

extension SkipButtonStyle where Self == DefaultSkipButtonStyle {
    /// The default Skip button: a standard system button.
    public static var automatic: Self { .init() }
}

#Preview {
    let style: some SkipButtonStyle = .automatic

    style
        .makeBody(configuration: .init(skip: {}))
        .padding()
}
