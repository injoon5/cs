#if canImport(UIKit)
import Contracts
import SwiftUI
import VisualsLayout

/// A run of `viz` frames with playback controls. Lays out once per run (and per Dynamic Type
/// size) off the main actor; playing and scrubbing just pick a cached scene.
public struct VizPlayerView: View {
    let frames: [VizFrame]
    let startIndex: Int

    @State private var timeline: SceneTimeline?
    @State private var player = ScenePlayer()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `startAt` opens on a later frame, e.g. when expanding an inline player at its current step.
    public init(frames: [VizFrame], startAt startIndex: Int = 0) {
        self.frames = frames
        self.startIndex = startIndex
    }

    public var body: some View {
        VStack(spacing: 8) {
            if let timeline {
                SceneStage(timeline: timeline, player: player)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 88)
            }
            PlaybackControls(player: player)
        }
        .task(id: dynamicTypeSize) {
            let metrics = LayoutMetrics.system(dynamicTypeSize)
            let frames = frames
            let laidOut = await Task.detached(priority: .userInitiated) {
                SceneLayoutEngine.layout(frames, metrics: metrics)
            }.value
            let isFirstLayout = timeline == nil
            timeline = laidOut
            player.setFrameCount(laidOut.scenes.count)
            if isFirstLayout { player.seek(to: startIndex) }
        }
        .onChange(of: reduceMotion, initial: true) {
            player.reduceMotion = reduceMotion
        }
        .onDisappear { player.pause() }
    }
}

/// The only view that reads `currentIndex` for drawing. Wide scenes scroll sideways instead of
/// shrinking, so cells keep their size.
struct SceneStage: View {
    let timeline: SceneTimeline
    let player: ScenePlayer

    var body: some View {
        let index = min(max(player.currentIndex, 0), max(timeline.scenes.count - 1, 0))
        let scene = timeline.scenes.isEmpty ? SceneLayout(size: .zero, shapes: []) : timeline.scenes[index]
        VStack(spacing: 8) {
            ViewThatFits(in: .horizontal) {
                SceneView(scene: scene)
                ScrollView(.horizontal) {
                    SceneView(scene: scene)
                }
                .scrollIndicators(.hidden)
            }
            .frame(maxWidth: .infinity)
            if hasNotes {
                // Always one line tall, so the controls don't jump when a note comes and goes.
                Text(scene.note ?? " ")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
        }
    }

    private var hasNotes: Bool {
        timeline.scenes.contains { $0.note != nil }
    }
}
#endif
