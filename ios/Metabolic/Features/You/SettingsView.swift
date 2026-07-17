import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import MetabolicCore

/// Settings: AI key, demo mode, smart scale, data export (Pro), about.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(SmartScaleService.self) private var scale
    @Environment(\.modelContext) private var modelContext

    @Query private var foods: [FoodEntry]
    @Query private var workouts: [WorkoutLog]
    @Query private var weights: [WeightEntry]

    @State private var apiKeyField = ""
    @State private var hasStoredKey = APIKeyStore.load() != nil
    @State private var exportURL: URL?
    @State private var showPaywall = false
    @State private var showScaleSheet = false
    @State private var wallpaperPickerItem: PhotosPickerItem?

    var body: some View {
        @Bindable var appState = appState

        ScrollView {
            VStack(spacing: 12) {
                section("Appearance") {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Appearance", selection: $appState.appearanceMode) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Divider().overlay(MTTheme.stroke)

                        HStack(spacing: 10) {
                            ForEach(AccentTheme.allCases, id: \.self) { theme in
                                accentCard(theme, selection: $appState.accentTheme)
                            }
                        }

                        Divider().overlay(MTTheme.stroke)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Background")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            HStack(spacing: 10) {
                                ForEach(BackgroundStyle.allCases, id: \.self) { style in
                                    backgroundCard(style, selection: $appState.backgroundStyle)
                                }
                            }
                            Text("Liquid Glass and Photo use translucent cards.")
                                .font(.system(size: 12))
                                .foregroundStyle(MTTheme.textTertiary)

                            if appState.backgroundStyle == .photo {
                                VStack(alignment: .leading, spacing: 10) {
                                    if !WallpaperCatalog.available.isEmpty {
                                        ScrollView(.horizontal) {
                                            HStack(spacing: 10) {
                                                ForEach(WallpaperCatalog.available, id: \.self) { presetID in
                                                    wallpaperPresetTile(presetID)
                                                }
                                            }
                                        }
                                        .scrollIndicators(.hidden)
                                    }

                                    PhotosPicker(selection: $wallpaperPickerItem, matching: .images) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(MTTheme.volt)
                                                .frame(width: 36, height: 36)
                                                .background(MTTheme.voltDim, in: RoundedRectangle(cornerRadius: 10))
                                            Text("Use your own photo…")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(MTTheme.textPrimary)
                                            Spacer(minLength: 0)
                                        }
                                        .contentShape(Rectangle())
                                    }

                                    Toggle(isOn: $appState.wallpaperParallax) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("3D parallax")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(MTTheme.textPrimary)
                                            Text("The wallpaper drifts subtly as you tilt your phone. Pauses automatically with Reduce Motion.")
                                                .font(.system(size: 12))
                                                .foregroundStyle(MTTheme.textSecondary)
                                        }
                                    }
                                    .tint(MTTheme.volt)

                                    if ThemeStore.shared.hasWallpaper && appState.wallpaperPresetID == nil {
                                        MTSecondaryButton(title: "Remove wallpaper") {
                                            appState.clearWallpaper()
                                        }
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity
                                ))
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appState.backgroundStyle)

                        Divider().overlay(MTTheme.stroke)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Units")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            Picker("Units", selection: $appState.unitSystem) {
                                ForEach(UnitSystem.allCases, id: \.self) { system in
                                    Text(system.displayName).tag(system)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Divider().overlay(MTTheme.stroke)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Figure style")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            HStack(spacing: 10) {
                                ForEach(ClipStyle.allCases, id: \.self) { style in
                                    figureStyleCard(style, selection: $appState.clipStyle)
                                }
                            }
                            Text("Anatomy ships built-in. Other packs fall back to Anatomy for any exercise they don't include yet.")
                                .font(.system(size: 12))
                                .foregroundStyle(MTTheme.textTertiary)
                        }
                    }
                }

                section("AI Calorie Vision") {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField(hasStoredKey ? "••••••••••••  (key saved)" : "Anthropic API key",
                                    text: $apiKeyField)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14).monospaced())
                            .foregroundStyle(MTTheme.textPrimary)
                            .padding(12)
                            .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
                        HStack(spacing: 10) {
                            MTSecondaryButton(title: "Save key") {
                                let trimmed = apiKeyField.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                APIKeyStore.save(trimmed)
                                apiKeyField = ""
                                hasStoredKey = true
                                Haptics.success()
                            }
                            if hasStoredKey {
                                MTSecondaryButton(title: "Clear") {
                                    APIKeyStore.clear()
                                    hasStoredKey = false
                                }
                            }
                        }
                        Text("Meal-photo analysis calls the Claude API with your key, straight from the device.")
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textTertiary)
                    }
                }

                section("Demo mode") {
                    Toggle(isOn: $appState.demoMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Demo mode")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            Text("Sample data and canned AI results for exploring the app.")
                                .font(.system(size: 12))
                                .foregroundStyle(MTTheme.textSecondary)
                        }
                    }
                    .tint(MTTheme.volt)
                }

                section("Devices") {
                    Button {
                        Haptics.tap()
                        showScaleSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.volt)
                                .symbolEffect(.pulse)
                                .frame(width: 36, height: 36)
                                .background(MTTheme.voltDim, in: RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smart food scale")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(MTTheme.textPrimary)
                                Text(scale.statusDescription)
                                    .font(.system(size: 12))
                                    .foregroundStyle(MTTheme.textSecondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MTTheme.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Text("Pair a Bluetooth kitchen scale to weigh portions straight into your diary.")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textTertiary)
                }

                section("Data") {
                    if FeatureGate.allows(.dataExport, tier: subscriptionManager.tier) {
                        if let exportURL {
                            ShareLink(item: exportURL) {
                                exportRow(caption: "metabolic-export.csv ready — tap to share")
                            }
                        } else {
                            Button {
                                Haptics.tap()
                                exportURL = CSVExporter.export(foods: foods, workouts: workouts,
                                                               weights: weights)
                                if exportURL != nil { Haptics.success() }
                            } label: {
                                exportRow(caption: "Foods, workouts and weights as CSV")
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button {
                            Haptics.tap()
                            showPaywall = true
                        } label: {
                            HStack {
                                exportRow(caption: "Foods, workouts and weights as CSV")
                                MTChip(text: "Pro", systemImage: "lock.fill")
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                section("About") {
                    HStack {
                        Text("Version")
                            .font(.system(size: 15))
                            .foregroundStyle(MTTheme.textSecondary)
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                            .font(.system(size: 15, weight: .semibold).monospacedDigit())
                            .foregroundStyle(MTTheme.textPrimary)
                    }
                    Link(destination: URL(string: "mailto:hello@metabolicstudio.app")!) {
                        HStack {
                            Text("Contact")
                                .font(.system(size: 15))
                                .foregroundStyle(MTTheme.textSecondary)
                            Spacer()
                            Text("hello@metabolicstudio.app")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(MTTheme.volt)
                        }
                    }
                    Text("Nutrition math, plan generation and product scoring run on-device in MetabolicCore.")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .background(MTBackground().ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showScaleSheet) { SmartScaleSheet() }
        .onChange(of: wallpaperPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data),
                      let downscaled = uiImage.downscaled(maxDimension: 1600),
                      let jpegData = downscaled.jpegData(compressionQuality: 0.8)
                else { return }
                appState.setWallpaper(jpegData)
                Haptics.success()
            }
        }
    }

    private func exportRow(caption: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MTTheme.volt)
                .frame(width: 36, height: 36)
                .background(MTTheme.voltDim, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("Export data (CSV)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                Text(caption)
                    .font(.system(size: 12))
                    .foregroundStyle(MTTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    /// One bundled wallpaper thumbnail — tap to select, tap again to deselect (falls back to
    /// the user's uploaded photo, if any).
    private func wallpaperPresetTile(_ presetID: String) -> some View {
        let selected = appState.wallpaperPresetID == presetID
        return Button {
            Haptics.tap()
            appState.wallpaperPresetID = selected ? nil : presetID
        } label: {
            Group {
                if let image = UIImage(named: presetID) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    MTTheme.surface2
                }
            }
            .frame(width: 64, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? MTTheme.volt : MTTheme.stroke, lineWidth: selected ? 2 : 1))
            .overlay(alignment: .bottomTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                        .padding(5)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Wallpaper preset\(selected ? ", selected" : "")")
    }

    private func accentCard(_ theme: AccentTheme, selection: Binding<AccentTheme>) -> some View {
        let selected = selection.wrappedValue == theme
        return Button {
            Haptics.tap()
            selection.wrappedValue = theme
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(accentColor(for: theme))
                    .frame(width: 26, height: 26)
                Text(theme.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.controlRadius)
                    .stroke(selected ? MTTheme.volt : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func backgroundCard(_ style: BackgroundStyle, selection: Binding<BackgroundStyle>) -> some View {
        let selected = selection.wrappedValue == style
        return Button {
            Haptics.tap()
            selection.wrappedValue = style
        } label: {
            VStack(spacing: 8) {
                Image(systemName: style.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selected ? MTTheme.volt : MTTheme.textSecondary)
                    .frame(height: 22)
                Text(style.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? MTTheme.voltDim : MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.controlRadius)
                    .stroke(selected ? MTTheme.volt : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func figureStyleCard(_ style: ClipStyle, selection: Binding<ClipStyle>) -> some View {
        let selected = selection.wrappedValue == style
        return Button {
            Haptics.tap()
            selection.wrappedValue = style
        } label: {
            VStack(spacing: 8) {
                Image(systemName: style.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selected ? MTTheme.volt : MTTheme.textSecondary)
                    .frame(height: 22)
                Text(style.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? MTTheme.voltDim : MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.controlRadius)
                    .stroke(selected ? MTTheme.volt : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    /// Same palette `MTTheme` resolves `AccentTheme` to — mirrored here for the swatch dots.
    private func accentColor(for theme: AccentTheme) -> Color {
        switch theme {
        case .volt: return Color(hex: 0xC8F542)
        case .tangerine: return Color(hex: 0xFF9F45)
        case .earth: return Color(hex: 0xC9A57B)
        case .jewel: return Color(hex: 0x45D6C6)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        MTCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(AppState())
        .environment(SubscriptionManager())
        .environment(SmartScaleService())
        .modelContainer(for: [FoodEntry.self, WorkoutLog.self, WeightEntry.self], inMemory: true)
}

fileprivate extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

fileprivate extension UIImage {
    /// Resizes so the longest side is at most `maxDimension`, preserving aspect ratio.
    /// Returns `self` unchanged if it's already within bounds.
    func downscaled(maxDimension: CGFloat) -> UIImage? {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
