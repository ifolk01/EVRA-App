
//
//  CarbonPointsDetailView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 22/07/26.
//

import SwiftUI


struct CarbonPointsDetailView: View {
    var homeVM: HomeViewModel
    
    // 🌙 Detetor de Tema
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let isDark = colorScheme == .dark
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        
        let bgApp = isDark ? Color("LevGreenDark") : AppColors.levGreenBg
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        
        ZStack {
            bgApp.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // MARK: - Cartão de Status Principal
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "bolt.fill")
                                .foregroundColor(accentColor)
                                .font(.system(size: 36, weight: .bold))
                        }
                        
                        VStack(spacing: 6) {
                            Text("Seus Carbon Points")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(secondaryText)
                            
                            let totalPoints = homeVM.currentUser?.totalCarbonPoints ?? 0
                            let spendablePoints = homeVM.currentUser?.spendableCarbonPoints ?? 0
                            
                            Text("\(totalPoints)")
                                .font(.system(size: 54, weight: .black, design: .rounded))
                                .foregroundColor(primaryText)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            
                            Text("XP Acumulado (Não se perde)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(accentColor)
                            
                            Text("Saldo disponível para troca: \(spendablePoints) pts")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(isDark ? secondaryText : .green)
                                .padding(.top, 8)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(28)
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 15, x: 0, y: 8)
                    
                    // MARK: - Detalhes do Nível Atual
                    let totalPoints = homeVM.currentUser?.totalCarbonPoints ?? 0
                    let pointsPerLevel = 1500
                    let maxLevel = 10
                    let prestigeCount = totalPoints / (pointsPerLevel * maxLevel)
                    let pointsInCurrentCycle = totalPoints % (pointsPerLevel * maxLevel)
                    let currentLevel = (pointsInCurrentCycle / pointsPerLevel) + 1
                    let pointsInCurrentLevel = pointsInCurrentCycle % pointsPerLevel
                    let pointsNeededForNext = pointsPerLevel - pointsInCurrentLevel
                    let progressRatio = Double(pointsInCurrentLevel) / Double(pointsPerLevel)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Progresso de Graduação")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(primaryText)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nível Atual")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(secondaryText)
                                Text("Nível \(currentLevel)")
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(primaryText)
                            }
                            
                            Spacer()
                            
                            if prestigeCount > 0 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Prestígio")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(secondaryText)
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("\(prestigeCount)x")
                                            .fontWeight(.black)
                                            .foregroundColor(primaryText)
                                    }
                                }
                            }
                        }
                        
                        // Barra de Progresso Segura e Desportiva
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .frame(width: geometry.size.width, height: 12)
                                        .foregroundColor(isDark ? Color.white.opacity(0.1) : Color(UIColor.systemGray5))
                                    
                                    Capsule()
                                        .frame(width: geometry.size.width * CGFloat(progressRatio), height: 12)
                                        .foregroundColor(accentColor)
                                        .shadow(color: isDark ? accentColor.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 0)
                                }
                            }
                            .frame(height: 12)
                            
                            HStack {
                                Text("Faltam \(pointsNeededForNext) pts")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(secondaryText)
                                Spacer()
                                Text("\(Int(progressRatio * 100))%")
                                    .font(.caption2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                    .padding(24)
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 12, x: 0, y: 6)
                    
                    // MARK: - Como Ganhar Mais Pontos
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Como Potencializar Pontos")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(primaryText)
                        
                        PointRuleRow(icon: "bicycle", title: "Pedaladas Diárias", description: "Cada quilómetro percorrido de E-bike soma pontos automáticos baseados no seu impacto evitado.")
                        PointRuleRow(icon: "leaf.fill", title: "Redução de CO2", description: "Substituir veículos poluentes multiplica o ganho ecológico de carbono.")
                        PointRuleRow(icon: "flame.fill", title: "Manter Ofensivas", description: "Pedalar consecutivamente mantém a sua atividade em alta rotação.")
                    }
                    .padding(24)
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 12, x: 0, y: 6)
                    
                }
                .padding(24)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Carbon Points")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Componente das Regras de Pontuação
struct PointRuleRow: View {
    @Environment(\.colorScheme) var colorScheme
    var icon: String
    var title: String
    var description: String
    
    var body: some View {
        let isDark = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .font(.system(size: 18, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(secondaryText)
                    .fixedSize(horizontal: false, vertical: true) // Força o texto a não se cortar!
            }
        }
    }
}
