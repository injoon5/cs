#if canImport(UIKit)
import SwiftUI

/// Scrubber, step back/forward, play/pause, speed and a frame counter. Plain buttons: these sit
/// inside content, not over it.
public struct PlaybackControls: View {
    @Bindable var player: ScenePlayer

    public init(player: ScenePlayer) {
        self.player = player
    }

    public var body: some View {
        VStack(spacing: 4) {
            Scrubber(player: player)
            HStack(spacing: 0) {
                speedMenu
                    .frame(maxWidth: .infinity, alignment: .leading)
                transport
                counter
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        // Inside a List row, borderless keeps each button's tap to itself.
        .buttonStyle(.borderless)
    }

    private var transport: some View {
        HStack(spacing: 8) {
            Button("Back", systemImage: "backward.frame.fill", action: player.stepBackward)
                .disabled(!player.canStepBackward)
            Button(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill", action: player.togglePlayback)
                .contentTransition(.symbolEffect(.replace))
                .font(.title2)
                .disabled(player.frameCount < 2)
            Button("Forward", systemImage: "forward.frame.fill", action: player.stepForward)
                .disabled(!player.canStepForward)
        }
        .labelStyle(.iconOnly)
        .imageScale(.large)
        .buttonStyle(TransportButtonStyle())
    }

    private var speedMenu: some View {
        Menu {
            Picker("Speed", selection: $player.speed) {
                ForEach(PlaybackSpeed.allCases) { speed in
                    Text(speed.label).tag(speed)
                }
            }
        } label: {
            Text(player.speed.label)
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(.rect)
        }
        .accessibilityLabel("Speed")
        .accessibilityValue(player.speed.label)
    }

    private var counter: some View {
        Text("\(min(player.currentIndex + 1, player.frameCount)) / \(player.frameCount)")
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
            .opacity(player.frameCount > 0 ? 1 : 0)
            .accessibilityLabel("Step \(player.currentIndex + 1) of \(player.frameCount)")
    }
}

/// A 44-point target around each icon, with the system's pressed and disabled looks.
private struct TransportButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(.rect)
            .foregroundStyle(isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

/// Dragging seeks without animation; the player pauses while the finger is down.
struct Scrubber: View {
    let player: ScenePlayer

    var body: some View {
        Slider(
            value: Binding(
                get: { Double(player.currentIndex) },
                set: { player.seek(to: Int($0.rounded())) }
            ),
            in: 0...Double(max(player.frameCount - 1, 1)),
            onEditingChanged: { editing in
                if editing { player.pause() }
            }
        )
        .disabled(player.frameCount < 2)
        .accessibilityLabel("Step")
        .accessibilityValue("\(player.currentIndex + 1) of \(player.frameCount)")
    }
}
#endif
