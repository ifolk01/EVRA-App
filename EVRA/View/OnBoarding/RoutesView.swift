//
//  RoutesView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI

struct RoutesView: View {
    @Environment(AppRouter.self) private var router
    @Environment(OnboardingViewModel.self) private var viewModel
    
    @State private var selectedRoutes: Set<String> = []
    
    
    
    let routes = [
        ("Trabalho", "briefcase"),
        ("Faculdade", "graduationcap"),
        ("Academia", "dumbbell"),
        ("Mercado", "cart"),
        ("Lazer", "music.note")
    ]
    
    var body: some View {
        ZStack {
            AppColors.levGreenBg.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                
                OnboardingProgressBar(currentStep: .routes)
                
                // Cabeçalho
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quais trajetos\nvocê mais realiza?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Selecione um ou mais destinos frequentes.")
                        .font(.system(size: 16))
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding(.bottom, 10)
                
                // Grelha Flexível para os botões estilo "Pílula"
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                    ForEach(routes, id: \.0) { route in
                        routePill(title: route.0, icon: route.1)
                    }
                }
                
                Spacer()
                
                OnboardingPrimaryButton(
                    title: "Continuar",
                    isDisabled: selectedRoutes.isEmpty,
                    backgroundColor: AppColors.levBlue
                ) {
                    // 🔥 Agora guardamos a seleção no ViewModel antes de avançar!
                    viewModel.routes = Array(selectedRoutes)
                    router.navigate(to: .locationPermission)
                }
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
        .onAppear {
                    AnalyticsManager.shared.trackScreen("Onboarding_Step_Routes")
                }
    }
    
    @ViewBuilder
    private func routePill(title: String, icon: String) -> some View {
        let isSelected = selectedRoutes.contains(title)
        
        Button(action: {
            withAnimation(.snappy) {
                if isSelected {
                    selectedRoutes.remove(title)
                    
                    AnalyticsManager.shared.trackEvent("Onboarding_Route_Toggled", properties: [
                                            "route_name": title,
                                            "action": "removed"
                                        ])
                    
                } else {
                    selectedRoutes.insert(title)
                    
                    AnalyticsManager.shared.trackEvent("Onboarding_Route_Toggled", properties: [
                                            "route_name": title,
                                            "action": "added"
                                        ])
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .black)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .black)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue : Color.white)
            .cornerRadius(16)
            // Pequena sombra para replicar o efeito do design
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RoutesView()
        .environment(AppRouter())
        .environment(OnboardingViewModel())
}
