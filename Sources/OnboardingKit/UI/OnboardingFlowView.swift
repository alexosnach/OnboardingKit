//
//  OnboardingFlowView.swift
//  OnboardingKit
//
//  Created by alex on 07/11/2026.
//

import SwiftUI

/// Shows a loaded flow: the steps with their navigation bar.
///
/// Created by ``OnboardingView`` once the provider has answered; apps present
/// ``OnboardingView``, not this view. The chrome modifiers (``SwiftUI/View/progressBarStyle(_:)``,
/// ``SwiftUI/View/onboardingChrome(_:)`` and the others) are set on ``OnboardingView`` and reach it
/// through the environment.
///
/// Owns its own `NavigationStack`, independent from the app's navigation.
/// Present it outside of any other `NavigationStack` — as the app root
/// or in a `fullScreenCover` — because SwiftUI does not support nested stacks.
///
/// The view contains no navigation logic: it renders the coordinator's state
/// and forwards user actions back to it. When it appears it calls
/// `coordinator.start()`: the first step becomes current and analytics gets `started`.
///
/// The progress bar fills the navigation bar between the back button and Skip.
/// Once the system's layout is measured, its gap to each of them is at least
/// 32 pt (see ``ProgressBarLayout``); on a side with no item it reaches the
/// system's margin. It is shown on steps where
/// ``StepConfiguration/isProgressBarShown`` is `true`. Its look is set with
/// ``SwiftUI/View/progressBarStyle(_:)`` and defaults to `.line`.
///
/// The Skip button is drawn on the trailing side of the navigation bar on steps where
/// ``StepConfiguration/isSkipButtonShown`` is `true`. Its look is set with
/// ``SwiftUI/View/skipButtonStyle(_:)`` and defaults to `.automatic`. On iPhone Duo it stays in
/// the top bar unless the app calls ``SwiftUI/View/skipButtonPrefersSideBar(_:)``.
///
/// The back button is the native `NavigationStack` button by default. A custom
/// ``SwiftUI/View/backButtonStyle(_:)`` replaces it with a button on the leading side; with
/// `.pinned` the button is always drawn by the style, since nothing is pushed.
/// Either way it is shown only where ``StepConfiguration/isBackButtonShown`` is `true`
/// and never on the first step. On iPhone Duo (iOS 27.1 and later), a drawn
/// `.automatic` button prefers the vertical bar; where the native button and a
/// custom style's button go is the system's decision.
///
/// By default each step has its own navigation bar, which the system's push and
/// pop slide with the step.
/// With `onboardingChrome(.pinned)` the navigation bar stays in place and only the
/// step content slides; see ``OnboardingChromePlacement`` for the trade-offs.
/// Both modes use the system navigation bar, so the system lays it out on every
/// device (next to the status bar, in the vertical bar of iPhone Duo, with glass).
///
/// - Precondition: `coordinator.steps` is not empty. An empty flow is completed
///   immediately; ``OnboardingView`` reports it as completed and never shows this
///   view for it. Shown anyway, it crashes with an index out of range.
struct OnboardingFlowView: View {
    /// The style set by the app with ``SwiftUI/View/progressBarStyle(_:)``.
    @Environment(\.progressBarStyle) private var progressBarStyle

    /// The style set by the app with ``SwiftUI/View/skipButtonStyle(_:)``.
    @Environment(\.skipButtonStyle) private var skipButtonStyle

    /// The style set by the app with ``SwiftUI/View/backButtonStyle(_:)``.
    @Environment(\.backButtonStyle) private var backButtonStyle

    /// The placement set by the app with ``SwiftUI/View/onboardingChrome(_:)``.
    @Environment(\.onboardingChromePlacement) private var chromePlacement

    /// Set by the app with ``SwiftUI/View/skipButtonPrefersSideBar(_:)``.
    @Environment(\.skipButtonPrefersSideBar) private var skipButtonPrefersSideBar

    let coordinator: OnboardingCoordinator

    /// The direction of the last move in `.pinned`, used by the content transition.
    @State private var isMovingForward = true

    /// `.pinned`: the window's width, the distance a step slides to leave it.
    ///
    /// Read from `UIWindow`: on iPhone Duo the vertical bar is a column of the
    /// window outside the navigation stack (not a safe area), so every size
    /// SwiftUI reports inside the stack is narrower than the window.
    @State private var windowWidth: CGFloat = 0

    /// `.pinned`: the side safe area where the steps rest, given to every step
    /// as its own padding so it does not change while the step slides.
    @State private var horizontalSafeArea = HorizontalSafeArea()

    /// The system's gaps between the progress bar and its neighbors, by navigation bar.
    @State private var progressBarGaps: [Int: NavigationBarGaps] = [:]

    /// Counts hinge changes reported by the device (folding iPhone Duo).
    ///
    /// Observed: the navigation bar sizes its middle item once and does not ask again when
    /// the screen changes, so the progress bar slot is rebuilt when the system
    /// reports a new layout. A hinge change is one of those signals; the others
    /// are listed in `progressBarItemID(index:)`.
    @State private var hingeChanges = 0

    /// Counts the times the system left the progress bar slot outside the
    /// navigation bar (after a cancelled swipe-back); each one rebuilds the slot.
    @State private var slotRebuilds = 0

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Whether the back button is drawn by ``BackButtonStyle`` instead of the system.
    private var drawsBackButtonWithStyle: Bool {
        chromePlacement == .pinned || !backButtonStyle.usesNativeButton
    }

    var body: some View {
        Group {
            switch chromePlacement {
            case .perStep:
                // Read the state here, in `body`: `@Observable` tracks only what `body` reads.
                // A value read later inside the Binding's `get` would not refresh the view.
                NavigationStack(path: path(currentIndex: coordinator.currentIndex)) {
                    stepWithOwnNavigationBar(at: 0)
                        .navigationDestination(for: Int.self) { index in
                            stepWithOwnNavigationBar(at: index)
                        }
                }
            case .pinned:
                NavigationStack {
                    pinnedSteps
                }
                .overlay { pinnedProgressBar }
                .background {
                    WindowWidthReader { windowWidth = $0 }
                }
            }
        }
        .modifier(HingeChangeCounter(count: $hingeChanges))
        .onAppear { coordinator.start() }
        .environment(\.onboardingNext, OnboardingNavigationAction { move(forward: true) { coordinator.next() } })
        .environment(\.onboardingSkip, OnboardingNavigationAction { move(forward: true) { coordinator.skip() } })
    }

    // MARK: - Pinned chrome

    /// `.pinned`: one screen whose navigation bar never moves; only the content slides.
    ///
    /// Nothing is pushed onto the stack, so the system keeps a single navigation bar
    /// and updates its items in place. The bar is still the system one, laid out
    /// by the system on every device.
    private var pinnedSteps: some View {
        let index = coordinator.currentIndex

        return ZStack {
            stepContent(at: index)
                // The side safe area as measured where the steps rest, so it
                // moves with the step instead of being resolved where it is.
                .safeAreaPadding(.leading, horizontalSafeArea.leading)
                .safeAreaPadding(.trailing, horizontalSafeArea.trailing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Opaque like a pushed screen, so the step below is covered, not seen through.
                .background(.background)
                .id(index)
                // The later step is always on top: it slides over on forward,
                // and slides away over the earlier one on back.
                .zIndex(Double(index))
                .transition(contentTransition)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // SwiftUI gives a view the safe area it touches where it is drawn: a
        // step moved by the transition no longer touches the side insets (the
        // vertical bar's column on iPhone Duo), so a background that ignores
        // the safe area stops short of the column, which stays empty until the
        // transition ends. The steps take the whole width, and get the side
        // insets back above as their own padding.
        .ignoresSafeArea(.container, edges: .horizontal)
        .background {
            // Does not move, so it reads the side insets where the steps rest.
            Color.clear.onGeometryChange(for: HorizontalSafeArea.self) { proxy in
                HorizontalSafeArea(leading: proxy.safeAreaInsets.leading, trailing: proxy.safeAreaInsets.trailing)
            } action: { horizontalSafeArea = $0 }
        }
        .chromeToolbar(self, index: index, drawsBackButtonWithStyle: true)
    }

    /// Slides like a navigation push.
    ///
    /// The step on top moves the full width; the step below moves 30% of it, an
    /// approximation of the `NavigationStack` push. Forward: the new step comes over from the trailing edge.
    /// Back: the current step leaves over the earlier one towards the trailing edge.
    /// Mirrors in right-to-left layouts.
    private var contentTransition: AnyTransition {
        let covered = AnyTransition.modifier(
            active: PushOffset(fraction: -PushOffset.coveredFraction, windowWidth: windowWidth),
            identity: PushOffset(fraction: 0, windowWidth: windowWidth)
        )
        let onTop = AnyTransition.modifier(
            active: PushOffset(fraction: 1, windowWidth: windowWidth),
            identity: PushOffset(fraction: 0, windowWidth: windowWidth)
        )
        return isMovingForward
            ? .asymmetric(insertion: onTop, removal: covered)
            : .asymmetric(insertion: covered, removal: onTop)
    }

    /// Runs a navigation action, animating the content in `.pinned`.
    ///
    /// When the direction changes, it is applied first, and the move follows on
    /// the next turn of the main queue:
    /// a view being removed animates with the transition from its last update,
    /// so the outgoing step must first be updated with the new direction.
    private func move(forward: Bool, _ action: @escaping () -> Void) {
        guard chromePlacement == .pinned else {
            // `.perStep`: `NavigationStack` animates the push itself.
            action()
            return
        }
        guard isMovingForward != forward else {
            withAnimation(.smooth) { action() }
            return
        }
        isMovingForward = forward
        DispatchQueue.main.async {
            withAnimation(.smooth) { action() }
        }
    }

    // MARK: - Bridge between the coordinator and NavigationStack

    /// Steps shown above the root; see ``OnboardingNavigationPath`` for the mapping.
    ///
    /// When the user goes back with the native button or swipe,
    /// `NavigationStack` writes a shorter path, and the coordinator follows it.
    private func path(currentIndex: Int) -> Binding<[Int]> {
        Binding(
            get: { OnboardingNavigationPath.path(for: currentIndex) },
            set: { OnboardingNavigationPath.apply($0, to: coordinator) }
        )
    }

    // MARK: - A single step

    /// The step's content as both modes show it, with the onboarding's look of
    /// the scroll edge under the bar (``StepScrollEdge``) and the step's place in
    /// the flow in the environment (``SwiftUI/EnvironmentValues/onboardingStepInfo``, ``SwiftUI/EnvironmentValues/onboardingFlowID``).
    private func stepContent(at index: Int) -> AnyView {
        // Erase the step's content type first, then style a concrete view.
        AnyView(
            AnyView(coordinator.steps[index].content)
                .stepScrollEdge()
                .environment(\.onboardingStepInfo, coordinator.stepInfo(at: index))
                .environment(\.onboardingFlowID, coordinator.flowID)
        )
    }

    /// The step's content with its own system navigation bar (`.perStep`).
    ///
    /// The step only declares its ``StepConfiguration``; the chrome is applied here.
    /// Progress uses the step's own `index`, not `coordinator.currentIndex`:
    /// during a back transition two steps are on screen, and each must show its own progress.
    private func stepWithOwnNavigationBar(at index: Int) -> some View {
        stepContent(at: index)
            .chromeToolbar(self, index: index, drawsBackButtonWithStyle: !backButtonStyle.usesNativeButton)
    }

    // MARK: - Chrome shared by both modes

    /// The navigation bar items for the step at `index`.
    ///
    /// Shared by both modes; the visibility rules live in ``ChromeVisibility``.
    @ToolbarContentBuilder
    fileprivate func chromeItems(index: Int, drawsBackButtonWithStyle: Bool) -> some ToolbarContent {
        let visibility = ChromeVisibility(configuration: coordinator.steps[index].configuration, index: index)

        if visibility.isBackButtonVisible && drawsBackButtonWithStyle {
            backItem
        }
        // A new id makes the system build a new item: the navigation bar keeps an
        // item's size (observed), and only a new item is sized for the new screen.
        ToolbarItem(id: progressBarItemID(index: index), placement: .principal) {
            if visibility.isProgressBarVisible {
                progressBar(index: index)
            }
        }
        skipItem(isVisible: visibility.isSkipButtonVisible)
    }

    /// The progress bar item's identity: it changes whenever the system reports a
    /// new layout — the navigation bar's width, a hinge change, a size class, or
    /// a slot left outside the bar.
    private func progressBarItemID(index: Int) -> String {
        let key = ProgressBarSlotKey(
            barWidth: progressBarGaps[navigationBarKey(index: index)]?.barWidth ?? 0,
            hingeChanges: hingeChanges,
            slotRebuilds: slotRebuilds,
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
        return "onboarding.progressBar.\(key)"
    }

    /// The progress bar in the middle of the navigation bar.
    ///
    /// The system stretches the slot over all the room between the side items
    /// (or up to the bar's margins where there are none) and leaves its own gap
    /// next to each item. In `.perStep` the bar tops that gap up to
    /// ``ProgressBarLayout/itemSpacing``. In `.pinned` the bar here is hidden and only
    /// gives the slot its height; `pinnedProgressBar` draws it.
    private func progressBar(index: Int) -> some View {
        let key = navigationBarKey(index: index)
        let gaps = progressBarGaps[key] ?? NavigationBarGaps()
        let bar = progressBarStyle.makeBody(configuration: ProgressBarConfiguration(
            currentIndex: index,
            total: coordinator.steps.count
        ))
        return ZStack {
            ExpandingNavigationBarSlot { gaps in
                // Rebuild once per broken layout, not on every report of it.
                if gaps.isSlotOutsideBar, progressBarGaps[key]?.isSlotOutsideBar != true {
                    slotRebuilds += 1
                }
                progressBarGaps[key] = gaps
            }
            if chromePlacement == .pinned {
                // Drawn over the navigation bar by `pinnedProgressBar`; here it
                // only gives the slot its height.
                bar.hidden()
            } else {
                bar
                    .padding(.leading, ProgressBarLayout.padding(forGap: gaps.leading))
                    .padding(.trailing, ProgressBarLayout.padding(forGap: gaps.trailing))
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("onboarding.progressBar")
            }
        }
    }

    /// `.pinned`: the progress bar, drawn over the one navigation bar.
    ///
    /// The bar's slot stays in the navigation bar, where the system gives it its
    /// room; but when items come and go, the system moves and resizes the slot
    /// at once or with its own animation, and a bar inside it would jump. Over
    /// the navigation bar the bar moves smoothly to the new room once the new
    /// layout is measured; its animation is its own, not synchronized with the
    /// navigation bar's.
    private var pinnedProgressBar: some View {
        let index = coordinator.currentIndex
        let visibility = ChromeVisibility(configuration: coordinator.steps[index].configuration, index: index)
        let gaps = progressBarGaps[navigationBarKey(index: index)]
        return MovingProgressBar(
            bar: progressBarStyle.makeBody(configuration: ProgressBarConfiguration(
                currentIndex: index,
                total: coordinator.steps.count
            )),
            frame: visibility.isProgressBarVisible ? gaps.flatMap(barFrame(in:)) : nil
        )
    }

    /// Where the bar goes in its slot, in the window: the slot inset by the
    /// paddings that make the gaps ``ProgressBarLayout/itemSpacing``.
    private func barFrame(in gaps: NavigationBarGaps) -> CGRect? {
        guard let slot = gaps.slotFrame, !gaps.isSlotOutsideBar else { return nil }
        let leading = ProgressBarLayout.padding(forGap: gaps.leading)
        let trailing = ProgressBarLayout.padding(forGap: gaps.trailing)
        let isRightToLeft = layoutDirection == .rightToLeft
        let left = isRightToLeft ? trailing : leading
        let right = isRightToLeft ? leading : trailing
        return CGRect(x: slot.minX + left, y: slot.midY, width: max(0, slot.width - left - right), height: 0)
    }

    /// The navigation bar that shows the step at `index`: one for all steps in
    /// `.pinned`, its own for each step in `.perStep`. What the progress bar
    /// learned about its bar carries over from step to step in `.pinned`.
    private func navigationBarKey(index: Int) -> Int {
        chromePlacement == .pinned ? 0 : index
    }

    /// Whether the native back button is shown for the step at `index`.
    fileprivate func showsNativeBackButton(index: Int, drawsBackButtonWithStyle: Bool) -> Bool {
        let visibility = ChromeVisibility(configuration: coordinator.steps[index].configuration, index: index)
        return visibility.isBackButtonVisible && !drawsBackButtonWithStyle
    }

    /// The back button drawn by ``BackButtonStyle``.
    private func backToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            backButtonStyle
                .makeBody(configuration: BackButtonConfiguration(
                    back: { move(forward: false) { coordinator.back() } }
                ))
                .accessibilityIdentifier("onboarding.backButton")
        }
    }

    /// The back item drawn by the style. On iOS 27.1 and later, `.automatic`
    /// prefers the vertical toolbar and a custom style leaves it to the system.
    @ToolbarContentBuilder
    private var backItem: some ToolbarContent {
        if #available(iOS 27.1, *) {
            // The default style is a chevron, like the native button, so it may go
            // to the vertical bar. A custom style may be a title,
            // so the system decides for it.
            backToolbarItem()
                .axisBehavior(backButtonStyle.usesNativeButton ? .verticalPreferred : .automatic)
        } else {
            backToolbarItem()
        }
    }

    /// The Skip button in the navigation bar.
    private func skipToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            skipButtonStyle
                .makeBody(configuration: SkipButtonConfiguration(
                    skip: { move(forward: true) { coordinator.skip() } }
                ))
        }
    }

    /// The Skip item with its vertical-toolbar behavior where the system supports it.
    ///
    /// The item itself is added and removed, like the back item, never left in
    /// the bar with empty content. Observed: the navigation bar animates its layout
    /// when items come and go, but applies a new size of an existing item at once,
    /// and the progress bar would jump to its new width.
    @ToolbarContentBuilder
    private func skipItem(isVisible: Bool) -> some ToolbarContent {
        if isVisible {
            skipItemWithAxisBehavior
        }
    }

    @ToolbarContentBuilder
    private var skipItemWithAxisBehavior: some ToolbarContent {
        if #available(iOS 27.1, *) {
            // Explicit both ways: with `.automatic` the system could move Skip to
            // the vertical bar on its own, even when the app did not opt in.
            skipToolbarItem()
                .axisBehavior(skipButtonPrefersSideBar ? .verticalPreferred : .horizontalOnly)
        } else {
            // No vertical toolbar before iOS 27.1: the item always stays in the top bar.
            skipToolbarItem()
        }
    }
}

private extension View {
    /// Applies the onboarding navigation bar for the step at `index`.
    func chromeToolbar(_ onboarding: OnboardingFlowView, index: Int, drawsBackButtonWithStyle: Bool) -> some View {
        self
            .navigationBarBackButtonHidden(
                !onboarding.showsNativeBackButton(index: index, drawsBackButtonWithStyle: drawsBackButtonWithStyle)
            )
            .toolbar {
                onboarding.chromeItems(index: index, drawsBackButtonWithStyle: drawsBackButtonWithStyle)
            }
    }
}

/// Shifts a step horizontally by a fraction of its width, towards the trailing edge.
///
/// Negative fractions shift towards the leading edge. Follows the layout direction.
private struct PushOffset: ViewModifier {
    /// How far the covered step moves: an approximation of the `NavigationStack` push.
    static let coveredFraction: CGFloat = 0.3

    let fraction: CGFloat

    /// The window's width. A step leaving on top moves at least this far, not
    /// only its own width: on iPhone Duo the window is wider than the steps by
    /// the vertical bar's column, and a step moved by its own width stops in
    /// that column. It shows there until the transition ends wherever the bar
    /// has no items to cover it (a step with neither back nor Skip).
    let windowWidth: CGFloat

    @Environment(\.layoutDirection) private var layoutDirection

    func body(content: Content) -> some View {
        let direction: CGFloat = layoutDirection == .rightToLeft ? -1 : 1
        let windowWidth = windowWidth
        let fraction = fraction
        content.visualEffect { content, proxy in
            // Only the step on top leaves the window; the covered one keeps
            // moving a share of its own width, as before.
            let width = fraction > 0 ? max(proxy.size.width, windowWidth) : proxy.size.width
            return content.offset(x: width * fraction * direction)
        }
    }
}

/// A progress bar that moves smoothly to each new frame it is given.
///
/// Placed over the whole onboarding; `frame` is in the window and has zero
/// height, so its `minY` is the line the bar is centered on. `nil` hides the bar.
private struct MovingProgressBar<Bar: View>: View {
    let bar: Bar
    let frame: CGRect?

    /// The frame shown now; it follows `frame` with an animation.
    @State private var shown: CGRect?

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        GeometryReader { proxy in
            if let shown {
                let origin = proxy.frame(in: .global).origin
                bar
                    // The bar keeps the app's direction; only its placement is in
                    // the window's left-to-right coordinates.
                    .environment(\.layoutDirection, layoutDirection)
                    .frame(width: shown.width)
                    .position(x: shown.midX - origin.x, y: shown.minY - origin.y)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("onboarding.progressBar")
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: frame, initial: true) { _, frame in
            if shown == nil || frame == nil {
                shown = frame
            } else {
                withAnimation(.smooth) { shown = frame }
            }
        }
    }
}

/// The leading and trailing safe area insets.
private nonisolated struct HorizontalSafeArea: Equatable, Sendable {
    var leading: CGFloat = 0
    var trailing: CGFloat = 0
}

/// What the system reported about the screen layout; a new value rebuilds the
/// progress bar slot so the navigation bar sizes it again.
private struct ProgressBarSlotKey: Hashable {
    /// The navigation bar width the slot was laid out in, as the bar reported it.
    let barWidth: CGFloat
    let hingeChanges: Int
    let slotRebuilds: Int
    let horizontalSizeClass: UserInterfaceSizeClass?
    let verticalSizeClass: UserInterfaceSizeClass?
}

/// Counts changes of the hinge status (folded, unfolded) on iOS 27.1 and later.
///
/// iPhone Duo reports them through `onHingeChange`; changes of the angle alone
/// are ignored. Earlier versions count nothing.
private struct HingeChangeCounter: ViewModifier {
    @Binding var count: Int

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.onHingeChange { old, new in
                // Only the state matters for layout, not every angle step.
                guard old.hinge?.status != new.hinge?.status else { return }
                count += 1
            }
        } else {
            content
        }
    }
}

/// Reports the width of the `UIWindow` it is in, and again whenever it changes.
private struct WindowWidthReader: UIViewRepresentable {
    let onChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: ReaderView, context: Context) {
        view.onChange = onChange
    }

    final class ReaderView: UIView {
        var onChange: ((CGFloat) -> Void)?
        private var reported: CGFloat?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            report()
        }

        private func report() {
            guard let width = window?.bounds.width, width != reported else { return }
            reported = width
            // Not during the layout pass that asked: it would change state mid-update.
            DispatchQueue.main.async { [weak self] in self?.onChange?(width) }
        }
    }
}
