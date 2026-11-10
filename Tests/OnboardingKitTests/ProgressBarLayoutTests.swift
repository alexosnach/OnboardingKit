//
//  ProgressBarLayoutTests.swift
//  OnboardingKitTests
//

import CoreGraphics
import Testing
@testable import OnboardingKit

@Suite("ProgressBarLayout")
struct ProgressBarLayoutTests {

    /// The system's own gap next to an item is topped up to the spacing.
    @Test(arguments: [0, 8, 12, 20] as [CGFloat])
    func paddingTopsTheSystemGapUpToTheSpacing(gap: CGFloat) {
        #expect(ProgressBarLayout.padding(forGap: gap) + gap == ProgressBarLayout.itemSpacing)
    }

    /// No item on a side: the bar keeps to the navigation bar's margin.
    @Test func noPaddingWithoutAnItem() {
        #expect(ProgressBarLayout.padding(forGap: nil) == 0)
    }

    /// A system gap already wider than the spacing is never narrowed.
    @Test func neverNegative() {
        #expect(ProgressBarLayout.padding(forGap: ProgressBarLayout.itemSpacing + 10) == 0)
    }

    @Test func spacingIsThirtyTwoPoints() {
        #expect(ProgressBarLayout.itemSpacing == 32)
    }
}

@Suite("NavigationBarGaps")
struct NavigationBarGapsTests {

    /// Before the bar is laid out there are no gaps, so no padding.
    @Test func emptyByDefault() {
        let gaps = NavigationBarGaps()

        #expect(gaps.leading == nil && gaps.trailing == nil)
    }
}
