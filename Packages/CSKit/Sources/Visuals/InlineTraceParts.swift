#if canImport(UIKit)
import SwiftUI
import VisualsLayout

// Parts of `InlineTraceView`. Each takes small values for the current step; only the root reads
// the player's index.

/// The code, one fixed-height row per line, with one tint behind the current line. The tint is a
/// single view placed by line index, so it slides between lines under the step spring (and
/// crossfades under Reduce Motion). Long lines scroll sideways instead of wrapping, so the block
/// height never changes.
struct TraceCodeView: View, Equatable {
    let lines: [String]
    /// 0-based; negative for none.
    let current: Int
    let isError: Bool
    let lineHeight: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.current == rhs.current && lhs.isError == rhs.isError && lhs.lineHeight == rhs.lineHeight && lhs.lines == rhs.lines
    }

    private static let inset = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines.indices, id: \.self) { index in
                    Text(verbatim: lines[index].isEmpty ? " " : lines[index])
                        .lineLimit(1)
                        .fixedSize()
                        .frame(height: lineHeight)
                        .accessibilityAddTraits(index == current ? .isSelected : [])
                }
            }
            .font(CodeFont.text)
            .padding(Self.inset)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .scrollIndicators(.hidden)
        .background(alignment: .topLeading) {
            highlight
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: shape)
        .clipShape(shape)
    }

    private var highlight: some View {
        Rectangle()
            .fill(isError ? Color.red.opacity(0.16) : Color.accentColor.opacity(0.14))
            .frame(maxWidth: .infinity)
            .frame(height: lineHeight)
            .offset(y: Self.inset.top + CGFloat(max(current, 0)) * lineHeight)
            .opacity(current >= 0 && current < lines.count ? 1 : 0)
            // Under Reduce Motion each line gets its own tint, so a step crossfades.
            .id(reduceMotion ? current : -1)
            .transition(.opacity)
    }
}

/// Restart, back, play/pause, forward on the leading edge; speed and the step counter trailing.
/// Plain buttons: they sit inside lesson content.
struct TraceControls: View {
    @Bindable var player: ScenePlayer

    var body: some View {
        HStack(spacing: 0) {
            Button("Restart", systemImage: "arrow.counterclockwise", action: player.restart)
                .disabled(!player.canStepBackward)
            Button("Back", systemImage: "backward.frame.fill", action: player.stepBackward)
                .disabled(!player.canStepBackward)
            Button(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill", action: player.togglePlayback)
                .contentTransition(.symbolEffect(.replace))
                .disabled(player.frameCount < 2)
            Button("Forward", systemImage: "forward.frame.fill", action: player.stepForward)
                .disabled(!player.canStepForward)
            Spacer(minLength: 8)
            speedMenu
            counter
        }
        .labelStyle(.iconOnly)
        .buttonStyle(TransportButtonStyle())
        // Line the first icon up with the code text: the 44-point target overhangs to the left.
        .padding(.leading, 12 - 14)
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
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .menuStyle(.button)
        .buttonStyle(.borderless)
        .accessibilityLabel("Speed")
        .accessibilityValue(player.speed.label)
    }

    private var counter: some View {
        let total = player.frameCount
        let current = min(player.currentIndex + 1, total)
        // The widest count reserves the space, so nothing moves as digits are added.
        return ZStack(alignment: .trailing) {
            Text(verbatim: "\(total) / \(total)").hidden()
            Text(verbatim: "\(current) / \(total)")
                .contentTransition(.numericText(value: Double(current)))
        }
        .font(.subheadline)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .padding(.leading, 4)
        .opacity(total > 0 ? 1 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current) of \(total)")
    }
}

/// One chip per variable of the innermost frame. Every function's chips are laid out in the same
/// place and only the current one is visible, so the area is as tall as the tallest function for
/// the whole trace. Slots not yet assigned keep their place, faint.
struct TraceVariablesView: View {
    let model: InlineTraceModel
    let step: InlineTraceModel.Step
    let stepIndex: Int
    let arrays: [Int: SceneTimeline]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(model.groups) { group in
                let isCurrent = group.id == step.group
                FlowLayout(spacing: 6) {
                    if !group.isModule {
                        Text(verbatim: group.function)
                            .font(CodeFont.text.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                    ForEach(group.slots, id: \.self) { slotIndex in
                        item(slotIndex)
                    }
                }
                .opacity(isCurrent ? 1 : 0)
                .accessibilityHidden(!isCurrent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func item(_ slotIndex: Int) -> some View {
        let slot = model.slots[slotIndex]
        let value = slotIndex < step.values.count ? step.values[slotIndex] : nil
        let chip = VariableChip(name: slot.name, text: value?.text, widest: slot.widest, changed: value?.changed ?? false)
        if let timeline = arrays[slotIndex], !timeline.isEmpty {
            // A list too wide for a chip draws as an array: one size for the whole trace.
            let scene = timeline.scenes[min(stepIndex, timeline.scenes.count - 1)]
            ViewThatFits(in: .horizontal) {
                chip
                SceneView(scene: scene)
                ScrollView(.horizontal) {
                    SceneView(scene: scene)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                .scrollIndicators(.hidden)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(value.map { "\(slot.name), \($0.text)" } ?? "")
            .accessibilityHidden(value == nil)
        } else {
            chip
        }
    }
}

/// `name value` in SF Mono. The value reserves the width of the longest value it ever shows.
/// A value that changed on this step rolls with `numericText` and is tinted for the step.
struct VariableChip: View, Equatable {
    let name: String
    /// nil while the variable isn't assigned: the chip keeps its place, faint and without a value.
    let text: String?
    let widest: String
    let changed: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(verbatim: name)
                .foregroundStyle(.secondary)
            ZStack(alignment: .leading) {
                Text(verbatim: widest).hidden()
                Text(verbatim: text ?? "")
                    .contentTransition(.numericText())
            }
        }
        .font(CodeFont.text)
        .monospacedDigit()
        .lineLimit(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(changed ? Color.accentColor.opacity(0.18) : Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        // Not yet assigned: the name holds its place, faint, so the row isn't a blank gap.
        .opacity(text == nil ? 0.35 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(text ?? "")")
        .accessibilityHidden(text == nil)
    }
}

/// Printed output so far, in the console's font.
struct TraceOutputView: View, Equatable {
    let text: String
    let isError: Bool

    var body: some View {
        Text(verbatim: text)
            .font(CodeFont.text)
            .foregroundStyle(isError ? Color.red : Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityLabel("Output, \(text)")
    }
}

/// Left-to-right rows that wrap. Each item is offered the full row width, so a chip can choose
/// between its compact and wide forms with `ViewThatFits`.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let widest = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(width: bounds.width, subviews: subviews) {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y + (row.height - item.size.height) / 2),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private struct Row {
        var y: CGFloat
        var width: CGFloat = 0
        var height: CGFloat = 0
        var items: [(index: Int, x: CGFloat, size: CGSize)] = []
    }

    private func arrange(width: CGFloat?, subviews: Subviews) -> [Row] {
        let maxWidth = width ?? .infinity
        let offer = ProposedViewSize(width: width, height: nil)
        var rows: [Row] = []
        var row = Row(y: 0)
        for index in subviews.indices {
            var size = subviews[index].sizeThatFits(offer)
            size.width = min(size.width, maxWidth)
            let x = row.items.isEmpty ? 0 : row.width + spacing
            if !row.items.isEmpty && x + size.width > maxWidth {
                rows.append(row)
                row = Row(y: row.y + row.height + lineSpacing)
                row.items.append((index, 0, size))
                row.width = size.width
            } else {
                row.items.append((index, x, size))
                row.width = x + size.width
            }
            row.height = max(row.height, size.height)
        }
        if !row.items.isEmpty { rows.append(row) }
        return rows
    }
}
#endif
