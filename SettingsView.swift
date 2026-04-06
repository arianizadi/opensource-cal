import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile = UserProfile.shared

    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 9
    @State private var weightLbs: Int = 154

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    modeSection
                    bodyStatsSection
                    goalsSection
                    if profile.mode == .limit {
                        calculatedSection
                    }
                    unitsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Cal.bg)
            .scrollIndicators(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Cal.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        profile.hasSetProfile = true
                        profile.save()
                        dismiss()
                    }
                    .foregroundStyle(Cal.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { syncImperialValues() }
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("MODE")

            ForEach(AppMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        profile.mode = mode
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: mode == .tracker ? "flame" : "target")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(profile.mode == mode ? Cal.accent : Cal.textTertiary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(mode.rawValue)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Cal.textPrimary)
                            Text(mode.description)
                                .font(.system(size: 12))
                                .foregroundStyle(Cal.textSecondary)
                        }

                        Spacer()

                        if profile.mode == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Cal.accent)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Cal.bgCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        profile.mode == mode ? Cal.accent.opacity(0.3) : Color.white.opacity(0.04),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
            }
        }
    }

    // MARK: - Body Stats

    private var bodyStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("BODY STATS")

            VStack(spacing: 0) {
                settingsRow("Sex") {
                    Picker("Sex", selection: $profile.sex) {
                        ForEach(BiologicalSex.allCases, id: \.self) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                Divider().overlay(Color.white.opacity(0.04))

                settingsRow("Age") {
                    Stepper("\(profile.age)", value: $profile.age, in: 13...100)
                        .font(.mono(14))
                        .frame(width: 140)
                }

                Divider().overlay(Color.white.opacity(0.04))

                if profile.useImperial {
                    settingsRow("Height") {
                        HStack(spacing: 4) {
                            Picker("Feet", selection: $heightFeet) {
                                ForEach(4...7, id: \.self) { ft in
                                    Text("\(ft)'").tag(ft)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: heightFeet) { syncMetricHeight() }

                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inches in
                                    Text("\(inches)\"").tag(inches)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: heightInches) { syncMetricHeight() }
                        }
                    }

                    Divider().overlay(Color.white.opacity(0.04))

                    settingsRow("Weight") {
                        Stepper("\(weightLbs) lbs", value: $weightLbs, in: 80...500)
                            .font(.mono(14))
                            .frame(width: 160)
                            .onChange(of: weightLbs) {
                                profile.weightKg = Double(weightLbs) / 2.205
                            }
                    }
                } else {
                    settingsRow("Height") {
                        Stepper("\(Int(profile.heightCm)) cm", value: $profile.heightCm, in: 120...250)
                            .font(.mono(14))
                            .frame(width: 160)
                    }

                    Divider().overlay(Color.white.opacity(0.04))

                    settingsRow("Weight") {
                        Stepper("\(Int(profile.weightKg)) kg", value: $profile.weightKg, in: 35...230)
                            .font(.mono(14))
                            .frame(width: 160)
                    }
                }
            }
            .glassCard(cornerRadius: 14, padding: 16)
        }
    }

    // MARK: - Goals

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("GOAL")

            VStack(spacing: 0) {
                settingsRow("Activity") {
                    Picker("Activity", selection: $profile.activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.shortLabel).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Divider().overlay(Color.white.opacity(0.04))

                settingsRow("Goal") {
                    Picker("Goal", selection: $profile.weightGoal) {
                        ForEach(WeightGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .glassCard(cornerRadius: 14, padding: 16)
        }
    }

    // MARK: - Calculated Targets

    private var calculatedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("YOUR TARGETS")

            VStack(spacing: 12) {
                targetRow("Calories", value: "\(Int(profile.calorieGoal))", unit: "kcal", gradient: Cal.accentGradient)
                targetRow("Protein", value: "\(Int(profile.proteinGoal))", unit: "g", gradient: Cal.proteinGradient)
                targetRow("Carbs", value: "\(Int(profile.carbGoal))", unit: "g", gradient: Cal.carbsGradient)
                targetRow("Fat", value: "\(Int(profile.fatGoal))", unit: "g", gradient: Cal.fatGradient)

                HStack(spacing: 4) {
                    Text("BMR: \(Int(profile.bmr))")
                    Text("TDEE: \(Int(profile.tdee))")
                }
                .font(.mono(11))
                .foregroundStyle(Cal.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .glassCard(cornerRadius: 14, padding: 16)
        }
    }

    // MARK: - Units

    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("UNITS")

            HStack {
                Text("Use Imperial (lbs, ft)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Cal.textPrimary)
                Spacer()
                Toggle("", isOn: $profile.useImperial)
                    .tint(Cal.accent)
                    .onChange(of: profile.useImperial) { syncImperialValues() }
            }
            .glassCard(cornerRadius: 14, padding: 16)
        }
    }

    // MARK: - Subviews

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.label())
            .tracking(2)
            .foregroundStyle(Cal.textTertiary)
    }

    private func settingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Cal.textPrimary)
            Spacer()
            content()
        }
        .padding(.vertical, 8)
    }

    private func targetRow(_ label: String, value: String, unit: String, gradient: LinearGradient) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Cal.textPrimary)
            Spacer()
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(gradient)
                Text(unit)
                    .font(.mono(12))
                    .foregroundStyle(Cal.textTertiary)
            }
        }
    }

    // MARK: - Helpers

    private func syncImperialValues() {
        let totalInches = profile.heightCm / 2.54
        heightFeet = Int(totalInches) / 12
        heightInches = Int(totalInches) % 12
        weightLbs = Int(profile.weightKg * 2.205)
    }

    private func syncMetricHeight() {
        profile.heightCm = Double(heightFeet * 12 + heightInches) * 2.54
    }
}
