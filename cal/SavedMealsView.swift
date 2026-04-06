import SwiftUI
import SwiftData
import WidgetKit

struct SavedMealsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MealTemplate.timesUsed, order: .reverse) private var templates: [MealTemplate]

    private var healthKit = HealthKitManager.shared
    @State private var loggedTemplate: MealTemplate?

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(templates) { template in
                            Button {
                                logTemplate(template)
                            } label: {
                                templateRow(template)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(templates[index])
                            }
                        }

                        Section {
                            Spacer(minLength: 80)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Cal.bg)
            .navigationTitle("Saved Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Cal.accent)
                }
            }
            .overlay(alignment: .bottom) {
                if loggedTemplate != nil {
                    loggedToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 100)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Template Row

    private func templateRow(_ template: MealTemplate) -> some View {
        HStack(spacing: 14) {
            // Quick-log indicator
            ZStack {
                Circle()
                    .fill(Cal.accent.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Cal.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name.isEmpty ? "Unnamed Meal" : template.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Cal.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(Int(template.calories)) kcal")
                        .font(.mono(11))
                        .foregroundStyle(Cal.accent)

                    HStack(spacing: 6) {
                        macroTag("P", value: template.protein, color: Cal.protein)
                        macroTag("C", value: template.totalCarbohydrates, color: Cal.carbs)
                        macroTag("F", value: template.totalFat, color: Cal.fat)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if template.timesUsed > 0 {
                    Text("\(template.timesUsed)x")
                        .font(.mono(11))
                        .foregroundStyle(Cal.textTertiary)
                }
                if !template.servingSize.isEmpty {
                    Text(template.servingSize)
                        .font(.mono(10))
                        .foregroundStyle(Cal.textTertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Cal.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
    }

    private func macroTag(_ letter: String, value: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Circle().fill(color).frame(width: 4, height: 4)
            Text("\(letter)\(Int(value))g")
                .font(.mono(10))
                .foregroundStyle(Cal.textSecondary)
        }
    }

    // MARK: - Log Template

    private func logTemplate(_ template: MealTemplate) {
        let entry = template.toFoodEntry()
        modelContext.insert(entry)
        template.timesUsed += 1
        template.lastUsed = .now
        WidgetCenter.shared.reloadAllTimelines()

        Task {
            if let hkID = await healthKit.saveFoodEntry(entry) {
                entry.healthKitID = hkID
            }
        }

        withAnimation(.spring(response: 0.3)) {
            loggedTemplate = template
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { loggedTemplate = nil }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Cal.accentSoft)
                    .frame(width: 100, height: 100)
                Image(systemName: "bookmark")
                    .font(.system(size: 36))
                    .foregroundStyle(Cal.accent)
            }

            VStack(spacing: 6) {
                Text("No saved meals")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Cal.textPrimary)
                Text("Log a food, then tap \"Save as Template\"\nin its detail view")
                    .font(.system(size: 14))
                    .foregroundStyle(Cal.textTertiary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    // MARK: - Logged Toast

    private var loggedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Cal.good)
            Text("\(loggedTemplate?.name ?? "Meal") logged")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Cal.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .environment(\.colorScheme, .dark)
    }
}
