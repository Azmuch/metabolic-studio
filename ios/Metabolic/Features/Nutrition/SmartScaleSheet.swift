import SwiftUI
import MetabolicCore

/// Pair-and-weigh sheet for the Bluetooth food scale. Shows discovery when disconnected
/// and a live gram readout with tare once connected. When `onUseWeight` is provided
/// (from food-logging flows), a primary button hands the settled weight back to the caller.
struct SmartScaleSheet: View {
    var onUseWeight: ((Double) -> Void)?

    @Environment(SmartScaleService.self) private var scale
    @Environment(\.dismiss) private var dismiss

    init(onUseWeight: ((Double) -> Void)? = nil) {
        self.onUseWeight = onUseWeight
    }

    var body: some View {
        VStack(spacing: 20) {
            MTSheetHeader(title: "Smart scale")

            switch scale.state {
            case .connected:
                readout
            case .bluetoothUnavailable:
                MTEmptyState(symbol: "antenna.radiowaves.left.and.right.slash",
                             title: "Bluetooth unavailable",
                             message: "Turn on Bluetooth in Settings, or use the Demo Scale below.")
                deviceList
            default:
                MTEmptyState(symbol: "scalemass.fill",
                             title: "Pair your scale",
                             message: "Put your Bluetooth kitchen scale in pairing mode and pick it below.")
                deviceList
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(MTBackground().ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if scale.state == .idle { scale.startScanning() }
        }
        .onDisappear {
            scale.stopScanning()
        }
    }

    // MARK: - Connected readout

    private var readout: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                Circle()
                    .fill(scale.isStable ? MTTheme.volt : MTTheme.warning)
                    .frame(width: 8, height: 8)
                Text(scale.isStable ? "Stable" : "Settling…")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MTTheme.textSecondary)
                Text("·")
                    .foregroundStyle(MTTheme.textTertiary)
                Text(scale.connectedDevice?.name ?? "Scale")
                    .font(.system(size: 12))
                    .foregroundStyle(MTTheme.textTertiary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(weightText)
                    .font(MTTheme.numberFont(size: 64))
                    .foregroundStyle(MTTheme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: weightText)
                Text("g")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(MTTheme.textSecondary)
            }

            HStack(spacing: 10) {
                MTSecondaryButton(title: "Tare", systemImage: "arrow.counterclockwise") {
                    scale.tare()
                }
                MTSecondaryButton(title: "Disconnect") {
                    scale.disconnect()
                }
            }
            .padding(.horizontal, 20)

            if onUseWeight != nil {
                MTPrimaryButton(title: "Use \(weightText) g", systemImage: "checkmark") {
                    guard let grams = scale.grams, grams > 0 else {
                        Haptics.warning()
                        return
                    }
                    Haptics.success()
                    onUseWeight?(grams)
                    dismiss()
                }
                .padding(.horizontal, 20)
                .disabled(scale.grams == nil || (scale.grams ?? 0) <= 0)
            }
        }
        .padding(.top, 8)
    }

    private var weightText: String {
        guard let grams = scale.grams else { return "–" }
        return String(Int(grams.rounded()))
    }

    // MARK: - Discovery

    private var deviceList: some View {
        VStack(spacing: 10) {
            HStack {
                Text("NEARBY SCALES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                Spacer()
                if scale.state == .scanning {
                    ProgressView().controlSize(.small).tint(MTTheme.volt)
                }
            }

            ForEach(scale.discovered) { device in
                Button {
                    Haptics.tap()
                    scale.connect(device)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: device.isSimulated ? "sparkles" : "scalemass.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MTTheme.accentText)
                            .frame(width: 34, height: 34)
                            .background(MTTheme.voltDim, in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(device.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            Text(device.isSimulated ? "Try the flow without hardware" : "Bluetooth scale")
                                .font(.system(size: 12))
                                .foregroundStyle(MTTheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                        if scale.state == .connecting, scale.connectedDevice == device {
                            ProgressView().controlSize(.small).tint(MTTheme.volt)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MTTheme.textTertiary)
                        }
                    }
                    .padding(14)
                    .background(MTTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(MTTheme.stroke, lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    SmartScaleSheet()
        .environment(SmartScaleService())
}
