#if canImport(UIKit)
import Observation
import SwiftUI

public enum PlaybackSpeed: Double, CaseIterable, Identifiable, Sendable {
    case half = 0.5
    case normal = 1
    case double = 2

    public var id: Double { rawValue }

    public var label: String {
        switch self {
        case .half: "0.5×"
        case .normal: "1×"
        case .double: "2×"
        }
    }
}

/// Drives a run of cached scenes. Only the diagram root and the controls read `currentIndex`.
///
/// Stepping and playing change the index inside a spring; scrubbing changes it with animations
/// disabled. Springs are interruptible, so fast taps retarget instead of queueing.
@MainActor
@Observable
public final class ScenePlayer {
    public private(set) var frameCount: Int
    public private(set) var currentIndex = 0
    public private(set) var isPlaying = false
    public var speed: PlaybackSpeed = .normal
    /// Set from the environment by the view that owns the player.
    public var reduceMotion = false

    @ObservationIgnored private var playback: Task<Void, Never>?

    /// Time on each frame at 1×.
    private static let interval: Duration = .milliseconds(900)

    public init(frameCount: Int = 0) {
        self.frameCount = frameCount
    }

    public var canStepBackward: Bool { currentIndex > 0 }
    public var canStepForward: Bool { currentIndex < frameCount - 1 }

    /// Moves are crossfades under Reduce Motion (see `SceneView`), so a gentle, non-bouncy spring.
    var stepAnimation: Animation {
        reduceMotion ? .smooth(duration: 0.3) : .spring(duration: 0.45, bounce: 0.12)
    }

    public func setFrameCount(_ count: Int) {
        frameCount = max(count, 0)
        if currentIndex >= frameCount { seek(to: max(frameCount - 1, 0)) }
        if frameCount < 2 { pause() }
    }

    public func stepForward() {
        pause()
        advance()
    }

    public func stepBackward() {
        pause()
        guard canStepBackward else { return }
        withAnimation(stepAnimation) { currentIndex -= 1 }
    }

    /// For scrubbing: no animation, so the scene tracks the finger.
    public func seek(to index: Int) {
        let clamped = min(max(index, 0), max(frameCount - 1, 0))
        guard clamped != currentIndex else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { currentIndex = clamped }
    }

    public func togglePlayback() {
        isPlaying ? pause() : play()
    }

    public func play() {
        guard frameCount > 1 else { return }
        // From the end, start over and hold the first frame; otherwise move right away.
        let restarted = !canStepForward
        if restarted { seek(to: 0) }
        isPlaying = true
        playback?.cancel()
        playback = Task { [weak self] in
            var shouldWait = restarted
            while !Task.isCancelled {
                if shouldWait {
                    let speed = self?.speed.rawValue ?? 1
                    try? await Task.sleep(for: Self.interval / speed)
                }
                shouldWait = true
                guard let self, self.isPlaying, !Task.isCancelled else { return }
                self.advance()
                if !self.canStepForward {
                    self.isPlaying = false
                    return
                }
            }
        }
    }

    public func pause() {
        isPlaying = false
        playback?.cancel()
        playback = nil
    }

    private func advance() {
        guard canStepForward else { return }
        withAnimation(stepAnimation) { currentIndex += 1 }
    }
}
#endif
