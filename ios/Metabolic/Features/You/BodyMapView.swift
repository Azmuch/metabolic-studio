import SwiftUI
import MetabolicCore

/// Interactive front/back body diagram used to pick strength "target areas" and flag
/// deep-tissue / custom trouble spots. Presented as a sheet from onboarding's health-flags
/// step and from `ProfileEditorView`.
struct BodyMapView: View {
    @Binding var selectedAreas: Set<MuscleGroup>
    @Binding var customFlags: [String]

    @State private var customText = ""
    @State private var tappedLabel: String?
    @State private var labelTask: Task<Void, Never>?

    private let suggestions = ["Psoas", "Hip rotators", "Rotator cuff", "IT band", "Achilles"]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                MTSheetHeader(title: "Body map")

                Text("Tap the areas you want to strengthen, firm up, or focus on.")
                    .font(.system(size: 13))
                    .foregroundStyle(MTTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                diagrams

                customSection

                disclaimer
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(MTTheme.bg.ignoresSafeArea())
    }

    // MARK: - Diagrams

    private var diagrams: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 20) {
                figure(title: "FRONT") { frontFigure }
                figure(title: "BACK") { backFigure }
            }
            .padding(.top, 28)

            if let tappedLabel {
                Text(tappedLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(MTTheme.surface2, in: Capsule())
                    .overlay(Capsule().stroke(MTTheme.volt.opacity(0.5), lineWidth: 1))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: tappedLabel)
        .frame(maxWidth: .infinity)
    }

    private func figure(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(MTTheme.textTertiary)
            content()
        }
        .frame(maxWidth: .infinity)
    }

    private var frontFigure: some View {
        VStack(spacing: 4) {
            decorative(Circle(), width: 34, height: 34)
            decorative(Capsule(), width: 14, height: 10)

            HStack(spacing: 3) {
                region(Capsule(), group: .shoulders, label: "Shoulders", width: 24, height: 40)
                region(RoundedRectangle(cornerRadius: 14, style: .continuous), group: .chest,
                       label: "Chest", width: 46, height: 40)
                region(Capsule(), group: .shoulders, label: "Shoulders", width: 24, height: 40)
            }
            HStack(spacing: 3) {
                region(Capsule(), group: .arms, label: "Arms", width: 18, height: 66)
                region(RoundedRectangle(cornerRadius: 12, style: .continuous), group: .core,
                       label: "Core", width: 44, height: 66)
                region(Capsule(), group: .arms, label: "Arms", width: 18, height: 66)
            }
            HStack(spacing: 6) {
                region(Capsule(), group: .quads, label: "Quads", width: 32, height: 64)
                region(Capsule(), group: .quads, label: "Quads", width: 32, height: 64)
            }
            HStack(spacing: 6) {
                region(Capsule(), group: .calves, label: "Calves", width: 24, height: 48)
                region(Capsule(), group: .calves, label: "Calves", width: 24, height: 48)
            }
        }
    }

    private var backFigure: some View {
        VStack(spacing: 4) {
            decorative(Circle(), width: 34, height: 34)
            decorative(Capsule(), width: 14, height: 10)

            HStack(spacing: 3) {
                decorative(Capsule(), width: 18, height: 40)
                region(RoundedRectangle(cornerRadius: 14, style: .continuous), group: .back,
                       label: "Upper back", width: 46, height: 40)
                decorative(Capsule(), width: 18, height: 40)
            }
            region(RoundedRectangle(cornerRadius: 12, style: .continuous), group: .back,
                   label: "Lower back", width: 66, height: 44)
            region(RoundedRectangle(cornerRadius: 16, style: .continuous), group: .glutes,
                   label: "Glutes", width: 66, height: 34)
            HStack(spacing: 6) {
                region(Capsule(), group: .hamstrings, label: "Hamstrings", width: 32, height: 60)
                region(Capsule(), group: .hamstrings, label: "Hamstrings", width: 32, height: 60)
            }
            HStack(spacing: 6) {
                region(Capsule(), group: .calves, label: "Calves", width: 24, height: 48)
                region(Capsule(), group: .calves, label: "Calves", width: 24, height: 48)
            }
        }
    }

    /// A tappable body region that toggles membership of `group` in `selectedAreas`.
    private func region(_ shape: some Shape, group: MuscleGroup, label: String,
                        width: CGFloat, height: CGFloat) -> some View {
        let isSelected = selectedAreas.contains(group)
        return Button {
            toggle(group, label: label)
        } label: {
            shape
                .fill(isSelected ? MTTheme.volt.opacity(0.45) : MTTheme.surface2)
                .overlay(shape.stroke(isSelected ? MTTheme.volt : MTTheme.stroke, lineWidth: isSelected ? 1.5 : 1))
                .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
    }

    /// Non-interactive silhouette filler (head, neck, decorative back limbs).
    private func decorative(_ shape: some Shape, width: CGFloat, height: CGFloat) -> some View {
        shape
            .fill(MTTheme.surface2)
            .overlay(shape.stroke(MTTheme.stroke, lineWidth: 1))
            .frame(width: width, height: height)
    }

    private func toggle(_ group: MuscleGroup, label: String) {
        Haptics.tap()
        if selectedAreas.contains(group) {
            selectedAreas.remove(group)
        } else {
            selectedAreas.insert(group)
        }
        labelTask?.cancel()
        tappedLabel = label
        labelTask = Task {
            try? await Task.sleep(for: .seconds(1.1))
            guard !Task.isCancelled else { return }
            tappedLabel = nil
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

/// Simple wrapping chip row/grid used for suggestion + deletable-flag chips.
private struct WrapChips<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

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
