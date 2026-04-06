import SwiftUI
import SwiftData

enum AppTab: Int, CaseIterable {
    case dashboard, log, scan

    var icon: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .log: return "list.bullet.clipboard.fill"
        case .scan: return "viewfinder"
        }
    }

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .log: return "Log"
        case .scan: return "Scan"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var tabBarVisible = true

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .log:
                    FoodLogView()
                case .scan:
                    NutritionScannerView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(Cal.accent.opacity(0.15))
                                    .frame(width: 48, height: 28)
                            }

                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: selectedTab == tab ? .bold : .regular))
                                .foregroundStyle(selectedTab == tab ? Cal.accent : Cal.textTertiary)
                        }
                        .frame(height: 28)

                        Text(tab.label.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(selectedTab == tab ? Cal.accent : Cal.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    Rectangle()
                        .fill(Cal.bg.opacity(0.7))
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 0.5)
                }
                .ignoresSafeArea()
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
