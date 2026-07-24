import SwiftUI
import SwiftData

struct BenefitsGalleryView: View {

    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // Para voltar atrás se necessário
    
    
    @Bindable var homeVM: HomeViewModel
  
    @State private var showRedeemAlert = false
    @State private var alertMessage = ""
    @State private var selectedCoupon: PartnerCoupon? = nil
   
    private var currentPoints: Int {
        homeVM.currentUser?.spendableCarbonPoints ?? 0
    }
    
    var body: some View {
        ZStack {
            AppColors.levGreenBg.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Cabeçalho de Saldo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seus Carbon Points")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.black.opacity(0.6))
                        
                        HStack {
                            Image(systemName: "leaf.circle.fill")
                                .foregroundColor(.green)
                            Text("\(currentPoints)")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.black)
                        }
                        
                        Text("Continue a pedalar para desbloquear mais benefícios exclusivos.")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Lista de Cupões
                    VStack(spacing: 16) {
                        ForEach(availableCoupons) { coupon in
                            couponCard(coupon: coupon)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Benefícios")
        .navigationBarTitleDisplayMode(.inline)
        // Alerta Interativo de Confirmação/Erro
        .alert("Resgatar Benefício", isPresented: $showErrorAlert) {
            if let coupon = selectedCoupon, currentPoints >= coupon.costInPoints {
                Button("Cancelar", role: .cancel) { }
                Button("Confirmar Resgate") {
                    redeem(coupon: coupon)
                    
                    // 📊 Rastreio da Ação
                    AnalyticsManager.shared.trackEvent("Coupon_Redeemed", properties: [
                        "company": coupon.company,
                        "cost": coupon.costInPoints
                    ])
                }
            } else {
                Button("Entendi", role: .cancel) { }
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            AnalyticsManager.shared.trackScreen("Benefits_Gallery")
        }
    }
    
    // MARK: - Design do Cupão Individual
    @ViewBuilder
    private func couponCard(coupon: PartnerCoupon) -> some View {
        let canAfford = currentPoints >= coupon.costInPoints
        
        HStack(spacing: 16) {
            // Logotipo da Empresa / Ícone
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(coupon.brandColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: coupon.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(coupon.brandColor)
            }
            
            // Informações
            VStack(alignment: .leading, spacing: 4) {
                Text(coupon.company)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Text(coupon.offer)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                
                Text(coupon.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Botão de Custo / Ação
            Button(action: {
                handleTap(on: coupon)
            }) {
                VStack(spacing: 2) {
                    Image(systemName: canAfford ? "lock.open.fill" : "lock.fill")
                        .font(.caption2)
                    Text("\(coupon.costInPoints) pts")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(canAfford ? AppColors.levBlue : Color.gray.opacity(0.5))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        // Efeito visual de inativo se não tiver pontos suficientes
        .opacity(canAfford ? 1.0 : 0.7)
    }
    
    // Estado do alerta partilhado
    @State private var showErrorAlert = false
    
    // MARK: - Lógica de Resgate
    private func handleTap(on coupon: PartnerCoupon) {
        selectedCoupon = coupon
        
        if currentPoints >= coupon.costInPoints {
            alertMessage = "Deseja usar \(coupon.costInPoints) pontos para resgatar o benefício '\(coupon.offer)' na \(coupon.company)?"
        } else {
            let missing = coupon.costInPoints - currentPoints
            alertMessage = "Faltam \(missing) pontos. Continue a pedalar e a poupar CO₂ para desbloquear este benefício!"
        }
        
        showErrorAlert = true
    }
    
    private func redeem(coupon: PartnerCoupon) {
            // 🔥 Integração em tempo real com o SwiftData!
            if let user = homeVM.currentUser {
                withAnimation {
                    user.spendableCarbonPoints -= coupon.costInPoints
                }
                
                do {
                    try modelContext.save()
                    print("🎉 Cupão da \(coupon.company) resgatado e pontos deduzidos com sucesso!")
                } catch {
                    print("❌ Erro ao deduzir pontos: \(error.localizedDescription)")
                }
            }
        }
        
}

