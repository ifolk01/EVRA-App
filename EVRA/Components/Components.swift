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
    @Environment(\.colorScheme) var colorScheme
    var title: String
    var value: String
    var unit: String
    var icon: String
    var iconColor: Color
    
    var body: some View {
        let isDarkTheme = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let cardBg = isDarkTheme ? deepDark : .white
        let primaryText = isDarkTheme ? Color.white : .black
        let secondaryText = isDarkTheme ? Color.white.opacity(0.6) : .gray
        let activeIconColor = isDarkTheme ? neonGreen : iconColor
        
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(activeIconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(activeIconColor)
                    .font(.system(size: 20, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(secondaryText)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(primaryText)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(secondaryText)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.3 : 0.04), radius: 12, x: 0, y: isDarkTheme ? 8 : 6)
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
    @Environment(\.colorScheme) var colorScheme
    var title: String
    var subtitle: String
    var percentageText: String
    
    var body: some View {
        let isDarkTheme = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let cardBg = isDarkTheme ? deepDark : .white
        let primaryText = isDarkTheme ? Color.white : .black
        let secondaryText = isDarkTheme ? Color.white.opacity(0.6) : .gray
        let accentColor = isDarkTheme ? neonGreen : AppColors.levBlue
        
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "target")
                    .foregroundColor(accentColor)
                    .font(.system(size: 24, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(secondaryText)
            }
            Spacer()
            
            Text(percentageText)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(accentColor)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.3 : 0.04), radius: 12, x: 0, y: isDarkTheme ? 8 : 6)
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
    @Environment(\.colorScheme) var colorScheme
    var homeVM: HomeViewModel
    
    var body: some View {
        let isDarkTheme = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let cardBg = isDarkTheme ? deepDark : .white
        let primaryText = isDarkTheme ? Color.white : .black
        let secondaryText = isDarkTheme ? Color.white.opacity(0.6) : .gray
        let accentColor = isDarkTheme ? neonGreen : Color.purple
        
        NavigationLink(destination: BenefitsGalleryView(homeVM: homeVM)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "gift.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 24, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trocar Pontos")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(primaryText)
                    
                    Text("Você tem \(homeVM.currentUser?.spendableCarbonPoints ?? 0) pts disponíveis")
                        .font(.subheadline)
                        .foregroundColor(secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(secondaryText)
                    .font(.system(size: 16, weight: .bold))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(isDarkTheme ? 0.3 : 0.04), radius: 12, x: 0, y: isDarkTheme ? 8 : 6)
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Carrossel de Destaques (Dinâmico)
struct HighlightsCarouselView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var globalLeader: String
    var globalPoints: Int
    var topCity: String
    var topVehicle: String
    var localMembers: Int
    var isLoading: Bool
    
    var body: some View {
        let isDark = colorScheme == .dark
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Destaques da Comunidade")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isDark ? .white : .black)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    
                    // Cartão 1: O Líder Supremo
                    HighlightCard(
                        icon: "trophy.fill",
                        iconColor: .yellow,
                        title: "1º Lugar Global",
                        subtitle: "\(globalLeader) com \(globalPoints) pts!",
                        isLoading: isLoading
                    )
                    
                    // Cartão 2: A Cidade que mais pedala
                    HighlightCard(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "Cidade em Alta",
                        subtitle: "\(topCity) com mais registros.",
                        isLoading: isLoading
                    )
                    
                    // Cartão 3: O Modal Campeão
                    HighlightCard(
                        icon: topVehicle == "Carro" ? "car.fill" : "bicycle",
                        iconColor: AppColors.levBlue,
                        title: "Modal em Alta",
                        subtitle: "\(topVehicle) lidera nas trocas.",
                        isLoading: isLoading
                    )
                    
                    // Cartão 4: A sua "Sala"
                    HighlightCard(
                        icon: "person.3.fill",
                        iconColor: .green,
                        title: "A Sua Região",
                        subtitle: "\(localMembers) ciclistas a competir.",
                        isLoading: isLoading
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
    }
}

func getInitials(from name: String) -> String {
    let words = name.split(separator: " ")
    if words.count >= 2 {
        let first = words.first?.first?.uppercased() ?? ""
        let last = words.last?.first?.uppercased() ?? ""
        return first + last
    } else if let first = words.first?.prefix(2).uppercased() {
        return String(first)
    }
    return "CL" // "CL" para Ciclista, caso falhe
}
struct FeedCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var name: String
    var action: String
    var distance: String
    var time: String
    
    var body: some View {
        let isDark = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        
        HStack(spacing: 16) {
            // 🔥 Avatar com a inicial
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(getInitials(from: name))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Nome e Ação
                HStack(spacing: 4) {
                    Text(name)
                        .fontWeight(.bold)
                        .foregroundColor(primaryText)
                        .lineLimit(1) // Protege nomes gigantes
                    
                    Text(action)
                        .foregroundColor(secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8) // Permite encolher um pouco
                }
                .font(.subheadline)
                
                // Distância e Tempo
                HStack {
                    Text(distance)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                    
                    Text("• \(time)")
                        .foregroundColor(secondaryText)
                }
                .font(.caption)
            }
            Spacer()
        }
        .padding(16)
        .background(cardBg)
        // O toque da Apple: Cantos contínuos e sombra dinâmica
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 10, x: 0, y: 5)
    }
    
    // (A sua função getInitials já deve estar algures no ficheiro ou pode mantê-la onde está!)
}

struct RankingRow: View {
    @Environment(\.colorScheme) var colorScheme
    var position: Int
    var name: String
    var points: String
    var co2: String
    
    var body: some View {
        let isDark = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        
        HStack(spacing: 16) {
            
            // Posição (O número do pódio)
            Text("\(position)º")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(secondaryText)
                .frame(width: 35, alignment: .leading)
            
            // Avatar Placeholder Circular
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                Text(getInitials(from: name))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor))
            }
            
            // Nome e Estatísticas Pessoais
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                
                Text("\(co2) evitados")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(secondaryText)
            }
            
            Spacer()
            
            // Pontuação Destacada
            VStack(alignment: .trailing, spacing: 2) {
                Text(points)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(accentColor)
            }
        }
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 10, x: 0, y: 5)
    }
}


struct EmptyStateView: View {
    var message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 40)
    }
}




struct PodiumBar: View {
    var name: String
    var points: String
    var position: Int
    var height: CGFloat
    var color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.levBlue)
                    .frame(width: 80, height: height)
                
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .overlay(Text("\(position)").font(.caption).bold().foregroundColor(.white))
                    .offset(y: -15)
            }
            
            Text("\(points) pts")
                .font(.caption2)
                .foregroundColor(.black.opacity(0.7))
        }
    }
}


struct LiveFeedSection: View {
    var feed: [GroupsViewModel.FeedActivity]
    
    var body: some View {
        VStack(spacing: 16) {
            if feed.isEmpty {
                EmptyStateView(message: "Ainda sem atividades recentes na sua localização.\nSeja o primeiro a pedalar!")
            } else {
                ForEach(feed) { activity in
                    FeedCard(
                        name: activity.name,
                        action: activity.action,
                        distance: String(format: "%.1f km", activity.distance),
                        time: timeAgoString(from: activity.timestamp)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // Pequena função para transformar a data real em texto amigável (ex: "Há 5 min")
    private func timeAgoString(from date: Date) -> String {
        let minutes = Int(-date.timeIntervalSinceNow / 60)
        if minutes < 1 { return "Agora mesmo" }
        if minutes < 60 { return "Há \(minutes) min" }
        let hours = minutes / 60
        if hours < 24 { return "Há \(hours)h" }
        return "Há mais de 1 dia"
    }
}

struct HighlightCard: View {
    @Environment(\.colorScheme) var colorScheme
    var icon: String
    var iconColor: Color
    var title: String
    var subtitle: String
    var isLoading: Bool
    
    var body: some View {
        let isDark = colorScheme == .dark
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        
        HStack(spacing: 16) {
            
            // Ícone num círculo suave
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 20, weight: .bold))
            }
            
            // Textos com proteção responsiva
            VStack(alignment: .leading, spacing: 4) {
                if isLoading {
                    // Efeito de "Skeleton" enquanto carrega do CloudKit
                    RoundedRectangle(cornerRadius: 4)
                        .fill(secondaryText.opacity(0.2))
                        .frame(width: 100, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(secondaryText.opacity(0.1))
                        .frame(width: 140, height: 12)
                } else {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(primaryText)
                        .lineLimit(1) // Protege contra quebras
                        .minimumScaleFactor(0.8) // Permite encolher um pouco se precisar
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(secondaryText)
                        .lineLimit(1) // Protege contra quebras
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding(16)
        .frame(minWidth: 260, alignment: .leading) // Garante que todos têm o mesmo tamanho mínimo no carrossel
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 10, x: 0, y: 5)
    }
}
