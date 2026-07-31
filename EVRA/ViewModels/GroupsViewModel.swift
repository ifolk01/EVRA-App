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
class GroupsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var groupName: String = "A localizar..."
    @Published var memberCount: Int = 0
    
    
    @Published var isLoadingHighlights: Bool = true
    @Published var globalTopUser: String = "Ciclista Campeão"
    @Published var globalTopPoints: Int = 15000
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
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - 1. REVERSE GEOCODING (Onde estou?)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation()
        
        Task {
            do {
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    throw NSError(domain: "MapKit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Falha ao criar o request"])
                }
                
                let mapItems: [MKMapItem] = try await withCheckedThrowingContinuation { continuation in
                    request.getMapItems { items, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: items ?? [])
                        }
                    }
                }
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-yyyy"
                let currentMonthYear = dateFormatter.string(from: Date())
                
                var city = "Local Desconhecido"
                if let item = mapItems.first, let addressRep = item.addressRepresentations {
                    city = addressRep.cityWithContext(.full) ?? "Local Desconhecido"
                }
                
                let userVehicle = UserDefaults.standard.string(forKey: "user_substituted_vehicle") ?? SubstitutedVehicle.car.rawValue
                
                // 🔥 NOME VISUAL PARA O CABEÇALHO (Sem a data)
                self.groupName = "\(userVehicle) - \(city)"
                
                // 🔥 NOME EXATO PARA PESQUISA NA NUVEM (Com a data)
                self.searchGroupName = "\(userVehicle) - \(city) - \(currentMonthYear)"
                
                await self.fetchGroupData(for: self.searchGroupName)
                await self.fetchGlobalHighlights()
            } catch {
                print("Erro ao localizar a cidade via MapKit: \(error.localizedDescription)")
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-yyyy"
                let currentMonthYear = dateFormatter.string(from: Date())
                
                let userVehicle = UserDefaults.standard.string(forKey: "user_substituted_vehicle") ?? SubstitutedVehicle.car.rawValue
                self.groupName = "\(userVehicle) - Local Desconhecido"
                
                // 🔥 NOME EXATO DE FALLBACK
                self.searchGroupName = "\(userVehicle) - Local Desconhecido - \(currentMonthYear)"
                
                await self.fetchGroupData(for: self.searchGroupName)
                await self.fetchGlobalHighlights()
            }
        }
    }
    
    // MARK: - 2. BUSCAR DADOS REAIS DO CLOUDKIT
    
    // 🔥 CORREÇÃO: O pull-to-refresh agora pesquisa a string exata (com a data)
    func refreshData() async {
        guard !self.searchGroupName.isEmpty else { return }
        await fetchGroupData(for: self.searchGroupName)
        await fetchGlobalHighlights()
    }
    
    
    func checkVehiclePreference() {
            // 1. Lê o que está salvo no momento (Se não achar, assume Carro)
            let savedVehicle = UserDefaults.standard.string(forKey: "user_substituted_vehicle") ?? "Carro"
            
            // 2. Se ainda estiver a buscar o GPS na primeira abertura, ignoramos
            guard !self.groupName.contains("A localizar") else { return }
            
            // 3. Extrai a cidade do nome atual (ex: separa "Carro - Rio de Janeiro" para pegar só o Rio)
            let parts = self.groupName.components(separatedBy: " - ")
            let city = parts.count > 1 ? parts[1] : "Local Desconhecido"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-yyyy"
            let currentMonthYear = dateFormatter.string(from: Date())
            
            let expectedSearchName = "\(savedVehicle) - \(city) - \(currentMonthYear)"
            
            // 4. Se o utilizador trocou de veículo, os nomes não vão bater!
            if self.searchGroupName != expectedSearchName && !self.searchGroupName.isEmpty {
                
                // Atualiza os nomes para a nova sala
                self.groupName = "\(savedVehicle) - \(city)"
                self.searchGroupName = expectedSearchName
                
                // Liga as barras cinzentas de carregamento novamente
                self.isLoadingHighlights = true
                
                // Dispara a busca na nova sala do CloudKit
                Task {
                    await fetchGroupData(for: self.searchGroupName)
                }
            }
        }
    
    private func fetchGroupData(for group: String) async {
        let publicDB = CKContainer.default().publicCloudDatabase
        
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
                    let name = record["userName"] as? String ?? "Ciclista Desconhecido"
                    let distance = record["totalDistance"] as? Double ?? 0.0
                    let co2 = record["totalCO2"] as? Double ?? 0.0
                    let points = record["totalCarbonPoints"] as? Int ?? 0
                    
                    fetchedRankings.append(RankingUser(name: name, points: points, co2: co2))
                }
            }
            
            for match in feedMatches {
                if case .success(let record) = match.1 {
                    let name = record["userName"] as? String ?? "Ciclista"
                    let distance = record["distance"] as? Double ?? 0.0
                    let co2 = record["co2Avoided"] as? Double ?? 0.0
                    let date = record["date"] as? Date ?? Date()
                    
                    let co2Formatted = co2 > 1000 ? String(format: "%.1f kg", co2 / 1000.0) : String(format: "%.0f g", co2)
                    
                    fetchedFeed.append(FeedActivity(
                        name: name,
                        action: " - evitou \(co2Formatted)",
                        distance: distance,
                        timestamp: date
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
    
    // MARK: - 3. BUSCAR DESTAQUES GLOBAIS
    func fetchGlobalHighlights() async {
        let publicDB = CKContainer.default().publicCloudDatabase
        
        // 1. Query do Líder Global (Pesquisa em TUDO: value: true)
        let leaderQuery = CKQuery(recordType: "PublicLeaderboard", predicate: NSPredicate(value: true))
        leaderQuery.sortDescriptors = [NSSortDescriptor(key: "totalCarbonPoints", ascending: false)]
        
        // 2. Query de Atividade Global (Para descobrir a cidade e modal em alta)
        let globalFeedQuery = CKQuery(recordType: "PublicFeedActivity", predicate: NSPredicate(value: true))
        globalFeedQuery.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
                    let (leaderMatches, _) = try await publicDB.records(matching: leaderQuery)
                    
                    var leaderName = ""
                    var leaderPoints = 0
                    
                    if let firstMatch = leaderMatches.first, case .success(let record) = firstMatch.1 {
                        leaderName = record["userName"] as? String ?? "Ciclista"
                        leaderPoints = record["totalCarbonPoints"] as? Int ?? 0
                    }
                    
                    let (feedMatches, _) = try await publicDB.records(matching: globalFeedQuery)
                    
                    var cityCounts: [String: Int] = [:]
                    var vehicleCounts: [String: Int] = [:]
                    
                    for match in feedMatches {
                        if case .success(let record) = match.1 {
                            if let groupName = record["groupName"] as? String {
                                let parts = groupName.components(separatedBy: " - ")
                                if parts.count >= 2 {
                                    let vehicle = parts[0]
                                    let city = parts[1]
                                    vehicleCounts[vehicle, default: 0] += 1
                                    cityCounts[city, default: 0] += 1
                                }
                            }
                        }
                    }
                    
                    // 🔥 A MÁGICA: Só revela os cartões se houver pelo menos 1 pedalada registada globalmente!
                    let hasGlobalData = !cityCounts.isEmpty && leaderPoints > 0
                    
                    await MainActor.run {
                        if hasGlobalData {
                            self.globalTopUser = leaderName
                            self.globalTopPoints = leaderPoints
                            self.topActiveCity = cityCounts.max(by: { $0.value < $1.value })?.key ?? ""
                            self.topVehicle = vehicleCounts.max(by: { $0.value < $1.value })?.key ?? ""
                            
                            withAnimation(.easeOut(duration: 0.3)) {
                                self.isLoadingHighlights = false // Desliga o esqueleto
                            }
                        }
                        // Se hasGlobalData for falso, o 'isLoadingHighlights' continua 'true'.
                        // Os cartões continuam com o efeito cinzento interativo infinitamente.
                    }
                    
                } catch {
                    print("⚠️ Erro ao buscar destaques globais: \(error.localizedDescription)")
                    // Mantemos em loading se houver erro de conexão
                }
    }
}
