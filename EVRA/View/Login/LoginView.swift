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
    
    // MARK: - Estados para o Popup de Recuperação
    @State private var showNamePrompt = false
    @State private var manualName: String = ""
    @State private var manualEmail: String = ""
    @State private var pendingAppleID: String = "" // Guarda o ID enquanto o usuário digita
    
    var body: some View {
        ZStack {
            AppColors.levGreenBg.ignoresSafeArea()
            
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
                        .lineLimit(1)
                    
                    Text("Faça login para começar a acumular Carbon Points")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black.opacity(0.7))
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
                                            // 1. UTILIZADOR EXISTENTE NA BASE DE DADOS
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
                                            // 2. UTILIZADOR NÃO ENCONTRADO (Novo ou Apagado)
                                            if viewModel.name.isEmpty {
                                                // ⚠️ A Apple escondeu o nome (Utilizador apagou a conta e voltou)
                                                // Pausamos o fluxo e abrimos o popup!
                                                pendingAppleID = appleID
                                                showNamePrompt = true
                                            } else {
                                                // ✅ Primeira vez de sempre (A Apple enviou os dados)
                                                createNewUserAndLogin(appleID: appleID, name: viewModel.name, email: viewModel.email)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .cornerRadius(12)
                }
                
                Text("Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black.opacity(0.4))
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
    LoginView()
        .environment(AppRouter())
        .environment(OnboardingViewModel())
}
