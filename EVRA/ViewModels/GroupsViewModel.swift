//
//  GroupsViewModel.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 21/07/26.
//

import SwiftUI
import CoreLocation
import CloudKit
import Combine
import MapKit

@MainActor
class GroupsViewModel: NSObject, ObservableObject {
    @Published var groupName: String = "Ranking Global"
    @Published var memberCount: Int = 0
    
    
    @Published var isLoadingHighlights: Bool = true
    @Published var globalTopUser: String = "Ciclista Campeão"
    @Published var globalTopPoints: Int = 0
    @Published var topActiveCity: String = "Nome da Cidade"
    @Published var topVehicle: String = "Transporte"
    
    // Arrays que vão guardar os dados REAIS vindos da nuvem
    @Published var rankings: [RankingUser] = []
    @Published var liveFeed: [FeedActivity] = []
    
    // 🔥 NOVA VARIÁVEL: Guarda o nome exato da sala na nuvem (com a data) para não haver erros na pesquisa
    private var searchGroupName: String = ""
    
    private let locationManager = CLLocationManager()
    private let publicDB = CKContainer.default().publicCloudDatabase
    
    // Estruturas para descodificar os dados do CloudKit
    struct RankingUser: Identifiable {
        let id = UUID()
        let name: String
        let points: Int
        let co2: Double
    }
    
    struct FeedActivity: Identifiable {
        let id = UUID()
        let name: String
        let action: String
        let distance: Double
        let timestamp: Date
    }
    
    override init() {
            // 🔥 A MÁGICA GLOBAL: O nome da sala agora é universal por mês!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-yyyy"
            let currentMonthYear = dateFormatter.string(from: Date())
            
            self.searchGroupName = "Global - \(currentMonthYear)"
            
        super.init()
            Task {
                await refreshData()
            }
        }
    func refreshData() async {
            isLoadingHighlights = true
            await fetchGroupData(for: self.searchGroupName)
            await fetchGlobalHighlights()
        }
        
        // Como agora é tudo global, não precisamos verificar mudança de veículo
        func checkVehiclePreference() {
            Task {
                await refreshData()
            }
        }
        
        private func fetchGroupData(for group: String) async {
            let rankPredicate = NSPredicate(format: "groupName == %@", group)
            let rankQuery = CKQuery(recordType: "PublicLeaderboard", predicate: rankPredicate)
            rankQuery.sortDescriptors = [
                NSSortDescriptor(key: "totalCarbonPoints", ascending: false),
                NSSortDescriptor(key: "totalDistance", ascending: false)
            ]
            
            let feedPredicate = NSPredicate(format: "groupName == %@", group)
            let feedQuery = CKQuery(recordType: "PublicFeedActivity", predicate: feedPredicate)
            feedQuery.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                let (rankMatches, _) = try await publicDB.records(matching: rankQuery)
                let (feedMatches, _) = try await publicDB.records(matching: feedQuery)
                
                var fetchedRankings: [RankingUser] = []
                var fetchedFeed: [FeedActivity] = []
                
                for match in rankMatches {
                    if case .success(let record) = match.1 {
                        fetchedRankings.append(RankingUser(
                            name: record["userName"] as? String ?? "Ciclista Desconhecido",
                            points: record["totalCarbonPoints"] as? Int ?? 0,
                            co2: record["totalCO2"] as? Double ?? 0.0
                        ))
                    }
                }
                
                for match in feedMatches {
                    if case .success(let record) = match.1 {
                        let co2 = record["co2Avoided"] as? Double ?? 0.0
                        let co2Formatted = co2 > 1000 ? String(format: "%.1f kg", co2 / 1000.0) : String(format: "%.0f g", co2)
                        
                
                        
                        fetchedFeed.append(FeedActivity(
                            name: record["userName"] as? String ?? "Ciclista",
                            action: " - evitou \(co2Formatted)",
                            distance: record["distance"] as? Double ?? 0.0,
                            timestamp: record["date"] as? Date ?? Date()
                        ))
                    }
                }
                
                await MainActor.run {
                    self.rankings = fetchedRankings
                    self.memberCount = fetchedRankings.count
                    self.liveFeed = fetchedFeed
                }
            } catch {
                print("❌ Erro ao buscar dados do CloudKit: \(error.localizedDescription)")
            }
        }
        
    func fetchGlobalHighlights() async {
            let leaderQuery = CKQuery(recordType: "PublicLeaderboard", predicate: NSPredicate(value: true))
            leaderQuery.sortDescriptors = [NSSortDescriptor(key: "totalCarbonPoints", ascending: false)]
            
            // 🔥 TRAZENDO DE VOLTA A PESQUISA DO FEED PARA OS DESTAQUES
            let globalFeedQuery = CKQuery(recordType: "PublicFeedActivity", predicate: NSPredicate(value: true))
            globalFeedQuery.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                let (leaderMatches, _) = try await publicDB.records(matching: leaderQuery)
                let (feedMatches, _) = try await publicDB.records(matching: globalFeedQuery)
                
                var leaderName = "Ciclista"
                var leaderPoints = 0
                
                if let firstMatch = leaderMatches.first, case .success(let record) = firstMatch.1 {
                    leaderName = record["userName"] as? String ?? "Ciclista"
                    leaderPoints = record["totalCarbonPoints"] as? Int ?? 0
                }
                
                // 🔥 RECRIANDO AS VARIÁVEIS DOS CONTADORES
                var cityCounts: [String: Int] = [:]
                var vehicleCounts: [String: Int] = [:]
                
                for match in feedMatches {
                    if case .success(let record) = match.1 {
                        // LÊ OS CAMPOS DIRETAMENTE DA NUVEM
                        if let city = record["cityName"] as? String {
                            cityCounts[city, default: 0] += 1
                        }
                        
                        if let vehicle = record["vehicleType"] as? String {
                            vehicleCounts[vehicle, default: 0] += 1
                        }
                    }
                }
                
                let topCity = cityCounts.max(by: { $0.value < $1.value })?.key ?? "Planeta Terra"
                let topVehicleType = vehicleCounts.max(by: { $0.value < $1.value })?.key ?? "Bicicleta"
                
                await MainActor.run {
                    self.globalTopUser = leaderName
                    self.globalTopPoints = leaderPoints
                    self.topActiveCity = topCity
                    self.topVehicle = topVehicleType
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isLoadingHighlights = false
                    }
                }
            } catch {
                print("⚠️ Erro ao buscar líder global.")
            }
        }
    }
