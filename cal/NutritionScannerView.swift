import SwiftUI
import SwiftData
import UIKit
import Vision

// All FoodEntry keys that the app tracks
private let trackedKeys: Set<String> = [
    "calories", "totalFat", "saturatedFat", "transFat", "polyunsaturatedFat",
    "monounsaturatedFat", "cholesterol", "sodium",
    "totalCarbohydrates", "dietaryFiber", "totalSugars", "addedSugars", "protein",
    "vitaminA", "vitaminD", "vitaminE", "vitaminK", "vitaminC",
    "thiamine", "riboflavin", "niacin", "pantothenicAcid", "vitaminB6",
    "biotin", "folate", "vitaminB12", "choline",
    "calcium", "phosphorus", "magnesium", "potassium", "chloride",
    "iron", "zinc", "copper", "manganese", "selenium", "iodine", "fluoride",
    "chromium", "molybdenum", "caffeine", "water",
]

private let nutrientDisplayNames: [String: String] = [
    "calories": "Calories", "totalFat": "Total Fat", "saturatedFat": "Saturated Fat",
    "transFat": "Trans Fat", "cholesterol": "Cholesterol", "sodium": "Sodium",
    "totalCarbohydrates": "Total Carbs", "dietaryFiber": "Dietary Fiber",
    "totalSugars": "Total Sugars", "addedSugars": "Added Sugars", "protein": "Protein",
    "vitaminD": "Vitamin D", "calcium": "Calcium", "iron": "Iron", "potassium": "Potassium",
    "vitaminA": "Vitamin A", "vitaminC": "Vitamin C", "vitaminE": "Vitamin E",
    "vitaminK": "Vitamin K", "thiamine": "Thiamine", "riboflavin": "Riboflavin",
    "niacin": "Niacin", "pantothenicAcid": "Pantothenic Acid", "vitaminB6": "Vitamin B6",
    "biotin": "Biotin", "folate": "Folate", "vitaminB12": "Vitamin B12",
    "phosphorus": "Phosphorus", "magnesium": "Magnesium", "zinc": "Zinc",
    "copper": "Copper", "manganese": "Manganese", "selenium": "Selenium",
    "iodine": "Iodine", "chloride": "Chloride", "fluoride": "Fluoride",
    "polyunsaturatedFat": "Polyunsaturated Fat", "monounsaturatedFat": "Monounsaturated Fat",
    "chromium": "Chromium", "molybdenum": "Molybdenum", "choline": "Choline",
    "caffeine": "Caffeine", "water": "Water",
]

private let nutrientUnits: [String: String] = [
    "calories": "kcal", "totalFat": "g", "saturatedFat": "g", "transFat": "g",
    "cholesterol": "mg", "sodium": "mg", "totalCarbohydrates": "g",
    "dietaryFiber": "g", "totalSugars": "g", "addedSugars": "g", "protein": "g",
    "vitaminD": "mcg", "calcium": "mg", "iron": "mg", "potassium": "mg",
    "vitaminA": "mcg", "vitaminC": "mg", "vitaminE": "mg", "vitaminK": "mcg",
    "thiamine": "mg", "riboflavin": "mg", "niacin": "mg", "pantothenicAcid": "mg",
    "vitaminB6": "mg", "biotin": "mcg", "folate": "mcg", "vitaminB12": "mcg",
    "phosphorus": "mg", "magnesium": "mg", "zinc": "mg", "copper": "mg",
    "manganese": "mg", "selenium": "mcg", "iodine": "mcg", "chloride": "mg",
    "fluoride": "mg", "polyunsaturatedFat": "g", "monounsaturatedFat": "g",
    "chromium": "mcg", "molybdenum": "mcg", "choline": "mg",
    "caffeine": "mg", "water": "mL",
]

// Display order for matched nutrients
private let displayOrder: [String] = [
    "calories", "totalFat", "saturatedFat", "transFat", "polyunsaturatedFat",
    "monounsaturatedFat", "cholesterol", "sodium", "totalCarbohydrates",
    "dietaryFiber", "totalSugars", "addedSugars", "protein",
    "vitaminA", "vitaminC", "vitaminD", "vitaminE", "vitaminK",
    "thiamine", "riboflavin", "niacin", "pantothenicAcid", "vitaminB6",
    "biotin", "folate", "vitaminB12", "choline",
    "calcium", "phosphorus", "magnesium", "potassium", "chloride",
    "iron", "zinc", "copper", "manganese", "selenium", "iodine", "fluoride",
    "chromium", "molybdenum",
    "caffeine", "water",
]

struct NutritionScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var recognizedLines: [String] = []
    @State private var parsedData: [String: Double] = [:]
    @State private var isProcessing = false
    @State private var showingAddFood = false
    @State private var errorMessage: String?
    @State private var reassigningKey: String?

    private var matchedEntries: [(key: String, value: Double)] {
        parsedData
            .filter { trackedKeys.contains($0.key) }
            .sorted { a, b in
                let ai = displayOrder.firstIndex(of: a.key) ?? 99
                let bi = displayOrder.firstIndex(of: b.key) ?? 99
                return ai < bi
            }
    }

    private var unmatchedEntries: [(key: String, value: Double)] {
        parsedData
            .filter { !trackedKeys.contains($0.key) }
            .sorted { a, b in a.key < b.key }
    }

    private var emptyTrackedKeys: [String] {
        displayOrder.filter { key in
            parsedData[key] == nil && trackedKeys.contains(key)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let image = capturedImage {
                    resultView(image: image)
                } else {
                    placeholderView
                }
            }
            .background(Cal.bg)
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $capturedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(image: $capturedImage)
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodView(
                    scannedData: parsedData.filter { trackedKeys.contains($0.key) },
                    onSave: {
                        // Reset scanner state after saving
                        capturedImage = nil
                        parsedData = [:]
                        recognizedLines = []
                        errorMessage = nil
                        // Switch to dashboard
                        NotificationCenter.default.post(name: .switchToDashboard, object: nil)
                    }
                )
            }
            .onChange(of: capturedImage) { _, newImage in
                if let image = newImage {
                    processImage(image)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Cal.intelligenceGlow, lineWidth: 16)
                        .blur(radius: 20)
                        .opacity(0.3)
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Cal.bgCard)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Cal.intelligenceGlow, lineWidth: 1)
                        )

                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(Cal.accentGradient)
                }

                VStack(spacing: 8) {
                    Text("Scan Nutrition Label")
                        .font(.displaySmall())
                        .foregroundStyle(Cal.textPrimary)
                    Text("Take a photo of any nutrition facts\nlabel to extract data automatically")
                        .font(.system(size: 14))
                        .foregroundStyle(Cal.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }

            Spacer()

            VStack(spacing: 10) {
                Button {
                    showingCamera = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("Take Photo")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Cal.accentGradient, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                }

                Button {
                    showingPhotoPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16))
                        Text("Photo Library")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Cal.bgCard, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Cal.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Cal.intelligenceGlow, lineWidth: 0.5)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Result View

    private func resultView(image: UIImage) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )

                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(Cal.accent)
                            .scaleEffect(1.2)
                        Text("Analyzing label...")
                            .font(.mono(12))
                            .foregroundStyle(Cal.textTertiary)
                    }
                    .padding(.vertical, 32)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 28))
                            .foregroundStyle(Cal.warn)
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(Cal.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    .glassCard()
                } else if !parsedData.isEmpty {
                    matchedDataView
                    if !unmatchedEntries.isEmpty {
                        unmatchedDataView
                    }
                }

                actionButtons

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    // MARK: - Matched Nutrients

    private var matchedDataView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DETECTED NUTRIENTS")
                    .font(.label())
                    .tracking(2)
                    .foregroundStyle(Cal.textTertiary)
                Spacer()
                Text("\(matchedEntries.count) matched")
                    .font(.mono(11))
                    .foregroundStyle(Cal.accent)
            }

            ForEach(Array(matchedEntries.enumerated()), id: \.element.key) { index, item in
                nutrientRow(key: item.key, value: item.value)
                if index < matchedEntries.count - 1 {
                    Divider().overlay(Color.white.opacity(0.04))
                }
            }
        }
        .glassCard()
    }

    // MARK: - Unmatched Nutrients

    private var unmatchedDataView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("UNMATCHED")
                    .font(.label())
                    .tracking(2)
                    .foregroundStyle(Cal.warn)
                Spacer()
                Text("tap to assign")
                    .font(.system(size: 11))
                    .foregroundStyle(Cal.textTertiary)
            }

            ForEach(Array(unmatchedEntries.enumerated()), id: \.element.key) { index, item in
                Button {
                    reassigningKey = item.key
                } label: {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(Cal.warn)
                            Text(displayName(for: item.key))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Cal.warn)
                        }
                        Spacer()
                        Text(formatValue(item.value, key: item.key))
                            .font(.mono(13))
                            .foregroundStyle(Cal.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
                .confirmationDialog(
                    "Assign \(displayName(for: item.key))",
                    isPresented: Binding(
                        get: { reassigningKey == item.key },
                        set: { if !$0 { reassigningKey = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    reassignActions(for: item.key, value: item.value)
                } message: {
                    Text("Choose which nutrient field to assign this value to")
                }

                if index < unmatchedEntries.count - 1 {
                    Divider().overlay(Color.white.opacity(0.04))
                }
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private func reassignActions(for unmatchedKey: String, value: Double) -> some View {
        // Show suggested matches first (based on similarity)
        let suggestions = suggestedKeys(for: unmatchedKey)
        let remaining = emptyTrackedKeys.filter { !suggestions.contains($0) }

        if !suggestions.isEmpty {
            ForEach(suggestions, id: \.self) { targetKey in
                Button("\(displayName(for: targetKey)) (suggested)") {
                    reassign(from: unmatchedKey, to: targetKey, value: value)
                }
            }
        }

        ForEach(remaining.prefix(10), id: \.self) { targetKey in
            Button(displayName(for: targetKey)) {
                reassign(from: unmatchedKey, to: targetKey, value: value)
            }
        }

        Button("Discard", role: .destructive) {
            parsedData.removeValue(forKey: unmatchedKey)
        }

        Button("Cancel", role: .cancel) {}
    }

    private func reassign(from unmatchedKey: String, to targetKey: String, value: Double) {
        parsedData[targetKey] = value
        parsedData.removeValue(forKey: unmatchedKey)
    }

    // MARK: - Suggestions

    private func suggestedKeys(for key: String) -> [String] {
        let lower = key.lowercased()
        var suggestions: [(key: String, score: Int)] = []

        for target in emptyTrackedKeys {
            let targetLower = target.lowercased()
            var score = 0

            // Exact substring match
            if targetLower.contains(lower) || lower.contains(targetLower) {
                score += 50
            }

            // Category matching
            if lower.contains("fat") && targetLower.contains("fat") { score += 30 }
            if lower.contains("vitamin") && targetLower.contains("vitamin") { score += 30 }
            if lower.contains("sugar") && targetLower.contains("sugar") { score += 30 }

            // Common prefix
            let prefix = commonPrefixLength(lower, targetLower)
            score += prefix * 3

            // Shared significant words
            let keyWords = splitCamelCase(lower)
            let targetWords = splitCamelCase(targetLower)
            let shared = Set(keyWords).intersection(Set(targetWords))
            score += shared.count * 15

            if score > 5 {
                suggestions.append((target, score))
            }
        }

        return suggestions.sorted { $0.score > $1.score }.prefix(3).map(\.key)
    }

    private func commonPrefixLength(_ a: String, _ b: String) -> Int {
        zip(a, b).prefix(while: { $0 == $1 }).count
    }

    private func splitCamelCase(_ text: String) -> [String] {
        var words: [String] = []
        var current = ""
        for char in text {
            if char.isUppercase && !current.isEmpty {
                words.append(current.lowercased())
                current = String(char)
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { words.append(current.lowercased()) }
        return words
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    capturedImage = nil
                    parsedData = [:]
                    recognizedLines = []
                    errorMessage = nil
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))
                    Text("Retake")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Cal.bgCard, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Cal.textSecondary)
            }

            if !matchedEntries.isEmpty {
                Button {
                    showingAddFood = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                        Text("Use Data")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Cal.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Cal.bg)
                }
            }
        }
    }

    // MARK: - Subviews

    private func nutrientRow(key: String, value: Double) -> some View {
        HStack {
            Text(displayName(for: key))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Cal.textPrimary)
            Spacer()
            Text(formatValue(value, key: key))
                .font(.mono(13))
                .foregroundStyle(Cal.accent)
        }
        .padding(.vertical, 8)
    }

    // MARK: - OCR Processing

    private func processImage(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil

        guard let cgImage = image.cgImage else {
            errorMessage = "Could not process image"
            isProcessing = false
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                isProcessing = false

                if let error = error {
                    errorMessage = "Recognition failed: \(error.localizedDescription)"
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    errorMessage = "No text found in image"
                    return
                }

                let lines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                recognizedLines = lines
                parsedData = NutritionLabelParser.parse(lines: lines)

                if parsedData.isEmpty {
                    errorMessage = "Could not identify nutrition data.\nMake sure the label is clearly visible."
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    errorMessage = "Failed to perform text recognition"
                }
            }
        }
    }

    // MARK: - Helpers

    private func displayName(for key: String) -> String {
        nutrientDisplayNames[key] ?? key
    }

    private func formatValue(_ value: Double, key: String) -> String {
        let unit = nutrientUnits[key] ?? ""
        let formatted = value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
        return "\(formatted) \(unit)"
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.image = image }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Picker

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPickerView
        init(_ parent: PhotoPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.image = image }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
