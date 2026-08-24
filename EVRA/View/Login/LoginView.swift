//
//  LoginView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 13/07/26.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct LoginView: View {
    @Environment(AppRouter.self) private var router
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @Environment(HomeViewModel.self) private var homeVM
    
    // 🔥 1. Detetor de Tema e Estado da Animação
    @Environment(\.colorScheme) var colorScheme
    @State private var animate = false
    
    // MARK: - Estados para o Popup de Recuperação
    @State private var showNamePrompt = false
    @State private var manualName: String = ""
    @State private var manualEmail: String = ""
    @State private var pendingAppleID: String = ""
    
    var body: some View {
        let isDark = colorScheme == .dark
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.8) : .black.opacity(0.7)
        let captionText = isDark ? Color.white.opacity(0.6) : .black.opacity(0.4)
        
        // Um verde néon um pouco mais fechado para não cansar a vista no Dark Mode
        let darkNeonGreen = Color(red: 0.6, green: 0.8, blue: 0.1)
        
        let lightGradientColors = [AppColors.neonGreen, Color("LevGreenDark")]
        let darkGradientColors = [darkNeonGreen, Color("LevGreenDark")]
        let activeColors = isDark ? darkGradientColors : lightGradientColors
        
        ZStack {
            // 🔥 2. Fundo Animado com suporte a Dark/Light Mode
            LinearGradient(
                colors: animate ? activeColors.reversed() : activeColors,
                startPoint: animate ? .bottomTrailing : .topLeading,
                endPoint: animate ? .topLeading : .bottomTrailing
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo e Branding
                VStack(spacing: 12) {
                    HStack(spacing: 7) {
                        Image("Letter_V_plain").resizable().scaledToFit().frame(width: 35, height: 35)
                        Image("Letter_E_plain").resizable().scaledToFit().frame(width: 35, height: 35)
                        Image("Letter_L_plain").resizable().scaledToFit().frame(width: 35, height: 35)
                        Image("Letter_O_plain").resizable().scaledToFit().frame(width: 35, height: 35)
                        Image("Letter_S_plain").resizable().scaledToFit().frame(width: 35, height: 35)
                    }
                    Spacer()
                    
                    Image("logoVelos").resizable().scaledToFit()
                    
                    Text("Seu trajeto agora vale mais.")
                        .font(.system(size: 25, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(primaryText) // 🔥 Texto responsivo
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Faça login para começar a acumular Carbon Points")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(secondaryText) // 🔥 Texto responsivo
                }
                
                Spacer()
                
                // Botões de Autenticação
                VStack(spacing: 39) {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in request.requestedScopes = [.fullName, .email] },
                        onCompletion: { result in
                            if case .success(let auth) = result,
                               let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                
                                viewModel.processAppleSignInResult(credential: credential)
                                let appleID = viewModel.appleUserIdentifier
                                UserDefaults.standard.set(appleID, forKey: "apple_user_id")
                                
                                Task {
                                    await homeVM.fetchDashboardData(appleUserId: appleID)
                                    
                                    await MainActor.run {
                                        if let recoveredUser = homeVM.currentUser {
                                            if !viewModel.name.isEmpty && recoveredUser.name == "Ciclista" {
                                                recoveredUser.name = viewModel.name
                                                recoveredUser.email = viewModel.email
                                                Task { try? await CloudKitService().saveUser(recoveredUser) }
                                            }
                                            modelContext.insert(recoveredUser)
                                            try? modelContext.save()
                                            isLoggedIn = true
                                            router.currentState = .main
                                            
                                        } else {
                                            if viewModel.name.isEmpty {
                                                pendingAppleID = appleID
                                                showNamePrompt = true
                                            } else {
                                                createNewUserAndLogin(appleID: appleID, name: viewModel.name, email: viewModel.email)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    )
                    // 🔥 3. O Botão da Apple também muda de cor!
                    .signInWithAppleButtonStyle(isDark ? .white : .black)
                    .frame(height: 52)
                    .cornerRadius(12)
                }
                
                Text("Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(captionText) // 🔥 Texto responsivo
            }
            .padding(24)
        }
    }
    
    // MARK: - Função Auxiliar para Criar e Logar
    private func createNewUserAndLogin(appleID: String, name: String, email: String) {
        let safeAppleName = viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let userName = safeAppleName.isEmpty ? "Ciclista" : safeAppleName

        let newUser = User(
            appleUserIdentifier: appleID,
            name: userName,
            email: viewModel.email.isEmpty ? "email@exemplo.com" : viewModel.email,
            bikeSerialNumber: "",
            substitutedVehicleRawValue: SubstitutedVehicle.car.rawValue,
            frequency: "",
            routes: []
        )
        
        modelContext.insert(newUser)
        try? modelContext.save()
        homeVM.currentUser = newUser
        
        Task { try? await CloudKitService().saveUser(newUser) }
        
        isLoggedIn = true
        router.currentState = .main
    }
}

#Preview {
    // 1. Criamos um contentor de memória temporário para o SwiftData não dar crash
    let previewContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: User.self, configurations: config)
        } catch {
            fatalError("Erro ao criar o ModelContainer do Preview: \(error)")
        }
    }()
    
    return LoginView()
        .environment(AppRouter())
        .environment(OnboardingViewModel())
        .environment(HomeViewModel()) // 🔥 Faltava isto!
        .modelContainer(previewContainer) // 🔥 E faltava o contexto da base de dados!
}
