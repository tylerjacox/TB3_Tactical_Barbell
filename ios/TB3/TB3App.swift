// TB3 iOS — App Entry Point (mirrors main.tsx + app.tsx)

import SwiftUI
import SwiftData

@main
struct TB3App: App {
    @State private var appState = AppState()

    init() {
        // Navigation bar: TB3 dark theme (used by Profile NavigationStack for push navigation)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.tb3Background)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .modelContainer(for: [
            PersistedProfile.self,
            PersistedActiveProgram.self,
            PersistedSessionLog.self,
            PersistedOneRepMaxTest.self,
        ])
    }
}

struct RootView: View {
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase

    @State private var dataStore: DataStore?
    @State private var authService: AuthService?
    @State private var syncCoordinator: SyncCoordinator?
    @State private var feedbackService = FeedbackService()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color.tb3Background.ignoresSafeArea()

            if appState.isLoading {
                LoadingView()
            } else if !appState.authState.isAuthenticated {
                if let authService {
                    AuthFlowView(authService: authService)
                } else {
                    LoadingView()
                }
            } else if appState.isFirstLaunch {
                if let dataStore {
                    OnboardingContainerView(appState: appState, dataStore: dataStore)
                } else {
                    LoadingView()
                }
            } else {
                mainTabView
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.isSessionPresented },
            set: { appState.isSessionPresented = $0 }
        )) {
            if let dataStore {
                SessionView(vm: SessionViewModel(
                    appState: appState,
                    dataStore: dataStore,
                    feedback: feedbackService
                ))
                .environment(appState)
            }
        }
        .tint(Color.tb3Accent)
        .preferredColorScheme(.dark)
        .task { await setup() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncCoordinator?.onForeground()
            }
        }
    }

    // MARK: - Main Tab View

    private var mainTabView: some View {
        VStack(spacing: 0) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            DashboardView(
                onNavigateToProgram: { selectedTab = 1 },
                onNavigateToProfile: { selectedTab = 3 },
                onStartWorkout: { exercises, week, program in
                    if let dataStore {
                        let sessionVM = SessionViewModel(appState: appState, dataStore: dataStore, feedback: feedbackService)
                        sessionVM.startSession(exercises: exercises, week: week, program: program)
                    }
                }
            )
        case 1:
            if let dataStore {
                ProgramView(dataStore: dataStore)
            }
        case 2:
            HistoryView()
        case 3:
            if let dataStore, let authService, let syncCoordinator {
                ProfileView(vm: ProfileViewModel(
                    appState: appState,
                    dataStore: dataStore,
                    authService: authService,
                    syncCoordinator: syncCoordinator
                ))
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Setup

    private func setup() async {
        let store = DataStore(modelContext: modelContext)
        let tokenManager = TokenManager()
        let auth = AuthService(authState: appState.authState)
        let apiClient = APIClient(tokenManager: tokenManager)
        let syncService = SyncService(apiClient: apiClient)
        let coordinator = SyncCoordinator(
            syncService: syncService,
            dataStore: store,
            authState: appState.authState,
            syncState: appState.syncState,
            appState: appState
        )

        self.dataStore = store
        self.authService = auth
        self.syncCoordinator = coordinator

        // Load data from SwiftData
        appState.loadInitialData(store)

        // Initialize auth (check stored tokens, refresh)
        await auth.initAuth()

        // Start periodic sync if authenticated
        if appState.authState.isAuthenticated {
            coordinator.start()
            await coordinator.performSync()
        }
    }
}
