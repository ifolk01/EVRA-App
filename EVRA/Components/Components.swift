//
//  Components.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI
import SwiftData

struct OnboardingProgressBar: View {
    @Environment(AppRouter.self) private var router
    
    // O ecrã onde o utilizador está neste momento
    let currentStep: OnboardingStep
    
    // A ordem oficial do seu fluxo de Onboarding
    let allSteps: [OnboardingStep] = [
        .connectLEV,
        .substitutedVehicle,
        .frequency,
        .routes,
        .locationPermission
    ]
    
    var body: some View {
        // Descobre automaticamente a posição do ecrã atual na lista
        let currentIndex = allSteps.firstIndex(of: currentStep) ?? 0
        
        HStack(spacing: 8) {
            ForEach(0..<allSteps.count, id: \.self) { index in
                Capsule()
                    // Pinta de azul se já passámos ou estamos neste passo
                    .fill(index <= currentIndex ? Color.blue : Color.white.opacity(0.4))
                    .frame(height: 4)
                    // Truque de UX: Aumenta a área invisível para ser fácil de clicar
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Navega para o passo correspondente à barra clicada
                        let stepToNavigate = allSteps[index]
                        router.navigate(to: stepToNavigate)
                    }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Cores Globais do App
/// Em vez de reescrever as cores em todos os ecrãs, usamos esta estrutura.
struct AppColors {
    static let neonGreen = Color(red: 0.85, green: 1.0, blue: 0.3)
    static let levGreenBg = Color(red: 0.76, green: 0.86, blue: 0.55)
    static let levBlue = Color(red: 0.2, green: 0.3, blue: 0.8)
    static let levButtonBg = Color(red: 0.63, green: 0.74, blue: 0.42)
}

// MARK: - Botão Principal Padrão
/// O botão "Continuar" que usamos em todo o Onboarding
struct OnboardingPrimaryButton: View {
    var title: String
    var icon: String? = "arrow.right"
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var backgroundColor: Color = AppColors.levBlue
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                if let icon = icon {
                    Image(systemName: icon)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDisabled ? backgroundColor.opacity(0.5) : backgroundColor)
            .cornerRadius(16)
        }
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Cabeçalho Padrão de Onboarding
/// O Título e Subtítulo padrão (usado no FrequencyView, RoutesView, etc)
struct OnboardingHeaderView: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
            
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(.black.opacity(0.7))
        }
        .padding(.bottom, 10)
    }
}

// MARK: - Linha de Informação (Cards com Ícone)
/// Usado no ecrã de Permissão e futuramente nos Benefícios
struct OnboardingInfoRow: View {
    var icon: String
    var title: String
    var description: String
    var iconColor: Color = AppColors.levBlue
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black.opacity(0.85))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct DashboardStatCard: View {
    var title: String
    var value: String
    var unit: String
    var icon: String
    var iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .padding(10)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
    }
}

struct HoldToFinishButton: View {
    var action: () -> Void
    @State private var pressProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Círculo de fundo
            Circle()
                .stroke(Color.black.opacity(0.2), lineWidth: 6)
                .frame(width: 80, height: 80)
            
            // Círculo de progresso
            Circle()
                .trim(from: 0, to: pressProgress)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
            
            Image(systemName: "stop.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.red)
        }
        // 🔥 Gesto de Pressão Longa Aprimorado
        .onLongPressGesture(minimumDuration: 4.0, maximumDistance: 50, perform: {
            // 1. O que acontece se segurar os 4 segundos completos:
            action()
            // Reseta a barra instantaneamente após finalizar
            withAnimation { pressProgress = 0 }
        }) { isPressing in
            // 2. O que acontece enquanto pressiona ou quando solta:
            if isPressing {
                // Dedo na tela: começa a encher a barra de forma linear por 4 segundos
                withAnimation(.linear(duration: 4.0)) {
                    pressProgress = 1.0
                }
            } else {
                // Dedo levantado ANTES de terminar: a barra esvazia rapidamente (0.5s) e a ação não é chamada
                withAnimation(.easeInOut(duration: 0.5)) {
                    pressProgress = 0.0
                }
            }
        }
    }
}

/// Cartão para exibir o progresso de metas
struct DashboardGoalCard: View {
    var title: String
    var subtitle: String
    var percentageText: String
    
    var body: some View {
        HStack {
            Image(systemName: "target")
                .font(.title)
                .foregroundColor(AppColors.levGreenBg)
                .padding(12)
                .background(Color.black.opacity(0.05))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(percentageText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.levBlue)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
    }
}





struct ProfilePreferencesSection: View {
    @Binding var substitutedVehicle: SubstitutedVehicle
    @Binding var bikeSerialNumber: String
    
    // 🔥 Agora usamos um Set<String> para gerir múltiplas seleções de forma super rápida e sem duplicados
    @Binding var routes: Set<String> // 🔥 Mudou de usualRoutes para routes
    var onSave: (String, Bool) -> Void
    
    @Namespace private var animation
    
    let vehicleOptions: [(label: String, value: SubstitutedVehicle)] = [
        ("Carro", .car),
        ("Uber/99", .appRide),
        ("Moto", .motorcycle),
        ("Ônibus", .bus),
        ("Metrô", .subway)
    ]
    
    let routeOptions = ["Trabalho", "Faculdade", "Lazer", "Academia", "Mercado"]
    
    // Configuração da grelha adaptável para os chips de trajeto
    let gridColumns = [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 10)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Preferências de Mobilidade")
                .font(.headline)
                .foregroundColor(.black)
            
            // 1. Veículo a ser substituído (Cápsulas Deslizantes)
            VStack(alignment: .leading, spacing: 10) {
                Text("Veículo Habitual Substituído")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vehicleOptions, id: \.value) { option in
                            Text(option.label)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .foregroundColor(substitutedVehicle == option.value ? .white : .black.opacity(0.7))
                                .background(
                                    ZStack {
                                        Capsule()
                                            .fill(Color.gray.opacity(0.15))
                                        
                                        if substitutedVehicle == option.value {
                                            Capsule()
                                                .fill(AppColors.levBlue)
                                                .matchedGeometryEffect(id: "VEHICLE_TAB", in: animation)
                                        }
                                    }
                                )
                                .onTapGesture {
                                    withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.6)) {
                                        substitutedVehicle = option.value
                                    }
                                    UserDefaults.standard.set(option.value.rawValue, forKey: "user_substituted_vehicle")
                                    onSave("Veículo habitual alterado para \(option.label) com sucesso!", true)
                                }
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 2)
                }
            }
            
            // 2. Trajetos Habituais (NOVO DESIGN COM CHIPS MÚLTIPLOS)
            VStack(alignment: .leading, spacing: 12) {
                Text("Trajetos Habituais / Frequentes")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                    ForEach(routeOptions, id: \.self) { route in
                        let isSelected = routes.contains(route)
                        
                        HStack(spacing: 6) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 14, weight: .bold))
                            Text(route)
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(isSelected ? .white : .black.opacity(0.7))
                        .background(
                            Capsule()
                                .fill(isSelected ? AppColors.levBlue : Color.gray.opacity(0.15))
                        )
                        // Animação de seleção e remoção
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSelected {
                                    routes.remove(route)
                                } else {
                                    routes.insert(route)
                                }                            }
                            // Salva silenciosamente sempre que adiciona ou remove um trajeto
                            onSave("", false)
                        }
                    }
                }
            }
            
            // 3. Série da Bicicleta
            VStack(alignment: .leading, spacing: 10) {
                Text("Número de Série da E-Bike")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    TextField("Ex: QWD-2026-9812", text: $bikeSerialNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        onSave("Número de série da E-Bike atualizado com sucesso!", true)
                    }) {
                        Text("Salvar")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(AppColors.levBlue)
                            .cornerRadius(10)
                    }
                }
            }
            
         
        }
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(24)
    }
}

struct PartnerCoupon: Identifiable {
    let id = UUID()
    let company: String
    let offer: String
    let description: String
    let costInPoints: Int
    let brandColor: Color
    let iconName: String // Pode ser um ícone do sistema ou o nome da imagem nos Assets
}

// Uma lista de exemplo com grandes marcas
let availableCoupons: [PartnerCoupon] = [
    PartnerCoupon(company: "FARM", offer: "15% OFF", description: "Em toda a nova coleção de verão.", costInPoints: 300, brandColor: Color.orange, iconName: "leaf.fill"),
    PartnerCoupon(company: "Magalu", offer: "Frete Grátis", description: "Válido para produtos selecionados na app.", costInPoints: 150, brandColor: Color.blue, iconName: "bag.fill"),
    PartnerCoupon(company: "Centauro", offer: "R$ 50 de Desconto", description: "Nas compras acima de R$ 200.", costInPoints: 500, brandColor: Color.red, iconName: "figure.run"),
    PartnerCoupon(company: "iFood", offer: "Cupom de R$ 20", description: "Válido para o seu próximo pedido.", costInPoints: 400, brandColor: Color.red.opacity(0.8), iconName: "takeoutbag.and.cup.and.straw")
]

/// Cartão horizontal para os benefícios e lojas parceiras
struct DashboardBenefitsLinkCard: View {

    @Bindable var homeVM: HomeViewModel

    var body: some View {
        
        let currentPoints = homeVM.currentUser?.spendableCarbonPoints ?? 0
        NavigationLink(destination: BenefitsGalleryView(homeVM: homeVM)){
            HStack(spacing: 16) {
                // Ícone de Destaque
                ZStack {
                    Circle()
                        .fill(AppColors.levBlue.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "gift.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.levBlue)
                }
                
                // Textos
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trocar Pontos")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("Você tem \(currentPoints) pts disponíveis")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Seta indicativa
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.levBlue)
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(20)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
       
    }
}

/// Banner flutuante quando há uma viagem em andamento
struct ActiveTrackingBanner: View {
    var durationText: String
    var isBlinking: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("A rastrear trajeto...")
                    .font(.caption)
                    .foregroundColor(AppColors.levBlue)
                Text("Tempo: \(durationText)")
                    .font(.headline)
            }
            Spacer()
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .opacity(isBlinking ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: isBlinking)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(AppColors.levBlue, lineWidth: 2)
        )
    }
}
