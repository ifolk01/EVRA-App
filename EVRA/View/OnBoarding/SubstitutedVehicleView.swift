//
//  SubstitutedVehicle.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI

struct SubstitutedVehicleView: View {
    @Environment(AppRouter.self) private var router
    @Environment(OnboardingViewModel.self) private var viewModel
    
    // Estado local para a animação da seleção
    @State private var selectedVehicle: SubstitutedVehicle? = nil
        
    // Lista de opções baseada no nosso Model.swift
    let options: [(SubstitutedVehicle, String, String)] = [
        (.car, "Carro", "car.fill"),
        (.motorcycle, "Moto", "motorcycle"),
        (.appRide, "Uber / Apps", "car.side.fill"),
        (.bus, "Ônibus", "bus.fill"),
        (.subway, "Metrô", "tram.fill"),
        (.walking, "Caminhada", "figure.walk")
    ]
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 3) {
           
            OnboardingProgressBar(currentStep: .substitutedVehicle)
               
                            .padding(.horizontal, 24)
       
           
            // Cabeçalho
            VStack(alignment: .leading, spacing: 16) {
                
             
                
                Text("Qual transporte sua bicicleta mais substitui no dia a dia?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Para calcularmos o seu impacto ambiental com precisão, conte-nos que transporte usaria se não estivesse de bike-E.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.top, 10)
            .padding(.horizontal, 24)
            
            // Grelha de Seleção (2 colunas)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.0) { option in
                        vehicleCard(vehicle: option.0, title: option.1, icon: option.2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
            }
            
            Spacer()
            
            // Botão de Avançar
            Button(action: {
                if let vehicle = selectedVehicle {
                    // 1. Guarda o veículo no "carrinho" da ViewModel
                    viewModel.substitutedVehicle = vehicle
                    router.navigate(to: .frequency)
                }
            }) {
                Text("Continuar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedVehicle == nil ? Color.gray.opacity(0.5) : AppColors.levBlue)
                    .cornerRadius(15)
            }
            .disabled(selectedVehicle == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(AppColors.levGreenBg.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        
        .onAppear {
                    AnalyticsManager.shared.trackScreen("Onboarding_Step_Vehicle")
                }
    }
    
    // Sub-view para desenhar cada cartão de veículo de forma limpa
    @ViewBuilder
    private func vehicleCard(vehicle: SubstitutedVehicle, title: String, icon: String) -> some View {
        let isSelected = selectedVehicle == vehicle
        
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedVehicle = vehicle
            }
            AnalyticsManager.shared.trackEvent("Onboarding_Vehicle_Selected", properties: [
                            "vehicle_name": title
                        ])
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ?  AppColors.levBlue : .gray)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ?  AppColors.levBlue : .black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ?  AppColors.levBlue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ?  AppColors.levBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SubstitutedVehicleView()
        .environment(AppRouter())
        .environment(OnboardingViewModel())
}
