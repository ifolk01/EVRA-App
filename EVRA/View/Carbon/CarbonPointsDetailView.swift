
//
//  CarbonPointsDetailView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 22/07/26.
//

import SwiftUI

struct CarbonPointsDetailView: View {
    var homeVM: HomeViewModel
    
    var body: some View {
        ZStack {
            AppColors.levGreenBg.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // MARK: - Cartão de Status Principal
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColors.levBlue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "bolt.fill")
                                .foregroundColor(AppColors.levBlue)
                                .font(.system(size: 36, weight: .bold))
                        }
                        
                        VStack(spacing: 4) {
                            Text("Os seus Carbon Points")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            let totalPoints = homeVM.currentUser?.totalCarbonPoints ?? 0
                            Text("\(totalPoints)")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundColor(.black)
                            
                            Text("pontos ecológicos totais")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.levBlue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(24)
                    
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
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progresso de Graduação")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nível Atual")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Nível \(currentLevel)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                            
                            if prestigeCount > 0 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Prestígio")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("\(prestigeCount)x")
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                        }
                        
                        // Barra de Progresso Detalhada
                        VStack(spacing: 8) {
                            ProgressView(value: progressRatio)
                                .tint(AppColors.levBlue)
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                            
                            HStack {
                                Text("Faltam \(pointsNeededForNext) pts")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(progressRatio * 100))%")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.levBlue)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(20)
                    
                    // MARK: - Como Ganhar Mais Pontos
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Como Potencializar Pontos")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        PointRuleRow(icon: "bicycle", title: "Pedaladas Diárias", description: "Cada quilómetro percorrido de E-bike soma pontos automáticos baseados no seu impacto evitado.")
                        PointRuleRow(icon: "leaf.fill", title: "Redução de CO2", description: "Substituir veículos poluentes multiplica o ganho ecológico de carbono.")
                        PointRuleRow(icon: "flame.fill", title: "Manter Ofensivas", description: "Pedalar consecutivamente mantém a sua atividade em alta rotação.")
                    }
                    .padding(20)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(20)
                    
                }
                .padding(24)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Carbon Points")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PointRuleRow: View {
    var icon: String
    var title: String
    var description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.levBlue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(AppColors.levBlue)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
