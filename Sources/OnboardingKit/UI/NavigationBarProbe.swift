//
//  NavigationBarProbe.swift
//  OnboardingKit
//

import SwiftUI
import UIKit

/// The gaps the navigation bar left between a slot and its neighboring items.
///
/// `nil` on a side where no item was found: there the slot runs up to the bar's
/// margin. Before the first report every side is `nil`.
struct NavigationBarGaps: Equatable {
    /// The gap to the item on the leading side (the back button).
    var leading: CGFloat?

    /// The gap to the item on the trailing side (Skip).
    var trailing: CGFloat?

    /// The navigation bar width the gaps were read at. A new width means the
    /// bar was laid out again (rotation, folding), and the slot must be resized.
    var barWidth: CGFloat = 0

    /// Whether the slot runs out of the navigation bar. The system lays the slot
    /// out inside the bar; but, as observed, after a cancelled interactive pop it can leave the
    /// slot at its unbounded expanded width. Then the gaps mean nothing, and the
    /// slot must be rebuilt for the system to lay it out again.
    var isSlotOutsideBar = false

    /// The slot's frame in the window, where the system laid it out.
    var slotFrame: CGRect?
}

/// A navigation bar slot that the system stretches over all the free room.
///
/// Observed (not documented API): the navigation bar stretches a principal item
/// that asks for `UIView.layoutFittingExpandedSize` over the space between the
/// bar's items, or up to the bar's margins where there are none. The slot's size
/// and position come from the system on any screen width, orientation, layout
/// direction and button style.
///
/// The slot also reports the gaps the system left next to the neighboring items,
/// read from the items' frames with heuristics (see `neighborEdges`). Use them
/// inside the slot (for padding), never to size the slot itself, so a report cannot start a layout loop. A report may
/// only rebuild the slot, when the bar's width changes or the slot is outside the bar.
struct ExpandingNavigationBarSlot: UIViewRepresentable {
    let onGapsChange: (NavigationBarGaps) -> Void

    func makeUIView(context: Context) -> SlotView {
        let view = SlotView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: SlotView, context: Context) {
        view.onGapsChange = onGapsChange
        view.reportWhenSettled()
    }

    /// As wide as offered, and expanded when asked for an ideal size, so the
    /// navigation bar sees a view that wants all the room. No height of its own:
    /// the content laid over it sets the height.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: SlotView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? UIView.layoutFittingExpandedSize.width, height: 0)
    }

    final class SlotView: UIView {
        var onGapsChange: ((NavigationBarGaps) -> Void)?
        private var lastGaps: NavigationBarGaps?

        /// Follows the navigation bar's size: when the screen changes, the bar is
        /// laid out again, but this slot keeps its old size until it is rebuilt.
        private var barSizeObservation: NSKeyValueObservation?

        override var intrinsicContentSize: CGSize { UIView.layoutFittingExpandedSize }

        override func layoutSubviews() {
            super.layoutSubviews()
            reportWhenSettled()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            barSizeObservation = enclosingNavigationBar?.layer.observe(\.bounds) { [weak self] _, _ in
                DispatchQueue.main.async { self?.reportWhenSettled() }
            }
            reportWhenSettled()
        }

        /// Reads the gaps after the current layout pass, and once more 0.6 s later,
        /// meant to come after a navigation transition: items move into the bar at
        /// its end without resizing this view. The delay is an estimate, not tied
        /// to the transition's end.
        func reportWhenSettled() {
            DispatchQueue.main.async { [weak self] in self?.report() }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.transitionDuration) { [weak self] in
                self?.report()
            }
        }

        /// An estimate: a little longer than a typical navigation push or rotation.
        private static let transitionDuration: TimeInterval = 0.6

        private func report() {
            guard let navigationBar = enclosingNavigationBar, bounds.width > 0 else { return }
            let slot = convert(bounds, to: navigationBar)
            let (left, right) = neighborEdges(around: slot, in: navigationBar)

            let leftGap = left.map { slot.minX - $0 }
            let rightGap = right.map { $0 - slot.maxX }
            let isRightToLeft = navigationBar.effectiveUserInterfaceLayoutDirection == .rightToLeft
            let gaps = NavigationBarGaps(
                leading: isRightToLeft ? rightGap : leftGap,
                trailing: isRightToLeft ? leftGap : rightGap,
                barWidth: navigationBar.bounds.width,
                isSlotOutsideBar: !navigationBar.bounds.contains(CGPoint(x: slot.minX, y: slot.midY))
                    || slot.maxX > navigationBar.bounds.maxX,
                slotFrame: convert(bounds, to: nil)
            )
            guard gaps != lastGaps else { return }
            lastGaps = gaps
            onGapsChange?(gaps)
        }

        /// The nearest item edges to the left and to the right of `slot`.
        ///
        /// Items are the bar's views beside the slot on the same row, inside the
        /// bar's bounds and narrower than half the bar. Hidden views are skipped with their subviews. A view's
        /// opacity is not a sign: an item fades in from fully transparent while
        /// it is already laid out in place. Views reaching out of the bar are not
        /// items: a pressed button leaves its glow behind, wider and taller than
        /// the button. A view's size is taken from its bounds, ignoring its scale:
        /// the system scales item views for their press effect. Its center keeps
        /// the transform.
        private func neighborEdges(
            around slot: CGRect,
            in navigationBar: UINavigationBar
        ) -> (left: CGFloat?, right: CGFloat?) {
            let ancestors = Set(sequence(first: self as UIView, next: { $0.superview }).map(ObjectIdentifier.init))
            var left: CGFloat?
            var right: CGFloat?

            func visit(_ view: UIView) {
                for child in view.subviews where child !== self && !child.isHidden {
                    if ancestors.contains(ObjectIdentifier(child)) {
                        visit(child)
                        continue
                    }
                    let frame = untransformedFrame(of: child, in: navigationBar)
                    let isBesideSlot = frame.width > 0 && frame.height > 0
                        && frame.width < navigationBar.bounds.width / 2
                        && isInsideBar(frame, navigationBar)
                        && frame.maxY > slot.minY && frame.minY < slot.maxY
                    if isBesideSlot, frame.maxX <= slot.minX {
                        left = max(left ?? frame.maxX, frame.maxX)
                    } else if isBesideSlot, frame.minX >= slot.maxX {
                        right = min(right ?? frame.minX, frame.minX)
                    }
                    visit(child)
                }
            }
            visit(navigationBar)
            return (left, right)
        }

        /// Whether `frame` lies within the bar's height, allowing for rounding.
        private func isInsideBar(_ frame: CGRect, _ navigationBar: UINavigationBar) -> Bool {
            let rounding: CGFloat = 1 / max(traitCollection.displayScale, 1)
            return frame.minY >= navigationBar.bounds.minY - rounding
                && frame.maxY <= navigationBar.bounds.maxY + rounding
        }

        private func untransformedFrame(of view: UIView, in navigationBar: UINavigationBar) -> CGRect {
            let scaled = view.convert(view.bounds, to: navigationBar)
            return CGRect(
                x: scaled.midX - view.bounds.width / 2,
                y: scaled.midY - view.bounds.height / 2,
                width: view.bounds.width,
                height: view.bounds.height
            )
        }

        private var enclosingNavigationBar: UINavigationBar? {
            sequence(first: superview, next: { $0?.superview })
                .lazy
                .compactMap { $0 as? UINavigationBar }
                .first
        }
    }
}
