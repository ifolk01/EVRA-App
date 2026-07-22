//
//  ConnectBikeView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI

struct ConnectBikeView: View {
    // Injetamos o Router para navegar e a ViewModel para guardar os dados
    @Environment(AppRouter.self) private var router
    @Environment(OnboardingViewModel.self) private var viewModel
    
    // Estado local para o campo de texto
    @State private var serialNumber: String = ""
    
    let levBlue = Color(red: 0.2, green: 0.3, blue: 0.8)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingProgressBar(currentStep: .connectLEV)
            // Cabeçalho
            VStack(alignment: .leading, spacing: 8) {
                Text("Conecte sua bike")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Insira o número de série pra vincular sua bike")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.gray)
                
                HStack{
                    Spacer()
                    Image("imageLevBike")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                    
                    Spacer()

                }
               
              
            }
            .padding(.top, 30)
            
            // Campo de Entrada
            VStack(alignment: .leading, spacing: 8) {
                Text("NÚMERO DE SÉRIE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                TextField("LEV-XXXX-XXXX", text: $serialNumber)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                
                Text("      O número de série está localizado no quadro da sua bike")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Botão de Avançar
            Button(action: {
                // 1. Guarda o dado no "carrinho" da ViewModel
                viewModel.bikeSerialNumber = serialNumber
                // 2. Navega para o próximo ecrã do seu fluxo
                router.navigate(to: .substitutedVehicle)
            }) {
                Text("Continuar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(serialNumber.isEmpty ? Color.gray.opacity(0.5) : AppColors.levBlue)
                    .cornerRadius(15)
            }
            .disabled(serialNumber.isEmpty)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        
        .background(AppColors.levGreenBg.edgesIgnoringSafeArea(.all))

        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    // Preview mockado para você testar no Canvas do Xcode
    ConnectBikeView()
        .environment(AppRouter())
        .environment(OnboardingViewModel())
}
