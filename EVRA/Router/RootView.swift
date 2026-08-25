//
//  RootView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//
import SwiftUI
import SwiftData
import AuthenticationServices

/// A view raiz que intercepta a abertura do aplicativo e decide para onde o usuário vai.
struct RootView: View {
    
    // 1. Agora a RootView CONSOME os dados que o VelosApp criou, evitando duplicações!
    @Environment(AppRouter.self) private var router
    @Environment(HomeViewModel.self) private var homeVM
    @Environment(OnboardingViewModel.self) private var onboardingVM
    @Environment(TrackingViewModel.self) private var trackingVM
    
    @Environment(\.modelContext) private var modelContext
    @Query private var savedUsers: [User]
    
    // 2. Trazemos a variável de sessão para saber a verdade sobre o login
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    var body: some View {
        Group {
            // Um switch case elegante que reage automaticamente às mudanças de estado
            switch router.currentState {
            case .splash:
                LaunchScreenView(onAnimationFinished: {
                    // 3. A MAGIA ACONTECE AQUI: A animação terminou! Para onde vamos?
                    if isLoggedIn, let existingUser = savedUsers.first {
                        // Utilizador logado e dados encontrados -> Vai para a Home
                        self.homeVM.currentUser = existingUser
                        router.currentState = .main
                    } else {
                        // Sem sessão ou sem dados -> Vai para o Login
                        router.currentState = .login
                    }
                })
                .transition(.opacity)
                
            case .login:
                LoginView()
                
            case .onboarding:
                OnboardingCoordinatorView(onboardingVM: onboardingVM)
                
            case .main:
                MainTabView(homeVM: homeVM, trackingVM: trackingVM)
            }
        }
        .onOpenURL { url in
                    if url.absoluteString == "velos://tracking" {
                        // 1. Garante que o utilizador vai para a área principal do app
                        router.currentState = .main
                        // 2. Dispara o gatilho para abrir o ecrã de Tracking
                        router.showActiveTracking = true
                    }
                }
        .onChange(of: onboardingVM.isRegistrationComplete) { _, newValue in
            if newValue {
                // O utilizador acabou de se registrar! Usamos a memória local instantânea.
                self.homeVM.currentUser = User(
                    appleUserIdentifier: onboardingVM.appleUserIdentifier,
                    name: onboardingVM.name,
                    email: onboardingVM.email,
                    bikeSerialNumber: onboardingVM.bikeSerialNumber,
                    substitutedVehicleRawValue: onboardingVM.substitutedVehicle?.rawValue ?? "",
                    frequency: onboardingVM.frequency,
                    routes: Array(onboardingVM.selectedRoutes).map { $0.rawValue }
                )
                
                // Transição instantânea para a Home com os dados já inseridos
                router.currentState = .main
            }
        }
        .onAppear {
            // 4. Verificamos silenciosamente se o Apple ID não foi revogado
            checkAppleLoginState()
        }
    }
    
    // Função trazida do VelosApp para garantir que a sessão da Apple ainda é válida
    private func checkAppleLoginState() {
        guard let userID = UserDefaults.standard.string(forKey: "apple_user_id") else {
            isLoggedIn = false
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { state, _ in
            DispatchQueue.main.async {
                if state != .authorized {
                    self.isLoggedIn = false
                }
            }
        }
    }
}

/// View responsável por encapsular o NavigationStack do Onboarding e injetar a ViewModel
struct OnboardingCoordinatorView: View {
    
    @Environment(AppRouter.self) private var router
    var onboardingVM: OnboardingViewModel
    
    var body: some View {
        @Bindable var routerBindable = router
        
        NavigationStack(path: $routerBindable.onboardingPath) {
            WelcomeOnboardingView()
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .connectLEV:
                        ConnectBikeView()
                    case .substitutedVehicle:
                        SubstitutedVehicleView()
                    case .frequency:
                        FrequencyView()
                    case .routes:
                        RoutesView()
                    case .locationPermission:
                        LocationPermissionView()
                    case .readyToStart:
                        HomeDashboardView(homeVM: HomeViewModel())
                    }
                }
        }
    }
}
