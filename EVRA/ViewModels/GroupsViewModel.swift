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
    
    // Arrays que vão guardar os dados REAIS vindos da nuvem
    @Published var rankings: [RankingUser] = []
    @Published var liveFeed: [FeedActivity] = []
    
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
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Não precisamos de precisão extrema para saber o bairro
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
                    
                    var city = "Local Desconhecido"
                    if let item = mapItems.first, let addressRep = item.addressRepresentations {
                        city = addressRep.cityWithContext(.full) ?? "Local Desconhecido"
                    }
                    
                    let userVehicle = UserDefaults.standard.string(forKey: "user_substituted_vehicle") ?? "Ciclista"
                    self.groupName = "\(userVehicle) - \(city)"
                    
                    // 🔥 O chamamento agora usa 'await'
                    await self.fetchGroupData(for: self.groupName)
                    
                } catch {
                    print("Erro ao localizar a cidade via MapKit: \(error.localizedDescription)")
                    let userVehicle = UserDefaults.standard.string(forKey: "user_substituted_vehicle") ?? "Ciclista"
                    self.groupName = "\(userVehicle) - Local Desconhecido"
                    
                    // 🔥 O chamamento agora usa 'await'
                    await self.fetchGroupData(for: self.groupName)
                }
            }
        }
        
        // MARK: - 2. BUSCAR DADOS REAIS DO CLOUDKIT
        
        // 🔥 Função pública para o pull-to-refresh chamar
        func refreshData() async {
            await fetchGroupData(for: self.groupName)
        }
        
        // 🔥 Função transformada em 'async' sem o 'Task' dentro, para o UI saber quando acaba
    private func fetchGroupData(for group: String) async {
            let publicDB = CKContainer.default().publicCloudDatabase
            
            // 1. QUERY PARA O RANKING (Tabela PublicLeaderboard)
            let rankPredicate = NSPredicate(format: "groupName == %@", group)
            let rankQuery = CKQuery(recordType: "PublicLeaderboard", predicate: rankPredicate)
            rankQuery.sortDescriptors = [NSSortDescriptor(key: "totalDistance", ascending: false)]
            
            // 2. QUERY PARA O FEED AO VIVO (Tabela PublicFeedActivity - últimas 20 pedaladas)
            let feedPredicate = NSPredicate(format: "groupName == %@", group)
            let feedQuery = CKQuery(recordType: "PublicFeedActivity", predicate: feedPredicate)
            feedQuery.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                // Executa as duas buscas em paralelo na nuvem
                async let rankResult = publicDB.records(matching: rankQuery)
                async let feedResult = publicDB.records(matching: feedQuery)
                
                let (rankMatches, _) = try await rankResult
                let (feedMatches, _) = try await feedResult
                
                var fetchedRankings: [RankingUser] = []
                var fetchedFeed: [FeedActivity] = []
                
                // Processa o Ranking (Sem duplicados, 1 por utilizador)
                for match in rankMatches {
                    if case .success(let record) = match.1 {
                        let name = record["userName"] as? String ?? "Ciclista LEV"
                        let distance = record["totalDistance"] as? Double ?? 0.0
                        let co2 = record["totalCO2"] as? Double ?? 0.0
                        let points = Int(distance * 10)
                        
                        fetchedRankings.append(RankingUser(name: name, points: points, co2: co2))
                    }
                }
                
                // Processa o Feed ao Vivo (Histórico cronológico real de pedaladas)
                for match in feedMatches {
                    if case .success(let record) = match.1 {
                        let name = record["userName"] as? String ?? "Ciclista LEV"
                        let distance = record["distance"] as? Double ?? 0.0
                        let co2 = record["co2Avoided"] as? Double ?? 0.0
                        let date = record["date"] as? Date ?? Date()
                        
                        let co2Formatted = co2 > 1000 ? String(format: "%.1f kg", co2 / 1000.0) : "\(Int(co2)) g"
                        
                        fetchedFeed.append(FeedActivity(
                            name: name,
                            action: " - evitou \(co2Formatted) de CO2!",
                            distance: distance,
                            timestamp: date
                        ))
                    }
                }
                
                await MainActor.run {
                    self.rankings = fetchedRankings
                    self.memberCount = fetchedRankings.count
                    self.liveFeed = fetchedFeed // Já ordenado pela query do CloudKit
                }
                
            } catch {
                print("❌ Erro ao buscar dados do CloudKit: \(error.localizedDescription)")
            }
        }
}
