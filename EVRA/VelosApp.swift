//
//  EVRAApp.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI
import SwiftData
import ActivityKit
import AuthenticationServices

@main
struct VelosApp: App {
        @Environment(\.scenePhase) private var scenePhase
        
        @State private var trackingVM = TrackingViewModel()
        // 1. Instanciamos o HomeVM aqui na raiz
        @State private var homeVM = HomeViewModel()
        @State private var router = AppRouter()
        @State private var onboardingVM = OnboardingViewModel()
        
        @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
        
  
    
    init() {
       
        AnalyticsManager.shared.setup()
    }
    
    var body: some Scene {
            WindowGroup {
                if isLoggedIn {
                    // 3. Passamos o homeVM para a TabView principal
                    MainTabView(homeVM: homeVM, trackingVM: trackingVM)
                        .preferredColorScheme(.light)
                        .environment(router)
                        .environment(homeVM)
                        .onAppear {
                            // Injeta o utilizador salvo no ViewModel assim que a tela abre
                          
                            
                            checkAppleLoginState()
                        }
                    
                } else {
                    LoginView()
                        .environment(router)
                        .environment(onboardingVM)
                        .environment(homeVM)
                }
            }
            .modelContainer(for: [User.self, LocalRide.self])
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    Task {
                        for activity in Activity<TrackingAttributes>.activities {
                            print("DEBUG: Live Activity detetada em plano de fundo: \(activity.id)")
                        }
                    }
                }
            }
        
        
        }
    
    private func checkAppleLoginState() {
            // Pega o ID que guardámos no LoginView
            guard let userID = UserDefaults.standard.string(forKey: "apple_user_id") else {
                isLoggedIn = false
                return
            }
            
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userID) { state, error in
                DispatchQueue.main.async {
                    switch state {
                    case .authorized:
                        // O utilizador está verificado e válido! A app continua normalmente.
                        print("✅ Apple ID Validado com sucesso.")
                    case .revoked, .notFound:
                        // O utilizador apagou a app das configurações do iCloud ou a sessão expirou.
                        // Deslogamos automaticamente por segurança.
                        print("⚠️ Apple ID Revogado ou não encontrado. A redirecionar para o Login.")
                        self.isLoggedIn = false
                    default:
                        break
                    }
                }
            }
        }
    }
