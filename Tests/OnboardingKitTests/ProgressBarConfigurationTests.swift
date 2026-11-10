//
//  ProgressBarConfigurationTests.swift
//  OnboardingKitTests
//

import Testing
@testable import OnboardingKit

@Suite("ProgressBarConfiguration")
struct ProgressBarConfigurationTests {

    /// Step N of M fills N segments.
    @Test(arguments: [(0, 1), (1, 2), (2, 3)])
    func completedCountCountsCurrentStep(currentIndex: Int, expected: Int) {
        let configuration = ProgressBarConfiguration(currentIndex: currentIndex, total: 3)

        #expect(configuration.completedCount == expected)
    }

    @Test func firstStepShowsOneSegmentNotZero() {
        let configuration = ProgressBarConfiguration(currentIndex: 0, total: 4)

        #expect(configuration.fraction == 0.25)
    }

    @Test func lastStepShowsFullBar() {
        let configuration = ProgressBarConfiguration(currentIndex: 2, total: 3)

        #expect(configuration.fraction == 1)
    }

    /// Guards against integer division: `1 / 3` would be `0`.
    @Test func fractionIsNotRoundedDown() {
        let configuration = ProgressBarConfiguration(currentIndex: 0, total: 3)

        #expect(abs(configuration.fraction - 1.0 / 3.0) < 0.0001)
    }

    @Test func emptyFlowHasZeroFractionWithoutCrashing() {
        let configuration = ProgressBarConfiguration(currentIndex: 0, total: 0)

        #expect(configuration.fraction == 0)
    }
}

@Suite("ProgressBarConfiguration edge cases")
struct ProgressBarConfigurationEdgeCaseTests {

    /// A one-step flow is already complete on its only step.
    @Test func singleStepFlowShowsFullBar() {
        let configuration = ProgressBarConfiguration(currentIndex: 0, total: 1)
        #expect(configuration.completedCount == 1)
        #expect(configuration.fraction == 1)
    }

    /// An index past the end (e.g. from a custom style preview) never overfills the bar.
    @Test(arguments: [3, 4, 100])
    func indexPastTheEndIsClamped(currentIndex: Int) {
        let configuration = ProgressBarConfiguration(currentIndex: currentIndex, total: 3)
        #expect(configuration.completedCount == 3)
        #expect(configuration.fraction == 1)
    }

    /// A negative index never produces negative progress.
    @Test(arguments: [-1, -5])
    func negativeIndexIsClamped(currentIndex: Int) {
        let configuration = ProgressBarConfiguration(currentIndex: currentIndex, total: 3)
        #expect(configuration.completedCount == 0)
        #expect(configuration.fraction == 0)
    }

    @Test func emptyFlowHasNoCompletedSegments() {
        let configuration = ProgressBarConfiguration(currentIndex: 0, total: 0)
        #expect(configuration.completedCount == 0)
    }

    /// Progress only grows as the flow moves forward.
    @Test func fractionGrowsMonotonically() {
        let fractions = (0..<10).map {
            ProgressBarConfiguration(currentIndex: $0, total: 10).fraction
        }
        #expect(fractions == fractions.sorted())
        #expect(Set(fractions).count == fractions.count)
    }
}
