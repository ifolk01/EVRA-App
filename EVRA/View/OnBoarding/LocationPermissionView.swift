//
//  LocationPermissionView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI
import CoreLocation
import SwiftData

struct LocationPermissionView: View {
    @Environment(AppRouter.self) private var router
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = false
    
 
    
    var body: some View {
        ZStack {
            AppColors.levGreenBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Barra de Progresso no topo
                OnboardingProgressBar(currentStep: .locationPermission)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                
                Spacer()
                
                // Ícone Central (Círculo Branco com Pin)
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "mappin")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(AppColors.levBlue)
                }
                .padding(.bottom, 24)
                
                // Título e Subtítulo
                Text("Permissão de localização")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 12)
                
                Text("Utilizamos sua localização para acompanhar trajetos, calcular impacto sustentável e liberar benefícios personalizados.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black.opacity(0.75))
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                
                // Cartão Branco de Informações (Razões de Privacidade)
                VStack(alignment: .leading, spacing: 20) {
                    infoRow(
                        icon: "shield",
                        title: "Seus dados são privados",
                        description: "Nunca compartilhamos sua localização com terceiros."
                    )
                    
                    infoRow(
                        icon: "location",
                        title: "Uso inteligente",
                        description: "A localização é usada apenas durante seus trajetos."
                    )
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 24)
                
                Spacer()
                
                if isLoading {
                    ProgressView("A preparar o seu perfil...")
                        .padding(.bottom, 16)
                        .tint(AppColors.levBlue)
                }
                
                // Botão Principal (Permitir)
                Button(action: {
                    AnalyticsManager.shared.trackEvent("Permission_Location_Accepted")
                    AnalyticsManager.shared.trackEvent("Onboarding_Completed")
                    requestPermissionAndFinish()
                }) {
                    HStack {
                        Text("Permitir localização")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.levBlue)
                    .cornerRadius(16)
                }
                .disabled(isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Botão Secundário (Agora não)
                Button(action: {
                    AnalyticsManager.shared.trackEvent("Permission_Location_Denied")
                    AnalyticsManager.shared.trackEvent("Onboarding_Completed")
                    skipPermissionAndFinish()
                }) {
                    Text("Agora não")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black.opacity(0.55))
                }
                .disabled(isLoading)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        
        .onAppear {
            AnalyticsManager.shared.trackScreen("Onboarding_Step_Location")
        }
    }
    
    // MARK: - Componente do Cartão de Informação
    @ViewBuilder
    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Ícone num pequeno círculo azul
            ZStack {
                Circle()
                    .fill(AppColors.levBlue.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.levBlue)
            }
            
            // Textos
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black.opacity(0.85))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true) // Evita que o texto corte
            }
        }
    }
    
    // MARK: - Lógica de Finalização
    private func requestPermissionAndFinish() {
        // 1. Pede a permissão real ao sistema
        let manager = CLLocationManager()
        manager.requestAlwaysAuthorization()
        
        // 2. Finaliza o registo
        finalizeOnboarding()
    }
    
    private func skipPermissionAndFinish() {
        // Ignora o pedido de permissão, mas finaliza o registo à mesma
        finalizeOnboarding()
    }
    
    private func finalizeOnboarding() {
        isLoading = true
        
        Task {
            // Aguarda a ViewModel gravar tudo no CloudKit
            await viewModel.completeRegistration(context: modelContext)
            await MainActor.run {
                isLoading = false
                
                // Se tudo correu bem, muda o estado do AppRouter para .main
                // O RootView deteta esta mudança e abre a TrackingTabView automaticamente!
                router.finishOnboardingAndGoHome()
            }
        }
    }
}


#Preview {
    LocationPermissionView()
        .environment(AppRouter())
        .environment(OnboardingViewModel())
}
