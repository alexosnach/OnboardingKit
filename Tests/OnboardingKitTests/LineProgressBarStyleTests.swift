//
//  LineProgressBarStyleTests.swift
//  OnboardingKitTests
//

import SwiftUI
import Testing
@testable import OnboardingKit

@Suite("LineProgressBarStyle")
struct LineProgressBarStyleTests {

    @Test func defaultStyleUsesSharedDefaultColors() {
        let style: LineProgressBarStyle = .line

        #expect(style.filledColor == ProgressBarDefaults.filledColor)
        #expect(style.emptyColor == ProgressBarDefaults.emptyColor)
    }

    @Test func customColorsAreApplied() {
        let style: LineProgressBarStyle = .line(filledColor: .purple, emptyColor: .yellow)

        #expect(style.filledColor == .purple)
        #expect(style.emptyColor == .yellow)
    }

    @Test func settingOneColorKeepsTheOtherDefault() {
        let style: LineProgressBarStyle = .line(filledColor: .purple)

        #expect(style.emptyColor == ProgressBarDefaults.emptyColor)
    }

    /// Both built-in styles start from the same colors, so switching between them
    /// does not change the look of the app.
    @Test func lineAndSegmentedShareDefaults() {
        let line: LineProgressBarStyle = .line
        let segmented: SegmentedProgressBarStyle = .segmented

        #expect(line.filledColor == segmented.filledColor)
        #expect(line.emptyColor == segmented.emptyColor)
    }

    @Test func lineShorthandIsTheLineStyle() {
        let style: some ProgressBarStyle = .line

        #expect(style is LineProgressBarStyle)
    }
}
