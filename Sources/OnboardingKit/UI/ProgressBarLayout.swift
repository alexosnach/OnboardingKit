//
//  ProgressBarLayout.swift
//  OnboardingKit
//

import CoreGraphics

/// The progress bar's spacing in the navigation bar.
///
/// The system lays out the bar's slot (see ``ExpandingNavigationBarSlot``): it fills
/// all the room between the back button and Skip, or reaches the bar's margins
/// where they are hidden. Next to an item the system leaves its own gap; when that
/// gap is smaller than `itemSpacing`, the bar adds padding so it becomes
/// `itemSpacing`. A larger system gap is kept as it is.
///
/// Kept separate from ``OnboardingView`` so it can be unit-tested without UI.
enum ProgressBarLayout {

    /// The gap between the progress bar and a side item.
    static let itemSpacing: CGFloat = 32

    /// The padding that turns the system's `gap` into `itemSpacing`.
    ///
    /// - Parameter gap: The system's gap to the item, or `nil` when there is no item
    ///   on that side; then the bar keeps to the navigation bar's margin.
    static func padding(forGap gap: CGFloat?) -> CGFloat {
        gap.map { max(0, itemSpacing - $0) } ?? 0
    }
}
