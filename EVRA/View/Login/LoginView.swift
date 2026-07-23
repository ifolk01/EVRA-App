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
    
    
    
    var body: some View {
        ZStack {
            // Fundo verde característico da marca Lev
            AppColors.levGreenBg.ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                // Logo e Branding
                VStack(spacing: 12) {
                    
                    
                    HStack(spacing: 7) {
                        Image("Letter_V_plain")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                        
                        
                        Image("Letter_E_plain")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                        
                        
                        
                        Image("Letter_L_plain")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                        
                        
                        Image("Letter_O_plain")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                        
                        
                        Image("Letter_S_plain")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                        
                        
                        
                    }
                    Spacer()
                    
                    Image("logoVelos")
                        .resizable()
                        .scaledToFit()
                    
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
                    
                    
                    
                    // Botão Apple (Nativo)
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in request.requestedScopes = [.fullName, .email] },
                        onCompletion: { result in
                            if case .success(let auth) = result,
                               let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                
                                viewModel.processAppleSignInResult(credential: credential)
                                let appleID = viewModel.appleUserIdentifier
                                
                                UserDefaults.standard.set(appleID, forKey: "apple_user_id")
                                // Usamos uma Task para fazer a chamada assíncrona ao CloudKit
                                Task {
                                                // 1. Busca na nuvem em background
                                                await homeVM.fetchDashboardData(appleUserId: appleID)
                                                
                                                // 🔥 2. TUDO O QUE MEXE NO SWIFTDATA TEM DE RODAR NO MAINACTOR!
                                                await MainActor.run {
                                                    if let recoveredUser = homeVM.currentUser {
                                                        
                                                        // 👻 CAÇA-FANTASMAS: Se a Apple deu um nome real agora, mas a nuvem tem o fantasma antigo, atualizamos!
                                                        if !viewModel.name.isEmpty && recoveredUser.name == "Ciclista" {
                                                            recoveredUser.name = viewModel.name
                                                            recoveredUser.email = viewModel.email
                                                            // Envia o nome real para curar a nuvem
                                                            Task { try? await CloudKitService().saveUser(recoveredUser) }
                                                        }
                                                        
                                                        modelContext.insert(recoveredUser)
                                                        try? modelContext.save()
                                                        isLoggedIn = true
                                                        
                                                    } else {
                                                        // 3. Se não achou, é novo!
                                                        let userName = viewModel.name.isEmpty ? "Ciclista" : viewModel.name
                                                        let userEmail = viewModel.email.isEmpty ? "email@exemplo.com" : viewModel.email
                                                        
                                                        let newUser = User(
                                                            appleUserIdentifier: appleID,
                                                            name: userName,
                                                            email: userEmail,
                                                            bikeSerialNumber: "",
                                                            substitutedVehicleRawValue: SubstitutedVehicle.car.rawValue,
                                                            frequency: "",
                                                            routes: []
                                                        )
                                                        
                                                        modelContext.insert(newUser)
                                                        try? modelContext.save()
                                                        homeVM.currentUser = newUser
                                                        
                                                        // Salva o utilizador NOVO na nuvem
                                                        Task { try? await CloudKitService().saveUser(newUser) }
                                                        
                                                        isLoggedIn = true
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
                
                // Separador "ou"
                //                Text("ou")
                //                    .foregroundColor(.gray)
                //
                //                // Botão E-mail
                //                Button(action: {}) {
                //                    Text("Criar conta com e-mail →")
                //                        .foregroundColor(.white)
                //                        .frame(maxWidth: .infinity)
                //                        .padding()
                //                        .background(AppColors.levBlue)
                //                        .cornerRadius(12)
                //                }
                
                // Termos
                Text("Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black.opacity(0.4))
                
                
            }
            .padding(24)
        }
        
    }
}

#Preview {
    LoginView()
        .environment(AppRouter())
        .environment(OnboardingViewModel())
}
