//
//  RootView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI
import SwiftData


/// A view raiz que intercepta a abertura do aplicativo e decide para onde o usuário vai.
struct RootView: View {
    // Instanciamos o Router aqui no topo da árvore
    @State var showingLaunchScreen = true
    @State private var router = AppRouter()
    @State private var onboardingVM = OnboardingViewModel()
    @State private var homeVM = HomeViewModel()
    @Environment(TrackingViewModel.self) private var trackingVM
    @Environment(\.modelContext) private var modelContext
    @Query private var savedUsers: [User]
    
    var body: some View {
        Group {
            // Um switch case elegante que reage automaticamente às mudanças de estado
            switch router.currentState {
            case .splash:
                LaunchScreenView(onAnimationFinished: {
                    
                    showingLaunchScreen = false
                })
                .transition(.opacity)
            case .login:
                LoginView()
            case .onboarding:
                OnboardingCoordinatorView(onboardingVM: onboardingVM)
            case .main:
                // Sua TabBarView principal, que já existia no seu projeto original
                MainTabView(homeVM: homeVM, trackingVM: trackingVM)
            }
        }
        .environment(router)
        .environment(onboardingVM) // <--- O SEGREDO ESTÁ AQUI
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
 
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if let existingUser = savedUsers.first {
                    // Já existe um utilizador gravado no telemóvel!
                    // Carregamos ele para o HomeViewModel e saltamos direto para a Home.
                    self.homeVM.currentUser = existingUser
                    router.currentState = .main
                } else {
                    // Não há ninguém logado, vai para a tela de Login do Apple ID
                    router.currentState = .login
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
            // Criamos um binding local para a path do router
            @Bindable var routerBindable = router
            
            NavigationStack(path: $routerBindable.onboardingPath) {
                // A tela raiz do Onboarding (Pode ser a tela de Boas-vindas ou ir direto pro N° de Série)
                WelcomeOnboardingView()
                // Aqui é onde a mágica acontece: Mapeamos o Enum para as Telas reais!
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
            // Injetamos a ViewModel no ambiente do fluxo de Onboarding
            .environment(onboardingVM)
        }
    }







