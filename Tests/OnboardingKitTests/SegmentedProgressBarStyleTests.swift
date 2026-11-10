//
//  SegmentedProgressBarStyleTests.swift
//  OnboardingKitTests
//

import SwiftUI
import Testing
@testable import OnboardingKit

@Suite("SegmentedProgressBarStyle")
struct SegmentedProgressBarStyleTests {

    private let configuration = ProgressBarConfiguration(currentIndex: 1, total: 3) // 2 of 3

    @Test func defaultStyleUsesDefaultColors() {
        let style: SegmentedProgressBarStyle = .segmented

        #expect(style.filledColor == ProgressBarDefaults.filledColor)
        #expect(style.emptyColor == ProgressBarDefaults.emptyColor)
    }

    @Test func customColorsAreApplied() {
        let style: SegmentedProgressBarStyle = .segmented(filledColor: .purple, emptyColor: .yellow)

        #expect(style.color(forSegment: 0, configuration: configuration) == .purple)
        #expect(style.color(forSegment: 1, configuration: configuration) == .purple)
        #expect(style.color(forSegment: 2, configuration: configuration) == .yellow)
    }

    /// Setting only one color keeps the other one at its default.
    @Test func settingOneColorKeepsTheOtherDefault() {
        let style: SegmentedProgressBarStyle = .segmented(filledColor: .purple)

        #expect(style.filledColor == .purple)
        #expect(style.emptyColor == ProgressBarDefaults.emptyColor)
    }

    /// Step N of M fills N segments, whatever the colors are.
    @Test func filledSegmentsFollowCompletedCount() {
        let style: SegmentedProgressBarStyle = .segmented(filledColor: .red, emptyColor: .blue)

        let colors = (0..<configuration.total).map {
            style.color(forSegment: $0, configuration: configuration)
        }

        #expect(colors == [.red, .red, .blue])
    }
}

@Suite("SegmentedProgressBarStyle edge cases")
struct SegmentedProgressBarStyleEdgeCaseTests {
    private let style: SegmentedProgressBarStyle = .segmented(filledColor: .red, emptyColor: .blue)

    private func colors(currentIndex: Int, total: Int) -> [Color] {
        let configuration = ProgressBarConfiguration(currentIndex: currentIndex, total: total)
        return (0..<total).map { style.color(forSegment: $0, configuration: configuration) }
    }

    @Test func firstStepFillsOnlyFirstSegment() {
        #expect(colors(currentIndex: 0, total: 4) == [.red, .blue, .blue, .blue])
    }

    @Test func lastStepFillsAllSegments() {
        #expect(colors(currentIndex: 3, total: 4) == [.red, .red, .red, .red])
    }

    @Test func singleStepFlowFillsItsOnlySegment() {
        #expect(colors(currentIndex: 0, total: 1) == [.red])
    }

    @Test func indexPastTheEndFillsAllSegments() {
        #expect(colors(currentIndex: 9, total: 3) == [.red, .red, .red])
    }

    /// An empty flow draws no segments and does not crash.
    @Test func emptyFlowBuildsBody() {
        _ = style.makeBody(configuration: .init(currentIndex: 0, total: 0))
    }

    /// Long flows keep exactly one filled segment per reached step.
    @Test func longFlowFillsReachedSteps() {
        let result = colors(currentIndex: 29, total: 50)
        #expect(result.filter { $0 == .red }.count == 30)
        #expect(result.prefix(30).allSatisfy { $0 == .red })
    }
}
