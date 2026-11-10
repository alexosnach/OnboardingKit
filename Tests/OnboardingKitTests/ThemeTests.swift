//
//  ThemeTests.swift
//  OnboardingKitTests
//

import SwiftUI
import Testing
@testable import OnboardingKit

/// Resolves a color the way SwiftUI does for a screen in the given theme.
private func resolved(_ color: Color, in scheme: ColorScheme) -> Color.Resolved {
    var environment = EnvironmentValues()
    environment.colorScheme = scheme
    return color.resolve(in: environment)
}

@Suite("Light and dark appearance")
struct ThemeTests {

    @Test func adaptiveColorUsesLightVariantInLightMode() {
        let color = Color(light: .red, dark: .blue)
        #expect(resolved(color, in: .light) == resolved(.red, in: .light))
    }

    @Test func adaptiveColorUsesDarkVariantInDarkMode() {
        let color = Color(light: .red, dark: .blue)
        #expect(resolved(color, in: .dark) == resolved(.blue, in: .dark))
    }

    @Test func adaptiveColorDiffersBetweenThemes() {
        let color = Color(light: .black, dark: .white)
        #expect(resolved(color, in: .light) != resolved(color, in: .dark))
    }

    /// Same fixed color for both themes behaves like a plain color.
    /// (A fixed RGB color: system colors such as `.green` adapt on their own.)
    @Test func sameVariantsGiveTheSameColor() {
        let brand = Color(red: 0.1, green: 0.6, blue: 0.3)
        let color = Color(light: brand, dark: brand)
        #expect(resolved(color, in: .light) == resolved(color, in: .dark))
    }

    /// Variants can be adaptive themselves, e.g. a system color: the right
    /// variant of the inner color is used.
    @Test func nestedAdaptiveColorsResolvePerTheme() {
        let color = Color(light: .primary, dark: .primary)
        #expect(resolved(color, in: .light) == resolved(.primary, in: .light))
        #expect(resolved(color, in: .dark) == resolved(.primary, in: .dark))
    }

    @Test func opacityIsKeptPerTheme() {
        let color = Color(light: .black.opacity(0.1), dark: .white.opacity(0.2))
        #expect(abs(resolved(color, in: .light).opacity - 0.1) < 0.01)
        #expect(abs(resolved(color, in: .dark).opacity - 0.2) < 0.01)
    }

    // MARK: - Built-in styles

    /// The default empty track must stay visible on both backgrounds.
    @Test func defaultEmptyColorAdaptsToTheme() {
        #expect(resolved(ProgressBarDefaults.emptyColor, in: .light) != resolved(ProgressBarDefaults.emptyColor, in: .dark))
    }

    @Test func lineStyleKeepsAdaptiveColors() {
        let filled = Color(light: .indigo, dark: .mint)
        let style: LineProgressBarStyle = .line(filledColor: filled)
        #expect(resolved(style.filledColor, in: .light) == resolved(.indigo, in: .light))
        #expect(resolved(style.filledColor, in: .dark) == resolved(.mint, in: .dark))
    }

    @Test func segmentedStyleColorsSegmentsPerTheme() {
        let style: SegmentedProgressBarStyle = .segmented(
            filledColor: Color(light: .red, dark: .orange),
            emptyColor: Color(light: .gray, dark: .white)
        )
        let configuration = ProgressBarConfiguration(currentIndex: 0, total: 2)
        let filled = style.color(forSegment: 0, configuration: configuration)
        let empty = style.color(forSegment: 1, configuration: configuration)

        #expect(resolved(filled, in: .dark) == resolved(.orange, in: .dark))
        #expect(resolved(empty, in: .light) == resolved(.gray, in: .light))
    }

    /// Custom styles get adaptive colors through their own stored properties.
    @Test func customStyleCanCarryAdaptiveColors() {
        struct BrandSkipStyle: SkipButtonStyle {
            let color = Color(light: .purple, dark: .yellow)
            func makeBody(configuration: SkipButtonConfiguration) -> some View {
                Button("Skip", action: configuration.skip).foregroundStyle(color)
            }
        }
        let style = BrandSkipStyle()
        _ = AnySkipButtonStyle(style).makeBody(configuration: .init(skip: {}))
        #expect(resolved(style.color, in: .dark) == resolved(.yellow, in: .dark))
    }
}
