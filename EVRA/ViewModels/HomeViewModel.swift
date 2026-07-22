//
//  HomeViewModel.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI
import Observation
import CloudKit


@Observable
class HomeViewModel {
    // Injeção de dependência dos serviços
    private let cloudKitService: CloudKitService
    
    // Estados visíveis para a View
    var currentUser: User?
    
    var recentRides: [Ride] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    // Inicializador
    init(cloudKitService: CloudKitService = CloudKitService()) {
        self.cloudKitService = cloudKitService
    }
    
    
    // Funções chamadas pela View
    func fetchDashboardData(appleUserId: String) async {
            isLoading = true
            errorMessage = nil
            
            do {
                // 1. Busca o usuário com o try await. Isso valida o catch lá embaixo!
                currentUser = try await cloudKitService.fetchUser(appleUserIdentifier: appleUserId)
                
                // 2. Se encontrou o usuário, busca as corridas dele
                if let user = currentUser {
                    recentRides = try await cloudKitService.fetchRecentRides(for: user.id)
                }
                
            } catch {
                errorMessage = "Erro ao carregar dados: \(error.localizedDescription)"
                print(errorMessage ?? "")
            }
            
            isLoading = false
        }
    
    func setUser(_ user: User) {
            self.currentUser = user
        }
    
    
    // Lógica de formatação (A View não deve fazer cálculos)
    var formattedCO2: String {
        guard let co2 = currentUser?.totalCO2Avoided else { return "0 kg" }
        return String(format: "%.1f kg", co2 / 1000)
    }
}
