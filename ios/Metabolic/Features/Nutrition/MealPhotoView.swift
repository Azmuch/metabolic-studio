import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import MetabolicCore

/// Photo tab of `AddFoodSheet`: gated behind Plus, lets the user snap or pick a meal photo,
/// sends it to `ClaudeVisionClient` for portion/calorie estimation, and logs the results.
struct MealPhotoView: View {
    let mealType: MealType

    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var pickedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var resultItems: [AnalyzedFoodItem]?
    @State private var analysisNotes: String?
    @State private var errorMessage: String?
    @State private var pulse = false

    init(mealType: MealType) {
        self.mealType = mealType
    }

    private var allowed: Bool {
        FeatureGate.allows(.aiPhotoAnalysis, tier: subscriptionManager.tier)
    }

    private var limitReached: Bool {
        subscriptionManager.tier == .plus && UsageMeter.aiAnalysesThisMonth() >= 30
    }

    private var totalCalories: Double { (resultItems ?? []).reduce(0) { $0 + $1.calories } }

    var body: some View {
        Group {
            if !allowed {
                lockedState
            } else if limitReached {
                limitReachedState
            } else if let errorMessage {
                errorState(errorMessage)
            } else if let resultItems {
                resultsState(resultItems)
            } else if isAnalyzing, let pickedImage {
                analyzingState(pickedImage)
            } else if let pickedImage {
                previewState(pickedImage)
            } else {
                pickerState
            }
        }
        .background(MTBackground())
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in pickedImage = image }
                .ignoresSafeArea()
        }
        .onChange(of: photosPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    pickedImage = uiImage
                }
            }
        }
    }

    // MARK: - Locked / limit states

    private var lockedState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(MTTheme.voltDim).frame(width: 88, height: 88)
                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(MTTheme.accentText)
            }
            VStack(spacing: 8) {
                Text("AI Calorie Vision")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MTTheme.textPrimary)
                Text("Snap a photo of your meal and let AI estimate portions, calories, and macros in seconds.")
                    .font(.system(size: 14))
                    .foregroundStyle(MTTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            MTChip(text: "Plus", systemImage: "lock.fill")
            Spacer()
            MTPrimaryButton(title: "Unlock with Plus") {
                showPaywall = true
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }

    private var limitReachedState: some View {
        VStack(spacing: 20) {
            Spacer()
            MTEmptyState(
                symbol: "hourglass",
                title: "Monthly limit reached",
                message: "You've used all 30 AI meal analyses this month on Plus. Upgrade to Pro for unlimited scans."
            )
            MTPrimaryButton(title: "Upgrade to Pro") {
                showPaywall = true
            }
            .padding(.horizontal, 20)
            Spacer()
        }
    }

    // MARK: - Picker / preview / analyzing states

    private var pickerState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                    .fill(MTTheme.surface2)
                    .frame(height: 220)
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(MTTheme.textTertiary)
                    Text("Add a photo of your meal")
                        .font(.system(size: 14))
                        .foregroundStyle(MTTheme.textSecondary)
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose Photo")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MTTheme.surface2)
                    .clipShape(Capsule())
                }

                Button {
                    Haptics.tap()
                    showCamera = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Camera")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MTTheme.surface2)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                .opacity(UIImagePickerController.isSourceTypeAvailable(.camera) ? 1 : 0.4)
            }
            .padding(.horizontal, 20)
            Spacer()
        }
    }

    @ViewBuilder
    private func previewState(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
                .clipped()
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Button {
                pickedImage = nil
            } label: {
                Text("Choose a different photo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MTTheme.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            MTPrimaryButton(title: "Analyze meal", systemImage: "sparkles") {
                analyze(image: image)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func analyzingState(_ image: UIImage) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
                    .clipped()
                    .opacity(0.35)

                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(MTTheme.accentText)
                        .scaleEffect(pulse ? 1.15 : 0.9)
                        .opacity(pulse ? 1 : 0.5)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                    Text("Estimating portions…")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .onAppear { pulse = true }
            .onDisappear { pulse = false }

            Spacer()
        }
    }

    // MARK: - Results / error states

    @ViewBuilder
    private func resultsState(_ items: [AnalyzedFoodItem]) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        analyzedRow(item)
                    }
                    if let analysisNotes, !analysisNotes.isEmpty {
                        Text(analysisNotes)
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textTertiary)
                            .padding(.top, 4)
                    }
                }
                .padding(20)
            }

            HStack {
                Text("Total")
                    .font(.system(size: 14))
                    .foregroundStyle(MTTheme.textSecondary)
                Spacer()
                Text("\(Int(totalCalories.rounded())) kcal")
                    .font(MTTheme.numberFont(size: 20))
                    .foregroundStyle(MTTheme.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            MTPrimaryButton(title: "Add \(items.count) item\(items.count == 1 ? "" : "s") to diary") {
                addAllToDiary()
            }
            .padding(20)
            .disabled(items.isEmpty)
            .opacity(items.isEmpty ? 0.4 : 1)
        }
    }

    private func analyzedRow(_ item: AnalyzedFoodItem) -> some View {
        MTCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("\(item.portionDescription) · \(Int(item.estimatedGrams)) g")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                    HStack(spacing: 8) {
                        confidenceChip(item.confidence)
                        Text("P \(Int(item.proteinG))g · C \(Int(item.carbsG))g · F \(Int(item.fatG))g")
                            .font(.system(size: 11))
                            .foregroundStyle(MTTheme.textTertiary)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 10) {
                    Text("\(Int(item.calories.rounded())) kcal")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            resultItems?.removeAll { $0.id == item.id }
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(MTTheme.danger)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func confidenceChip(_ confidence: Double) -> some View {
        let (label, color): (String, Color) = confidence > 0.75
            ? ("High", MTTheme.success)
            : confidence > 0.5 ? ("Med", MTTheme.warning) : ("Low", MTTheme.danger)
        return Text(label.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            MTEmptyState(symbol: "exclamationmark.triangle", title: "Couldn't analyze photo", message: message)
            MTPrimaryButton(title: "Try again") {
                errorMessage = nil
            }
            .padding(.horizontal, 20)
            Spacer()
        }
    }

    // MARK: - Analysis

    private func analyze(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        isAnalyzing = true
        errorMessage = nil
        Task {
            do {
                let result = try await ClaudeVisionClient().analyzeMeal(imageData: data)
                await MainActor.run {
                    resultItems = result.items
                    analysisNotes = result.notes
                    isAnalyzing = false
                }
            } catch MealVisionError.noAPIKey where appState.demoMode {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    resultItems = DemoMealAnalysis.sample.items
                    analysisNotes = DemoMealAnalysis.sample.notes
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = friendlyMessage(for: error)
                    isAnalyzing = false
                }
            }
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        if let visionError = error as? MealVisionError {
            switch visionError {
            case .noAPIKey:
                return "Add your Anthropic API key in Settings to use AI photo analysis, or enable demo mode to try a sample."
            case .badResponse:
                return "The AI service didn't respond. Check your connection and try again."
            case .decodingFailed:
                return "We couldn't read the AI's response. Please try again."
            }
        }
        return "Something went wrong analyzing this photo. Please try again."
    }

    private func addAllToDiary() {
        guard let resultItems else { return }
        for item in resultItems {
            let entry = FoodEntry(
                date: .now, mealType: mealType, name: item.name, brand: nil,
                calories: item.calories, proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG,
                grams: item.estimatedGrams, source: .photo
            )
            modelContext.insert(entry)
            Task { await healthKit.saveMeal(entry) }
        }
        UsageMeter.recordAIAnalysis()
        Haptics.success()
        dismiss()
    }
}

/// Minimal UIImagePickerController wrapper for taking a meal photo with the device camera.
struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    MealPhotoView(mealType: .dinner)
        .environment(AppState())
        .environment(SubscriptionManager())
        .environment(HealthKitService())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
            inMemory: true
        )
}
