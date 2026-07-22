//
//  GroupsView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 21/07/26.
//

import SwiftUI

struct GroupsView: View {
    @StateObject private var viewModel = GroupsViewModel() // 🔥 O cérebro foi ligado!
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.levGreenBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // MARK: - Cabeçalho do Grupo
                    VStack(spacing: 8) {
//                        Image(systemName: "graduationcap.fill")
//                            .font(.system(size: 20))
//                            .foregroundColor(AppColors.levBlue)
//                            .padding()
//                            .background(Circle().fill(Color.white.opacity(0.8)))
//                            .shadow(radius: 5)
                        
                        Text(viewModel.groupName) // 🔥 Nome real do Geocoding
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.black)
                        
                        Text("\(viewModel.memberCount) ciclistas ativos") // 🔥 Contagem real do CloudKit
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    Picker("Visão", selection: $selectedTab) {
                        Text("Ranking Mensal").tag(0)
                        Text("Feed ao Vivo").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    
                    
                    ScrollView(showsIndicators: false) {
                        if selectedTab == 0 {
                            // 🔥 Passa os dados reais para a secção de ranking
                            RankingSection(rankings: viewModel.rankings)
                        } else {
                            LiveFeedSection(feed: viewModel.liveFeed)                        }
                    }
                    .refreshable {
                                            await viewModel.refreshData()
                                        }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct LiveFeedSection: View {
    var feed: [GroupsViewModel.FeedActivity]
    
    var body: some View {
        VStack(spacing: 16) {
            if feed.isEmpty {
                Text("Ainda sem atividades recentes no grupo.\nSeja o primeiro a pedalar! ")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
            } else {
                ForEach(feed) { activity in
                    FeedCard(
                        name: activity.name,
                        action: activity.action,
                        distance: String(format: "%.1f km", activity.distance),
                        time: timeAgoString(from: activity.timestamp)
                    )
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

// MARK: - Secção de Ranking (O Pódio)
struct RankingSection: View {
    var rankings: [GroupsViewModel.RankingUser]
    
    var body: some View {
        VStack(spacing: 20) {
            if rankings.isEmpty {
                Text("Seja o primeiro a pedalar neste grupo!")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                // Resto da Tabela (Ignorando o pódio complexo no MVP para focar na lista real)
                VStack(spacing: 12) {
                    ForEach(Array(rankings.enumerated()), id: \.element.id) { index, user in
                        RankingRow(
                            position: index + 1,
                            name: user.name,
                            points: "\(user.points) pts",
                            co2: String(format: "%.1f kg", user.co2 / 1000.0)
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}


// MARK: - Componentes Visuais

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

struct RankingRow: View {
    var position: Int
    var name: String
    var points: String
    var co2: String
    
    var body: some View {
        HStack {
            Text("\(position)º")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black.opacity(0.5))
                .frame(width: 30, alignment: .leading)
            
            Text(name)
                .font(.headline)
                .foregroundColor(.black)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(points)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.levBlue)
                Text("\(co2) CO2")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        
    }
}

struct FeedCard: View {
    var name: String
    var action: String
    var distance: String
    var time: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppColors.levBlue.opacity(0.15))
                .frame(width: 45, height: 45)
                .overlay(Image(systemName: "bicycle").foregroundColor(AppColors.levBlue))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(name).fontWeight(.bold).foregroundColor(.black)
                    Text(action).foregroundColor(.black.opacity(0.8))
                }
                .font(.subheadline)
                .lineLimit(2)
                
                HStack {
                    Text(distance).fontWeight(.bold).foregroundColor(AppColors.levBlue)
                    Text("• \(time)").foregroundColor(.gray)
                }
                .font(.caption)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

#Preview {
    GroupsView()
}
