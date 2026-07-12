import SwiftUI

/// Reorder / show-hide sheet for the Today dashboard, gated behind Plus.
struct DashboardEditSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if FeatureGate.allows(.dashboardCustomize, tier: subscriptionManager.tier) {
                    editor
                } else {
                    locked
                }
            }
            .background(MTBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MTTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var editor: some View {
        VStack(spacing: 0) {
            MTSheetHeader(title: "Customize Today")
                .padding(.bottom, 8)

            List {
                ForEach(appState.dashboardLayout) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.kind.symbolName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(MTTheme.textSecondary)
                            .frame(width: 24)
                        Text(item.kind.title)
                            .font(.system(size: 16))
                            .foregroundStyle(MTTheme.textPrimary)
                        Spacer()
                        Toggle("", isOn: binding(for: item.kind))
                            .labelsHidden()
                            .tint(MTTheme.volt)
                    }
                    .listRowBackground(MTTheme.surface)
                }
                .onMove { indices, newOffset in
                    appState.dashboardLayout.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
        }
    }

    private func binding(for kind: DashboardWidgetKind) -> Binding<Bool> {
        Binding(
            get: { appState.dashboardLayout.first(where: { $0.kind == kind })?.isVisible ?? true },
            set: { newValue in
                if let index = appState.dashboardLayout.firstIndex(where: { $0.kind == kind }) {
                    appState.dashboardLayout[index].isVisible = newValue
                }
            }
        )
    }

    private var locked: some View {
        VStack(spacing: 24) {
            Spacer()
            MTEmptyState(
                symbol: "lock.fill",
                title: "Make Today yours",
                message: "Reorder and hide widgets to build a dashboard that fits your routine — unlock with Plus."
            )
            MTPrimaryButton(title: "Unlock with Plus") {
                showPaywall = true
            }
            .padding(.horizontal, 20)
            Spacer()
        }
    }
}

#Preview {
    DashboardEditSheet()
        .environment(AppState())
        .environment(SubscriptionManager())
}
