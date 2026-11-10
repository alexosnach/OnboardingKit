//
//  OnboardingNavigationPath.swift
//  OnboardingKit
//

/// Translates between the coordinator's state and the `NavigationStack` path.
///
/// The root of the stack is step `0`; the path holds the indices of the steps
/// shown above it, so `path.count == currentIndex` at all times.
///
/// Kept separate from ``OnboardingView`` so the mapping can be unit-tested
/// without UI. It contains no navigation rules: those live in the coordinator.
enum OnboardingNavigationPath {

    /// The path for the given current step: `0` → `[]`, `2` → `[1, 2]`.
    static func path(for currentIndex: Int) -> [Int] {
        Array(1..<(currentIndex + 1))
    }

    /// Moves the coordinator back until it matches a path written by `NavigationStack`.
    ///
    /// The back-button menu can pop several steps at once, so one `back()`
    /// is called per removed step. A longer path is ignored: moving forward
    /// happens only through the coordinator.
    static func apply(_ newPath: [Int], to coordinator: OnboardingCoordinator) {
        while coordinator.currentIndex > newPath.count {
            coordinator.back()
        }
    }
}
