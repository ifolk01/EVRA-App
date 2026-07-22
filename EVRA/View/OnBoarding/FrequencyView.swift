import SwiftUI

struct FrequencyView: View {
    @Environment(AppRouter.self) private var router
    @Environment(OnboardingViewModel.self) private var viewModel
    
    @State private var selectedFrequency: String? = nil
    
    // Cores baseadas no seu design
    let levGreenBg = Color(red: 0.76, green: 0.86, blue: 0.55) // Verde fundo
    let levButtonBg = Color(red: 0.63, green: 0.74, blue: 0.42) // Verde escuro do botão
    
    let options = [
        ("Todo dia", "5-7x por semana"),
        ("Frequentemente", "3-4x por semana"),
        ("Às vezes", "1-2x por semana"),
        ("Ocasionalmente", "Algumas vezes por mês")
    ]
    
    var body: some View {
        ZStack {
            levGreenBg.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                
                // Barra de Progresso
                OnboardingProgressBar(currentStep: .frequency)
               
                
                // Cabeçalho
                VStack(alignment: .leading, spacing: 8) {
                    Text("Com que frequência\nvocê utiliza sua LEV?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Personalizamos sua experiência com base no\nseu uso.")
                        .font(.system(size: 16))
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding(.bottom, 10)
                
                // Lista de Opções
                VStack(spacing: 16) {
                    ForEach(options, id: \.0) { option in
                        frequencyCard(title: option.0, subtitle: option.1)
                    }
                }
                
                Spacer()
                
                OnboardingPrimaryButton(
                    title: "Continuar",
                    isDisabled: selectedFrequency == nil, // Ou selectedRoutes.isEmpty
                    backgroundColor: AppColors.levBlue
                ) {
                    // O código de navegação vai aqui
                    router.navigate(to: .routes)
                }
              
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
        
        .onAppear {
                    AnalyticsManager.shared.trackScreen("Onboarding_Step_Frequency")
                }
    }
    
    @ViewBuilder
    private func frequencyCard(title: String, subtitle: String) -> some View {
        let isSelected = selectedFrequency == title
        
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFrequency = title
            }
            
            AnalyticsManager.shared.trackEvent("Onboarding_Frequency_Selected", properties: [
                            "frequency": title
                        ])
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Círculo de seleção
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FrequencyView()
        .environment(AppRouter())
        .environment(OnboardingViewModel())
}
