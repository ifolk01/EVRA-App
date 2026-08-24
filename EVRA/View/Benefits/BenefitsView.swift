import SwiftUI
import SwiftData

struct BenefitsGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var homeVM: HomeViewModel
    
    @Environment(\.colorScheme) var colorScheme
  
    @State private var showRedeemAlert = false
    @State private var alertMessage = ""
    @State private var selectedCoupon: PartnerCoupon? = nil
   
    private var currentPoints: Int {
        homeVM.currentUser?.spendableCarbonPoints ?? 0
    }
    
    var body: some View {
        let isDark = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        
        let bgApp = isDark ? Color("LevGreenDark") : AppColors.levGreenBg
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .black.opacity(0.6)
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        
        ZStack {
            bgApp.ignoresSafeArea()
            
            // MARK: - Conteúdo Principal (Com Blur)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Cabeçalho de Saldo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seus Carbon Points")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(secondaryText)
                        
                        HStack {
                            Image(systemName: "leaf.circle.fill")
                                .foregroundColor(isDark ? neonGreen : .green)
                            Text("\(currentPoints)")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(primaryText)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                        
                        Text("Continue a pedalar para desbloquear mais benefícios exclusivos.")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(secondaryText)
                            .padding(.top, 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Lista de Cupões Mockados
                    VStack(spacing: 16) {
                        // Como os dados reais vão entrar aqui no futuro, o layout já está blindado.
                        ForEach(availableCoupons) { coupon in
                            couponCard(coupon: coupon)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .blur(radius: 5) // 🔥 EFEITO BLUR
            .disabled(true)  // 🔥 BLOQUEIA CLIQUES ENQUANTO ESTÁ "EM BREVE"
            
            // MARK: - FITA ZEBRADA SOBREPOSTA
            ConstructionTapeView()
                .ignoresSafeArea()
        }
        .navigationTitle("Benefícios")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AnalyticsManager.shared.trackScreen("Benefits_Gallery_ComingSoon")
        }
    }
    
    // MARK: - Design do Cupão Individual
    @ViewBuilder
    private func couponCard(coupon: PartnerCoupon) -> some View {
        let isDark = colorScheme == .dark
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        let canAfford = currentPoints >= coupon.costInPoints
        
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(coupon.brandColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: coupon.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(coupon.brandColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(coupon.company)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(coupon.offer)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(coupon.description)
                    .font(.caption2)
                    .foregroundColor(secondaryText)
                    .lineLimit(2)
            }
            Spacer()
            
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: canAfford ? "lock.open.fill" : "lock.fill")
                        .font(.caption2)
                    Text("\(coupon.costInPoints) pts")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(canAfford ? (isDark ? .black : .white) : primaryText)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(canAfford ? accentColor : Color.gray.opacity(isDark ? 0.3 : 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 12, x: 0, y: 6)
        .opacity(canAfford ? 1.0 : 0.6)
    }
}

// MARK: - COMPONENTE: Fita Zebrada "Em Breve"
struct ConstructionTapeView: View {
    var body: some View {
        ZStack {
            // Fundo Amarelo Forte
            Color(red: 1.0, green: 0.85, blue: 0.0)
            
            // Listras Diagonais Pretas desenhadas com SwiftUI Puro!
            HStack(spacing: 20) {
                ForEach(0..<60, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.85))
                        .frame(width: 7)
                        .rotationEffect(.degrees(30)) // Inclinação da listra
                        .scaleEffect(1.5) // Para cobrir as pontas vazias
                }
            }
            
            // O Texto Sobreposto
            Text("EM BREVE")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.0)) // Letra Amarela
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
                .background(Color.black) // Fundo Preto para saltar da fita
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .frame(width: 1000, height: 75) // Uma largura absurda para não cortar as pontas ao girar
        .clipped()
        // A inclinação da fita no ecrã (Do canto superior esquerdo para o inferior direito)
        .rotationEffect(.degrees(45))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Previews
#Preview {
    BenefitsGalleryView(homeVM: HomeViewModel())
        .modelContainer(for: LocalRide.self, inMemory: true)

}

