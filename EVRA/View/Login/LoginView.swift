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
    

 
    
    var body: some View {
        ZStack {
            // Fundo verde característico da marca Lev
            AppColors.levGreenBg.ignoresSafeArea()
            
            VStack(spacing: 40) {
               
                // Logo e Branding
                VStack(spacing: 12) {
    
                    
                    HStack(spacing: 7) {
                        Image("Letter_E_BebasNeue")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 55, height: 55)
          
                     
                        
                        Image("Letter_V_BebasNeue")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 55, height: 55)
     
            
                        
                        Image("Letter_R_BebasNeue")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 55, height: 55)
                     
                    
                        
                        Image("Letter_A_BebasNeue")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 55, height: 55)
                   
               
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
                                                    
                                                    // 1. Extrai os dados da Apple e guarda temporariamente no ViewModel
                                                    viewModel.processAppleSignInResult(credential: credential)
                                                    
                                                    // 2. Identifica o utilizador no PostHog usando os dados do ViewModel!
                                                    AnalyticsManager.shared.identifyUser(
                                                        id: viewModel.appleUserIdentifier,
                                                        name: viewModel.name.isEmpty ? "Ciclista" : viewModel.name,
                                                        email: viewModel.email
                                                    )
                                                    
                                                    // 3. Avança para o Onboarding
                                                    router.startOnboarding()
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
