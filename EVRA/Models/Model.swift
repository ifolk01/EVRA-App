//
//  Model.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import Foundation
import SwiftData
import CoreLocation


struct Ride: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var distance: Double // km
    var duration: TimeInterval // segundos
    var co2Avoided: Double // gramas
    var earnedPoints: Int
    var date: Date
}

struct RouteCoordinate: Codable {
    var latitude: Double
    var longitude: Double
}

/// Modelo local para guardar viagens quando o telemóvel está offline.
@Model
class LocalRide {
    // 1. Removido o @Attribute(.unique) para cumprir as regras do CloudKit
    var id: UUID = UUID()
    
    var userAppleID: String = ""
    
    // 2. Todos os campos agora possuem valores padrão (obrigatório para CloudKit)
    var distance: Double = 0.0 // km
    var duration: TimeInterval = 0.0 // segundos
    var co2Avoided: Double = 0.0 // gramas
    var date: Date = Date()
    var route: [RouteCoordinate] = []
    
    // O grande segredo para o modo offline!
    var isSyncedToCloud: Bool = false
    
    init(id: UUID = UUID(), distance: Double, duration: TimeInterval, co2Avoided: Double, date: Date = Date(),route: [RouteCoordinate] = [], isSyncedToCloud: Bool = false,userAppleID: String) {
        self.id = id
        self.distance = distance
        self.duration = duration
        self.co2Avoided = co2Avoided
        self.date = date
        self.route = route
        self.isSyncedToCloud = isSyncedToCloud
        self.userAppleID = userAppleID
    }
}
