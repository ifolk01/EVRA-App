//
// User.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 08/07/26.
//
import SwiftUI
import Foundation
import SwiftData

// Enum para o Veículo Substituído
enum SubstitutedVehicle: String, Codable, CaseIterable {
    case car = "Carro"
    case motorcycle = "Moto"
    case bus = "Ônibus"
    case subway = "Metrô"
    case walking = "Caminhada"
    case appRide = "Uber / Apps"
    
    // Fator de emissão de CO2 (g/km) para o cálculo
    var emissionFactor: Double {
        switch self {
        case .car, .appRide: return 150.0
        case .motorcycle: return 100.0
        case .bus: return 80.0
        case .subway: return 40.0
        case .walking: return 0.0
        }
    }
}

// O NOSSO NOVO SUPER USER (SwiftData + CloudKit Automático)
@Model
final class User {
    var id: UUID = UUID()
    // 2. Valores padrão em todas as variáveis não-opcionais
        var appleUserIdentifier: String = ""
        var name: String = ""
        var email: String = ""
        
        // Dados recolhidos no Onboarding
        var bikeSerialNumber: String? = nil
        var substitutedVehicleRawValue: String = ""
        var frequency: String = ""
        var routes: [String] = []
       
        
        // Métricas de Gamificação
        var totalCarbonPoints: Int = 0
        var totalCO2Avoided: Double = 0.0
        var totalDistance: Double = 0.0
        var createdAt: Date = Date()
    
    init(appleUserIdentifier: String, name: String, email: String, bikeSerialNumber: String?, substitutedVehicleRawValue: String, frequency: String, routes: [String]) {
        self.id = UUID()
        self.appleUserIdentifier = appleUserIdentifier
        self.name = name
        self.email = email
        self.bikeSerialNumber = bikeSerialNumber
        self.substitutedVehicleRawValue = substitutedVehicleRawValue
        self.frequency = frequency
        self.routes = routes
        
        self.totalCarbonPoints = 0
        self.totalCO2Avoided = 0.0
        self.totalDistance = 0.0
        self.createdAt = Date()
    }
    init(id: UUID, appleUserIdentifier: String, name: String, email: String, bikeSerialNumber: String?, substitutedVehicle: SubstitutedVehicle?, totalCarbonPoints: Int, totalCO2Avoided: Double, totalDistance: Double, createdAt: Date, frequency: String = "", routes: [String] = []) {
            self.id = id
            self.appleUserIdentifier = appleUserIdentifier
            self.name = name
            self.email = email
            self.bikeSerialNumber = bikeSerialNumber
            self.substitutedVehicleRawValue = substitutedVehicle?.rawValue ?? ""
            self.totalCarbonPoints = totalCarbonPoints
            self.totalCO2Avoided = totalCO2Avoided
            self.totalDistance = totalDistance
            self.createdAt = createdAt
            
            // Novos campos (Se o CloudKit ainda não os tiver, ficam vazios por padrão)
            self.frequency = frequency
            self.routes = routes
        }
    
    // Propriedade auxiliar para nos dar o Enum correto no resto da app
    var substitutedVehicle: SubstitutedVehicle? {
        get { SubstitutedVehicle(rawValue: substitutedVehicleRawValue) }
        set { substitutedVehicleRawValue = newValue?.rawValue ?? "" }
    }
}
