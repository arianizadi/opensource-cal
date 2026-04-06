import SwiftUI
import SwiftData

extension Notification.Name {
    static let switchToDashboard = Notification.Name("switchToDashboard")
}

enum AppTab: Int, CaseIterable {
    case dashboard, log, scan, analytics

    var icon: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .log: return "list.bullet.clipboard.fill"
        case .scan: return "viewfinder"
        case .analytics: return "chart.line.uptrend.xyaxis"
        }
    }

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .log: return "Log"
        case .scan: return "Scan"
        case .analytics: return "Insights"
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
                case .analytics:
                    AnalyticsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .switchToDashboard)) { _ in
            withAnimation(.spring(response: 0.35)) {
                selectedTab = .dashboard
            }
        }
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
                                    .fill(Cal.accentGradient)
                                    .opacity(0.2)
                                    .frame(width: 48, height: 28)
                                    .blur(radius: 4)
                                Capsule()
                                    .fill(Cal.accentGradient)
                                    .opacity(0.12)
                                    .frame(width: 48, height: 28)
                            }

                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: selectedTab == tab ? .bold : .regular))
                                .foregroundStyle(
                                    selectedTab == tab
                                        ? AnyShapeStyle(Cal.accentGradient)
                                        : AnyShapeStyle(Cal.textTertiary)
                                )
                        }
                        .frame(height: 28)

                        Text(tab.label.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(
                                selectedTab == tab
                                    ? AnyShapeStyle(Cal.accentGradient)
                                    : AnyShapeStyle(Cal.textTertiary)
                            )
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
