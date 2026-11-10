//
//  StepScrollEdgeTests.swift
//  OnboardingKitTests
//

import SwiftUI
import UIKit
import Testing
@testable import OnboardingKit

/// The top scroll edge of the steps: soft by default, and a step can change it.
///
/// Checked on the `UIScrollView` behind each SwiftUI `ScrollView`, where the
/// system applies the style it resolved.
@MainActor
@Suite("StepScrollEdge")
struct StepScrollEdgeTests {

    // MARK: - The modifier

    @Test func defaultStyleIsSoft() {
        #expect(StepScrollEdge.topStyle == .soft)
    }

    /// Without the onboarding's modifier the system decides (`.automatic`).
    ///
    /// On iOS 27 it does not pick `.soft`, so the tests below show the
    /// modifier's effect, not a system default. Observed on iOS 26: the system
    /// already picks `.soft`, at any width, so there the modifier changes nothing
    /// visible and only keeps the style the same across versions.
    @Test func withoutModifierSystemDecides() async throws {
        let style = try await topEdgeStyle(of: scrolling)
        if #available(iOS 27, *) {
            #expect(style != .soft)
        } else {
            #expect(style == .soft)
        }
    }

    @Test func modifierMakesTopEdgeSoft() async throws {
        let style = try await topEdgeStyle(of: scrolling.stepScrollEdge())
        #expect(style == .soft)
    }

    /// The step's own choice is closer to its scroll view, so it wins.
    @Test func stepOverridesSoftWithHard() async throws {
        let style = try await topEdgeStyle(of:
            scrolling.scrollEdgeEffectStyle(.hard, for: .top).stepScrollEdge()
        )
        #expect(style == .hard)
    }

    @Test func stepCanHideTopEdge() async throws {
        let scrollView = try await hostedScrollView(of:
            scrolling.scrollEdgeEffectHidden(true, for: .top).stepScrollEdge()
        )
        #expect(scrollView.topEdgeEffect.isHidden)
    }

    /// Only the top edge, under the navigation bar, is set by the onboarding.
    @Test func otherEdgesAreLeftToTheSystem() async throws {
        let plain = try await hostedScrollView(of: scrolling)
        let styled = try await hostedScrollView(of: scrolling.stepScrollEdge())
        #expect(styled.bottomEdgeEffect.style == plain.bottomEdgeEffect.style)
    }

    // MARK: - OnboardingView, both chrome placements

    @Test(arguments: [OnboardingChromePlacement.perStep, .pinned])
    func onboardingStepsGetSoftTopEdge(placement: OnboardingChromePlacement) async throws {
        let coordinator = OnboardingCoordinator(steps: [ScrollingStep()])
        let style = try await topEdgeStyle(of:
            OnboardingFlowView(coordinator: coordinator).onboardingChrome(placement)
        )
        #expect(style == .soft)
    }

    @Test(arguments: [OnboardingChromePlacement.perStep, .pinned])
    func onboardingStepCanOverrideTopEdge(placement: OnboardingChromePlacement) async throws {
        let coordinator = OnboardingCoordinator(steps: [ScrollingStep(topStyle: .hard)])
        let style = try await topEdgeStyle(of:
            OnboardingFlowView(coordinator: coordinator).onboardingChrome(placement)
        )
        #expect(style == .hard)
    }

    // MARK: - Helpers

    private var scrolling: some View {
        ScrollView { Color.red.frame(height: 2000) }
    }

    private func topEdgeStyle(of view: some View) async throws -> UIScrollEdgeEffect.Style {
        try await hostedScrollView(of: view).topEdgeEffect.style
    }

    /// Shows `view` in a window and returns the first `UIScrollView` inside it.
    private func hostedScrollView(of view: some View) async throws -> UIScrollView {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        window.rootViewController = UIHostingController(rootView: view)
        window.isHidden = false
        defer { window.isHidden = true }
        // Give SwiftUI a few turns to build the hierarchy and apply the modifiers.
        for _ in 0..<10 {
            window.layoutIfNeeded()
            if let scrollView = Self.firstScrollView(in: window) { return scrollView }
            try await Task.sleep(for: .milliseconds(50))
        }
        return try #require(Self.firstScrollView(in: window), "No UIScrollView in the hosted view")
    }

    private static func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        for subview in view.subviews {
            if let found = firstScrollView(in: subview) { return found }
        }
        return nil
    }
}

/// A step whose content scrolls, optionally with its own top edge style.
private struct ScrollingStep: OnboardingStep {
    let id = "scrolling"
    var topStyle: ScrollEdgeEffectStyle?

    var content: some View {
        ScrollView { Color.blue.frame(height: 2000) }
            .scrollEdgeEffectStyle(topStyle, for: .top)
    }
}
