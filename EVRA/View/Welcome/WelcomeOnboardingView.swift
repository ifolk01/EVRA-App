//
//  Untitled.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 20/07/26.
//




import SwiftUI

struct WelcomeOnboardingView: View {
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        ZStack {
            // Fundo verde do aplicativo
            // Se AppColors.levBackground não for este verde, você pode usar Color("LevGreen")
            AppColors.levGreenBg.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                Spacer()
                
                // Imagem central (Bicicleta)
                HStack {
                    Spacer()
                    Image("imageLevBike") // Substitua pelo nome do seu Asset
                        .resizable()
                        .scaledToFit()
                        // Ajuste a altura máxima se a imagem estiver muito grande
                        .frame(maxHeight: 200)
                    Spacer()
                }
                
                Spacer()
                
                // Seção de Textos (Alinhados à esquerda)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pedale, acompanhe\nseu impacto e\ndesbloqueie\nbenefícios.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true) // Evita cortes em telas menores
                    
                    Text("Transforme cada trajeto em recompensas reais.")
                        .font(.body)
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding(.bottom, 40) // Espaço entre o texto e o botão
                
                // Botão "Começar"
                Button(action: {
                    router.navigate(to: .connectLEV)
                }) {
                    HStack {
                        Text("Começar")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.levBlue)
                    .cornerRadius(16)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        // Esconde a barra nativa do NavigationStack para que o fundo verde cubra tudo
        .navigationBarHidden(true)
    }
}

#Preview {
    WelcomeOnboardingView()
        .environment(AppRouter())
}
