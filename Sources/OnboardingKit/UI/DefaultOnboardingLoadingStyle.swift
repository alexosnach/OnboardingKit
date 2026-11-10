//
//  DefaultOnboardingLoadingStyle.swift
//  OnboardingKit
//

import SwiftUI

/// The default loading screen: a system activity indicator in the center,
/// on the system background, edge to edge.
public struct DefaultOnboardingLoadingStyle: OnboardingLoadingStyle {
    public init() {}

    public func makeBody(configuration: OnboardingLoadingConfiguration) -> some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
}

extension OnboardingLoadingStyle where Self == DefaultOnboardingLoadingStyle {
    /// The default loading screen: a system activity indicator on the system background.
    public static var automatic: Self { .init() }
}

#Preview("Automatic") {
    let style: some OnboardingLoadingStyle = .automatic

    style.makeBody(configuration: .init())
}

#Preview("Custom") {
    struct PreparingPlanStyle: OnboardingLoadingStyle {
        func makeBody(configuration: OnboardingLoadingConfiguration) -> some View {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                ProgressView()
                Text("Loading...", bundle: .module)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
        }
    }

    return EnvironmentReader()
        .onboardingLoadingStyle(PreparingPlanStyle())
}

/// Draws whatever loading style the environment holds, the way the onboarding will.
private struct EnvironmentReader: View {
    @Environment(\.onboardingLoadingStyle) private var style

    var body: some View {
        style.makeBody(configuration: .init())
    }
}
