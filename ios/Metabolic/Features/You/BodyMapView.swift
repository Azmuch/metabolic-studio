import SwiftUI
import MetabolicCore

/// Interactive body map for picking strength "target areas" and flagging deep-tissue / custom
/// trouble spots. Presented as a sheet from onboarding's health-flags step and `ProfileEditorView`.
///
/// Speaks the app's hero language: an edge-to-edge 9:16 anatomical figure (the bundled écorché
/// stills) pinned to the top with tappable selection nodes over the muscles, a Front/Back toggle,
/// and the shared scrim carrying the selected areas — the custom-flags card scrolls beneath.
/// Falls back to the schematic vector figure until the anatomy images are bundled.
struct BodyMapView: View {
    @Binding var selectedAreas: Set<MuscleGroup>
    @Binding var customFlags: [String]

    @Environment(\.dismiss) private var dismiss

    @State private var side: BodySide = .front
    @State private var customText = ""
    @State private var tappedLabel: String?
    @State private var labelTask: Task<Void, Never>?

    private let suggestions = ["Psoas", "Hip rotators", "Rotator cuff", "IT band", "Achilles"]

    /// Fixed hero canvas color — matches the exercise heroes (light in both appearances).
    private let canvas = Color(red: 0.965, green: 0.965, blue: 0.957)

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroCard

                    VStack(alignment: .leading, spacing: 16) {
                        customSection
                        disclaimer
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            closeButton
                .padding(.leading, 16)
                .padding(.top, 8)
        }
        .overlay(alignment: .topTrailing) {
            sideToggle
                .padding(.trailing, 16)
                .padding(.top, 8)
        }
        .background(MTBackground().ignoresSafeArea())
    }

    // MARK: - Floating chrome (same treatment as the exercise detail screen)

    private var closeButton: some View {
        Button {
            Haptics.tap()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.32), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close body map")
    }

    private var sideToggle: some View {
        HStack(spacing: 0) {
            ForEach(BodySide.allCases, id: \.self) { option in
                Button {
                    Haptics.tap()
                    withAnimation(.snappy(duration: 0.25)) { side = option }
                } label: {
                    Text(option.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(side == option ? Color.black : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(side == option ? MTTheme.volt : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.black.opacity(0.32), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
    }

    // MARK: - Hero figure

    private var heroCard: some View {
        ZStack {
            canvas
            figureContent
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) { tapToast }
        .overlay(alignment: .bottom) { heroFooter }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 28,
                bottomTrailingRadius: 28, topTrailingRadius: 0, style: .continuous))
    }

    @ViewBuilder
    private var figureContent: some View {
        if let figure = UIImage(named: side == .front ? "anatomy.body.front" : "anatomy.body.back") {
            Image(uiImage: figure)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.top, 44)          // clears the floating chrome
                .padding(.bottom, 96)       // clears the scrim footer
                .overlay { nodeOverlay }
        } else {
            schematicFallback
                .padding(.top, 72)
                .padding(.bottom, 120)
                .overlay { nodeOverlay }
        }
    }

    /// Selection nodes positioned in coordinates normalized to the figure's fitted bounds.
    private var nodeOverlay: some View {
        GeometryReader { geo in
            ForEach(side.nodes) { node in
                nodeButton(node)
                    .position(x: geo.size.width * node.x, y: geo.size.height * node.y)
            }
        }
    }

    private func nodeButton(_ node: MapNode) -> some View {
        let isSelected = selectedAreas.contains(node.group)
        return Button {
            toggle(node.group, label: node.label)
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? MTTheme.volt : Color.white.opacity(0.78))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(
                        isSelected ? Color.black.opacity(0.25) : Color.black.opacity(0.12),
                        lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? Color.black : Color(white: 0.35))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(node.label)\(isSelected ? ", selected" : "")")
    }

    /// Momentary label naming the region just tapped.
    @ViewBuilder
    private var tapToast: some View {
        if let tappedLabel {
            Text(tappedLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(white: 0.12))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.85), in: Capsule())
                .overlay(Capsule().stroke(MTTheme.volt.opacity(0.6), lineWidth: 1))
                .padding(.top, 64)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    /// Shared scrim footer: instruction + the currently selected areas as ink pills.
    private var heroFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedAreas.isEmpty
                 ? "Tap the nodes on the figure to strengthen, firm up, or focus an area."
                 : "FOCUS AREAS")
                .font(.system(size: selectedAreas.isEmpty ? 13 : 11,
                              weight: .semibold))
                .tracking(selectedAreas.isEmpty ? 0 : 1.2)
                .foregroundStyle(Color(white: 0.3))
            if !selectedAreas.isEmpty {
                WrapChips(items: sortedSelection) { group in
                    Button {
                        toggle(group, label: group.displayName)
                    } label: {
                        HStack(spacing: 5) {
                            Text(group.displayName)
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(white: 0.22))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.8), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .padding(.top, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MTHeroScrim())
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedAreas)
    }

    private var sortedSelection: [MuscleGroup] {
        MuscleGroup.allCases.filter { selectedAreas.contains($0) }
    }

    private func toggle(_ group: MuscleGroup, label: String) {
        Haptics.tap()
        if selectedAreas.contains(group) {
            selectedAreas.remove(group)
        } else {
            selectedAreas.insert(group)
        }
        labelTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { tappedLabel = label }
        labelTask = Task {
            try? await Task.sleep(for: .seconds(1.1))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { tappedLabel = nil }
        }
    }

    // MARK: - Schematic fallback (until anatomy stills are bundled)

    /// A neutral capsule silhouette so the node layer still reads against something figure-shaped.
    private var schematicFallback: some View {
        VStack(spacing: 5) {
            Circle().fill(MTTheme.surface2).frame(width: 44, height: 44)
            Capsule().fill(MTTheme.surface2).frame(width: 18, height: 12)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(MTTheme.surface2)
                .frame(width: 110, height: 150)
            HStack(spacing: 10) {
                Capsule().fill(MTTheme.surface2).frame(width: 34, height: 130)
                Capsule().fill(MTTheme.surface2).frame(width: 34, height: 130)
            }
        }
    }

    // MARK: - Custom flags

    private var customSection: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("DEEP TISSUE & CUSTOM AREAS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)

                HStack(spacing: 10) {
                    TextField("e.g. Left knee ITB", text: $customText)
                        .font(.system(size: 15))
                        .foregroundStyle(MTTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
                    Button {
                        addCustomFlag(customText)
                        customText = ""
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .frame(width: 40, height: 40)
                            .background(MTTheme.volt, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                WrapChips(items: suggestions) { suggestion in
                    Button {
                        addCustomFlag(suggestion)
                    } label: {
                        MTChip(text: suggestion, systemImage: "plus",
                               isActive: customFlags.contains(suggestion))
                    }
                    .buttonStyle(.plain)
                }

                if !customFlags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FLAGGED")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(MTTheme.textTertiary)
                        WrapChips(items: customFlags) { flag in
                            Button {
                                Haptics.tap()
                                customFlags.removeAll { $0 == flag }
                            } label: {
                                MTChip(text: flag, systemImage: "xmark", isActive: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func addCustomFlag(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !customFlags.contains(trimmed) else { return }
        Haptics.tap()
        customFlags.append(trimmed)
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 11))
            Text("For pre-existing conditions — or any flagged area that has persisted 3 months or more — consult a physician or physical therapist before training it.")
                .font(.system(size: 11))
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(MTTheme.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Sides & nodes

/// Which face of the figure is shown; each carries its tappable muscle nodes in coordinates
/// normalized to the figure's fitted bounds (0...1 on both axes).
private enum BodySide: CaseIterable {
    case front, back

    var title: String {
        switch self {
        case .front: return "Front"
        case .back: return "Back"
        }
    }

    var nodes: [MapNode] {
        switch self {
        case .front:
            return [
                MapNode(group: .shoulders, label: "Shoulders", x: 0.30, y: 0.20),
                MapNode(group: .shoulders, label: "Shoulders", x: 0.70, y: 0.20),
                MapNode(group: .chest, label: "Chest", x: 0.50, y: 0.25),
                MapNode(group: .arms, label: "Arms", x: 0.19, y: 0.37),
                MapNode(group: .arms, label: "Arms", x: 0.81, y: 0.37),
                MapNode(group: .core, label: "Core", x: 0.50, y: 0.40),
                MapNode(group: .quads, label: "Quads", x: 0.40, y: 0.60),
                MapNode(group: .quads, label: "Quads", x: 0.60, y: 0.60),
                MapNode(group: .calves, label: "Calves", x: 0.42, y: 0.82),
                MapNode(group: .calves, label: "Calves", x: 0.58, y: 0.82),
            ]
        case .back:
            return [
                MapNode(group: .shoulders, label: "Rear Shoulders", x: 0.30, y: 0.20),
                MapNode(group: .shoulders, label: "Rear Shoulders", x: 0.70, y: 0.20),
                MapNode(group: .back, label: "Upper Back", x: 0.50, y: 0.26),
                MapNode(group: .arms, label: "Arms", x: 0.19, y: 0.37),
                MapNode(group: .arms, label: "Arms", x: 0.81, y: 0.37),
                MapNode(group: .back, label: "Lower Back", x: 0.50, y: 0.42),
                MapNode(group: .glutes, label: "Glutes", x: 0.50, y: 0.51),
                MapNode(group: .hamstrings, label: "Hamstrings", x: 0.41, y: 0.64),
                MapNode(group: .hamstrings, label: "Hamstrings", x: 0.59, y: 0.64),
                MapNode(group: .calves, label: "Calves", x: 0.42, y: 0.82),
                MapNode(group: .calves, label: "Calves", x: 0.58, y: 0.82),
            ]
        }
    }
}

private struct MapNode: Identifiable {
    let group: MuscleGroup
    let label: String
    let x: CGFloat
    let y: CGFloat
    var id: String { "\(group.rawValue)-\(x)-\(y)" }
}

/// Simple wrapping chip row/grid used for selection, suggestion, and deletable-flag chips.
private struct WrapChips<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}

private struct BodyMapPreviewHost: View {
    @State private var selected: Set<MuscleGroup> = [.chest, .quads]
    @State private var flags: [String] = ["Psoas"]

    var body: some View {
        BodyMapView(selectedAreas: $selected, customFlags: $flags)
    }
}

#Preview {
    BodyMapPreviewHost()
}
