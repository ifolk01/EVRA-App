//
//  CoreServices.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import Foundation
import CloudKit
import CoreLocation
import CoreMotion
import Observation



// MARK: - CloudKit Service

enum CloudKitError: Error, LocalizedError {
    case accountNotAvailable
    case recordNotFound
    case failedToSave
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable: return "Conta do iCloud não encontrada ou restrita."
        case .recordNotFound: return "fetch encontrado no banco de dados."
        case .failedToSave: return "Falha ao salvar os dados na nuvem."
        case .unknown(let error): return error.localizedDescription
        }
    }
}

/// Serviço responsável pela comunicação exclusiva com o Apple CloudKit.
/// Esta classe é injetada nas ViewModels, blindando a View do banco de dados.
class CloudKitService {
    
    // Container principal configurado no Signing & Capabilities
    private let container = CKContainer.default()
    
    // Banco Privado: Somente o usuário acessa (Corridas, Perfil, Nº de Série)
    private let privateDB = CKContainer.default().privateCloudDatabase
    
    // Banco Público: Todos acessam (Ranking de Grupos, Benefícios)
    private let publicDB = CKContainer.default().publicCloudDatabase
    
    // Verifica se o usuário tem uma conta do iCloud logada e ativa
    func checkAccountStatus() async throws -> CKAccountStatus {
        return try await container.accountStatus()
    }
    
    
    // MARK: - Operações de Usuário (Private DB)
    
    /// Salva ou atualiza um usuário no banco de dados privado
    func saveUser(_ user: User) async throws {
        let recordID = CKRecord.ID(recordName: user.id.uuidString)
        let record = CKRecord(recordType: "LevUser", recordID: recordID)
        
        record["appleUserIdentifier"] = user.appleUserIdentifier as CKRecordValue
        record["name"] = user.name as CKRecordValue
        record["email"] = user.email as CKRecordValue
        record["bikeSerialNumber"] = user.bikeSerialNumber as CKRecordValue?
        record["substitutedVehicle"] = user.substitutedVehicle?.rawValue as CKRecordValue?
        record["totalCarbonPoints"] = user.totalCarbonPoints as CKRecordValue
        record["totalCO2Avoided"] = user.totalCO2Avoided as CKRecordValue
        record["totalDistance"] = user.totalDistance as CKRecordValue
        record["createdAt"] = user.createdAt as CKRecordValue
        record["spendableCarbonPoints"] = user.spendableCarbonPoints as CKRecordValue
        
        do {
            _ = try await privateDB.save(record)
        } catch {
            throw CloudKitError.failedToSave
        }
    }
    func deleteUser(userId: UUID) async throws {
            let recordID = CKRecord.ID(recordName: userId.uuidString)
            do {
                try await privateDB.deleteRecord(withID: recordID)
                print("☁️ Utilizador apagado do CloudKit com sucesso.")
            } catch {
                throw CloudKitError.failedToSave
            }
        }
    
    // MARK: - Operações de Corridas (Private DB)
    
    /// Salva uma corrida finalizada no banco de dados do usuário
    func saveRide(_ ride: Ride) async throws {
        let recordID = CKRecord.ID(recordName: ride.id.uuidString)
        let record = CKRecord(recordType: "Ride", recordID: recordID)
        
        // Relacionamento (Reference) com o usuário criador
        let userRecordID = CKRecord.ID(recordName: ride.userId.uuidString)
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .deleteSelf)
        
        record["user"] = userReference
        record["distance"] = ride.distance as CKRecordValue
        record["duration"] = ride.duration as CKRecordValue
        record["co2Avoided"] = ride.co2Avoided as CKRecordValue
        record["earnedPoints"] = ride.earnedPoints as CKRecordValue
        record["date"] = ride.date as CKRecordValue
        
        do {
            _ = try await privateDB.save(record)
        } catch {
            throw CloudKitError.failedToSave
        }
    }
}


// MARK: - Tracking Service

/// Serviço de Rastreamento responsável por gerenciar a lógica de Background, GPS e Acelerômetro.
/// Utilizamos @Observable (iOS 17+) para que a UI reaja a mudanças de velocidade e distância facilmente.
@MainActor
class TrackingService: NSObject, CLLocationManagerDelegate {
    
    // Managers nativos
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionActivityManager()
   
    var routeCoordinates: [RouteCoordinate] = []
    
    // Estados reativos (Lidos pelas ViewModels/Live Activities)
    var isTrackingActive: Bool = false
    var currentSpeed: Double = 0.0
    var currentDistance: Double = 0.0
    var detectedActivity: String = "Parado"
    var isAutomotiveDetected: Bool = false
    var onDistanceUpdate: ((Double) -> Void)?
    var lastLocation: CLLocation?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.distanceFilter = 5.0
            locationManager.showsBackgroundLocationIndicator = true
            
            // 🔥 AVISO AO iOS: Otimiza a recolha de satélite para ciclismo/corrida (poupa muita bateria)
            locationManager.activityType = .fitness
        }
    
    func requestPermissions() {
        // Solicita autorização de localização em Always (necessário para tracking em background robusto)
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Controle de Rastreamento
    
    func startTracking() {
        guard !isTrackingActive else { return }
        
        currentDistance = 0.0
        isTrackingActive = true
        locationManager.startUpdatingLocation()
        routeCoordinates.removeAll()
        
        // Inicia a captura do coprocessador de movimento (Acelerômetro)
        if CMMotionActivityManager.isActivityAvailable() {
            motionManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let self = self, let activity = activity else { return }
                self.handleMotionActivity(activity)
            }
        }
    }
    
    func stopTracking() {
        isTrackingActive = false
        locationManager.stopUpdatingLocation()
        motionManager.stopActivityUpdates()
    }
    func pauseTracking() {
           locationManager.stopUpdatingLocation()
       }
   
       func resumeTracking() {
           locationManager.startUpdatingLocation()
       }
    
    // MARK: - Lógica de Máquina de Estados (CoreMotion)
    
    private func handleMotionActivity(_ activity: CMMotionActivity) {
        // Aqui está o "Cérebro" para evitar falsos positivos
        // Analisamos o nível de confiança (confidence) do sensor
        guard activity.confidence == .high || activity.confidence == .medium else { return }
        
        if activity.cycling {
                    self.detectedActivity = "Pedalando"
                    self.isAutomotiveDetected = false // Libertado para somar
                } else if activity.automotive {
                    self.detectedActivity = "Em um Veículo"
                    self.isAutomotiveDetected = true  // 🔥 TRAVÃO ACIONADO: Detetou vibração de carro/autocarro
                } else if activity.walking || activity.running {
                    self.detectedActivity = "Caminhando/Correndo"
                    self.isAutomotiveDetected = false
                } else if activity.stationary {
                    self.detectedActivity = "Parado no Sinal"
                    self.isAutomotiveDetected = false
                }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last, isTrackingActive else { return }
            
            // 🔥 AJUSTE 1: Relaxamos a precisão para 50 metros para abraçar a realidade urbana
            guard location.horizontalAccuracy > 0 && location.horizontalAccuracy <= 35 else {
                print("Trajeto ignorado: GPS com baixa precisão (\(location.horizontalAccuracy) metros).")
                return
            }
            
            // --- Cálculo de Velocidade ---
            let speedMetersPerSecond = location.speed
            self.currentSpeed = max(speedMetersPerSecond * 3.6, 0.0)
            
            // 🔥 AJUSTE 2: Removemos a barreira do "Automotive" porque as E-bikes enganam o sensor do iPhone.
            // Confiamos APENAS no limite de 44 km/h. Se passar disso, é mota ou carro em via rápida.
            guard self.currentSpeed <= 44.0 else {
                print("Trajeto ignorado: Velocidade de \(self.currentSpeed) km/h excede o limite físico de uma E-bike.")
                return
            }
            
            // --- Cálculo de Distância Seguro ---
            if let last = lastLocation {
                let distanceInMeters = location.distance(from: last)
                self.currentDistance += (distanceInMeters / 1000.0)
                
                // Só guarda e atualiza se passar na velocidade máxima
                onDistanceUpdate?(self.currentDistance)
            }
        for location in locations {
                    let newPoint = RouteCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    routeCoordinates.append(newPoint)
                }
        
            lastLocation = location
        }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erro de Localização: \(error.localizedDescription)")
    }
}

extension CloudKitService {
    
   
    /// Busca o usuário logado usando o ID único do Sign in with Apple
        func fetchUser(appleUserIdentifier: String) async throws -> User {
            let predicate = NSPredicate(format: "appleUserIdentifier == %@", appleUserIdentifier)
            let query = CKQuery(recordType: "LevUser", predicate: predicate)
            
            let (matchResults, _) = try await privateDB.records(matching: query)
            
            guard let match = matchResults.first,
                  let record = try? match.1.get() else {
                // Se realmente não existir nenhum registo com este ID
                throw CloudKitError.recordNotFound
            }
            
            let idString = record.recordID.recordName
            guard let id = UUID(uuidString: idString) else {
                throw CloudKitError.recordNotFound
            }
            
            // EXTRAÇÃO SEGURA: Se o campo falhar ou for nulo na nuvem, usamos um valor padrão seguro
            let name = record["name"] as? String ?? "Ciclista"
            let email = record["email"] as? String ?? ""
            
            // Lidar com conversão de números do CloudKit (que às vezes usa Int64)
            let totalCarbonPoints = record["totalCarbonPoints"] as? Int ?? 0
            let totalCO2Avoided = record["totalCO2Avoided"] as? Double ?? 0.0
            let totalDistance = record["totalDistance"] as? Double ?? 0.0
            let createdAt = record["createdAt"] as? Date ?? Date()
            let spendableCarbonPoints = record["spendableCarbonPoints"] as? Int ?? totalCarbonPoints
            
            let bikeSerialNumber = record["bikeSerialNumber"] as? String
            var subVehicle: SubstitutedVehicle? = nil
            if let vehicleString = record["substitutedVehicle"] as? String {
                subVehicle = SubstitutedVehicle(rawValue: vehicleString)
            }
            
            return User(
                id: id,
                appleUserIdentifier: appleUserIdentifier,
                name: name,
                email: email,
                bikeSerialNumber: bikeSerialNumber,
                substitutedVehicle: subVehicle,
                totalCarbonPoints: totalCarbonPoints,
                totalCO2Avoided: totalCO2Avoided,
                totalDistance: totalDistance,
                createdAt: createdAt,
                spendableCarbonPoints: spendableCarbonPoints
            )
        }
    
    /// Busca as viagens salvas de um usuário específico, ordenadas da mais recente para a mais antiga
    func fetchRecentRides(for userId: UUID) async throws -> [Ride] {
        // Cria a referência ao usuário para buscar apenas as viagens dele
        let userRecordID = CKRecord.ID(recordName: userId.uuidString)
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)
        let predicate = NSPredicate(format: "user == %@", userReference)
        
        let query = CKQuery(recordType: "Ride", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)] // Mais recentes primeiro
        
        let (matchResults, _) = try await privateDB.records(matching: query)
        
        var rides: [Ride] = []
        
        for match in matchResults {
            if let record = try? match.1.get(),
               let id = UUID(uuidString: record.recordID.recordName),
               let distance = record["distance"] as? Double,
               let duration = record["duration"] as? TimeInterval,
               let co2Avoided = record["co2Avoided"] as? Double,
               let earnedPoints = record["earnedPoints"] as? Int,
               let date = record["date"] as? Date {
                
                let ride = Ride(id: id, userId: userId, distance: distance, duration: duration, co2Avoided: co2Avoided, earnedPoints: earnedPoints, date: date)
                rides.append(ride)
            }
        }
        
        return rides
    }
}
