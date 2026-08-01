//
//  GroupsView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 21/07/26.
//

import SwiftUI

struct GroupsView: View {
    @StateObject private var viewModel = GroupsViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.levGreenBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // MARK: - 1. Novo Cabeçalho (Estilo Pílula da Imagem)
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.black)
                            Text(viewModel.groupName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                      
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        Spacer()
                        
                    
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            // MARK: - 2. Carrossel de Destaques (Interatividade)
                            HighlightsCarouselView(
                                                    globalLeader: viewModel.globalTopUser,
                                                    globalPoints: viewModel.globalTopPoints,
                                                    topCity: viewModel.topActiveCity,
                                                    topVehicle: viewModel.topVehicle,
                                                    localMembers: viewModel.memberCount,
                                                    isLoading: viewModel.isLoadingHighlights
                                                )
                            
                            // MARK: - 3. Toggle de Visão
                            Picker("Visão", selection: $selectedTab) {
                                Text("Feed ao Vivo").tag(0)
                                Text("Ranking Mensal").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 24)
                            
                            // MARK: - 4. Conteúdo Principal
                            if selectedTab == 0 {
                                LiveFeedSection(feed: viewModel.liveFeed)
                            } else {
                                RankingSection(rankings: viewModel.rankings)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .refreshable {
                        await viewModel.refreshData()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                            // 1. Verifica se trocou de veículo
                            viewModel.checkVehiclePreference()
                            
                            // 2. Força a atualização dos dados do Ranking e Feed toda a vez que abrir a aba!
                            Task {
                                await viewModel.refreshData()
                            }
                        }
        }
    }
}



// MARK: - Secção de Ranking (O Pódio)
struct RankingSection: View {
    var rankings: [GroupsViewModel.RankingUser]
    
    var body: some View {
        VStack(spacing: 20) {
            if rankings.isEmpty {
                Text("Seja o primeiro a pedalar!!")
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






#Preview {
    GroupsView()
}
