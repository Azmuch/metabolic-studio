import SwiftUI
import SwiftData
import UIKit
import MetabolicCore

/// Scan tab root: live barcode camera (with manual-entry fallback), free-tier scan limiting,
/// and a swipeable history of recent scans.
struct ScanTabView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanRecord.date, order: .reverse) private var recentScans: [ScanRecord]

    @State private var manualBarcode = ""
    @State private var showManualEntry = false
    @State private var isProcessing = false
    @State private var showLimitSheet = false
    @State private var showNotFound = false
    @State private var showResult = false
    @State private var showPaywall = false
    @State private var resultProduct: ScannedProduct?
    @State private var resultScore: ProductScore?
    @State private var lastAttemptedBarcode: String?

    private var freeTier: Bool { !FeatureGate.allows(.unlimitedScans, tier: subscriptionManager.tier) }
    private var cameraHeight: CGFloat { UIScreen.main.bounds.height * 0.55 }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    cameraRegion
                        .frame(height: cameraHeight)
                        .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 8, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    if BarcodeScannerView.isSupported && showManualEntry {
                        manualEntryField
                            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }

                    if freeTier {
                        HStack {
                            MTChip(text: "\(min(UsageMeter.scansToday(), 3)) of 3 free scans today", systemImage: "barcode.viewfinder")
                            Spacer()
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }

                Section {
                    if recentScans.isEmpty {
                        MTEmptyState(
                            symbol: "barcode.viewfinder",
                            title: "No scans yet",
                            message: "Scan a barcode to see its health score here."
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(recentScans) { record in
                            Button {
                                reopen(record)
                            } label: {
                                recentScanRow(record)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(record)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("RECENT SCANS")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MTTheme.textSecondary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(MTBackground())
            .navigationTitle("Scan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showManualEntry.toggle()
                    } label: {
                        Image(systemName: "keyboard")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                }
            }
            .overlay { if isProcessing { processingOverlay } }
            .sheet(isPresented: $showLimitSheet) { limitSheet }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showNotFound) { notFoundSheet }
            .sheet(isPresented: $showResult) {
                if let resultProduct, let resultScore {
                    ScanResultView(product: resultProduct, score: resultScore)
                }
            }
        }
    }

    // MARK: - Camera region

    @ViewBuilder
    private var cameraRegion: some View {
        ZStack {
            if BarcodeScannerView.isSupported {
                BarcodeScannerView(onScan: handleScan)
                viewfinderOverlay
            } else {
                unsupportedFallback
            }
        }
        .background(MTTheme.surface2)
    }

    private var viewfinderOverlay: some View {
        VStack {
            Spacer()
            MTChip(text: "Point at a barcode", systemImage: "viewfinder")
                .padding(.bottom, 16)
        }
        .overlay(cornerStrokes.padding(24))
        .allowsHitTesting(false)
    }

    private var cornerStrokes: some View {
        GeometryReader { geo in
            let length: CGFloat = 28
            Path { path in
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))

                path.move(to: CGPoint(x: geo.size.width - length, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width, y: length))

                path.move(to: CGPoint(x: geo.size.width, y: geo.size.height - length))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: geo.size.width - length, y: geo.size.height))

                path.move(to: CGPoint(x: length, y: geo.size.height))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height - length))
            }
            .stroke(MTTheme.volt, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }

    private var unsupportedFallback: some View {
        VStack(spacing: 16) {
            MTEmptyState(
                symbol: "camera.metering.unknown",
                title: "Camera Unavailable",
                message: "Enter a barcode manually to look up a product."
            )
            manualEntryField
        }
        .padding(20)
    }

    private var manualEntryField: some View {
        HStack(spacing: 10) {
            TextField("Enter barcode…", text: $manualBarcode)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(MTTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))

            Button {
                submitManualBarcode()
            } label: {
                Text("Go")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(MTTheme.volt)
                    .clipShape(Capsule())
            }
            .disabled(manualBarcode.isEmpty)
        }
    }

    // MARK: - Recent scans

    private func recentScanRow(_ record: ScanRecord) -> some View {
        MTCard {
            HStack(spacing: 14) {
                AsyncImage(url: record.imageURLString.flatMap { URL(string: $0) }) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(MTTheme.surface2)
                            Image(systemName: "barcode").foregroundStyle(MTTheme.textTertiary)
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(record.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                        .lineLimit(1)
                    Text(subtitleText(for: record))
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                ScoreBadge(score: record.scoreValue, rating: record.rating)
            }
        }
    }

    private func subtitleText(for record: ScanRecord) -> String {
        var parts: [String] = []
        if let brand = record.brand, !brand.isEmpty { parts.append(brand) }
        parts.append(record.date.formatted(.relative(presentation: .named)))
        return parts.joined(separator: " · ")
    }

    // MARK: - Sheets

    private var limitSheet: some View {
        VStack(spacing: 20) {
            MTSheetHeader(title: "Daily limit reached")
            Text("3 free scans a day")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
            MTPrimaryButton(title: "Go unlimited with Plus", systemImage: "bolt.fill") {
                showLimitSheet = false
                showPaywall = true
            }
            Text("or come back tomorrow")
                .font(.system(size: 13))
                .foregroundStyle(MTTheme.textTertiary)
        }
        .padding(20)
        .presentationDetents([.medium])
    }

    private var notFoundSheet: some View {
        VStack(spacing: 20) {
            MTSheetHeader(title: "Product not found")
            Text("We couldn't find a match for that barcode in Open Food Facts.")
                .font(.system(size: 14))
                .foregroundStyle(MTTheme.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                MTSecondaryButton(title: "Dismiss") { showNotFound = false }
                MTPrimaryButton(title: "Retry") {
                    showNotFound = false
                    if let barcode = lastAttemptedBarcode {
                        Task { await lookup(barcode: barcode) }
                    }
                }
            }
        }
        .padding(20)
        .presentationDetents([.height(260)])
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            ProgressView().tint(MTTheme.volt).scaleEffect(1.4)
        }
    }

    // MARK: - Actions

    private func handleScan(_ barcode: String) {
        guard !isProcessing else { return }
        Haptics.tap()

        if freeTier && UsageMeter.scansToday() >= 3 {
            showLimitSheet = true
            return
        }

        lastAttemptedBarcode = barcode
        Task { await lookup(barcode: barcode) }
    }

    private func submitManualBarcode() {
        let trimmed = manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        manualBarcode = ""
        showManualEntry = false
        hideKeyboard()
        handleScan(trimmed)
    }

    private func lookup(barcode: String) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            guard let product = try await OpenFoodFactsClient().product(barcode: barcode) else {
                showNotFound = true
                return
            }
            let score = ProductScoringEngine.score(product)
            UsageMeter.recordScan()
            modelContext.insert(ScanRecord(
                date: .now, barcode: product.barcode, name: product.name, brand: product.brand,
                scoreValue: score.value, rating: score.rating, imageURLString: product.imageURLString
            ))
            try? modelContext.save()
            resultProduct = product
            resultScore = score
            showResult = true
        } catch {
            showNotFound = true
        }
    }

    private func reopen(_ record: ScanRecord) {
        guard !isProcessing else { return }
        Task {
            isProcessing = true
            defer { isProcessing = false }
            guard let product = try? await OpenFoodFactsClient().product(barcode: record.barcode) else {
                showNotFound = true
                return
            }
            let score = ProductScoringEngine.score(product)
            resultProduct = product
            resultScore = score
            showResult = true
        }
    }

    private func delete(_ record: ScanRecord) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ScanTabView()
        .environment(SubscriptionManager())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
            inMemory: true
        )
}
