//
//  TrackingViewModel.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI
import Observation
import SwiftData
import ActivityKit
import CloudKit
import MapKit


// MARK: - ESTADOS DO RASTREAMENTO
enum TrackingState: Sendable, Equatable {
    case idle
    case tracking
    case paused
}



// MARK: - VIEW MODEL (O Cérebro da View)
@Observable
class TrackingViewModel {
    
  
    // Estados visíveis para a View
    var currentState: TrackingState = .idle
    var durationInSeconds: TimeInterval = 0
    
    // Serviço (Observável) - Não precisa de delegate!
    var trackingService = TrackingService()
    var stationaryTimeInSeconds: Int = 0
    private var timerTask: Task<Void, Never>?
    
    var rideStartTime: Date? = nil
    
    // Referência para a Live Activity ativa
    private var activity: Activity<TrackingAttributes>?
    
    var activeContext: ModelContext?
    var activeUser: User?
    var showNameRequiredAlert: Bool = false
    
    // Fatores de Emissão
    var emissionFactorReplaced: Double = 0.0
    let ebikeEmissionFactor: Double = 15.0 // Emissão base da E-bike
    
    @MainActor
        init() {
            // 🔥 REMOVIDO o bloco que matava as atividades acidentalmente ao carregar views
            
            // 1. LIGAÇÃO DO SERVIÇO DE TRACKING
            trackingService.onDistanceUpdate = { [weak self] newDistance in
                self?.updateRideProgress(newDistance: newDistance)
            }
            
            // 2. OUVINTES DE NOTIFICAÇÃO
            NotificationCenter.default.addObserver(
                forName: Notification.Name("ToggleRideStatus"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                switch self.currentState {
                case .tracking: self.pauseRide()
                case .paused:   self.resumeRide()
                case .idle:     break
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: Notification.Name("FinishRideSignal"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    await self?.finishRide(localContext: self?.activeContext, currentUser: self?.activeUser)
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { _ in
                print("🚨 App a ser encerrado! Abatendo Live Activity...")
                Task(priority: .high) { @MainActor in
                    for activity in Activity<TrackingAttributes>.activities {
                        let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
                        await activity.end(finalContent, dismissalPolicy: .immediate)
                    }
                }
                UserDefaults.standard.set(true, forKey: "has_interrupted_ride")
            }
        }
    
    
    // Propriedades Computadas (Reagem automaticamente quando o TrackingService muda)
    var distanceInKm: Double {
        return trackingService.currentDistance
    }
    
    var currentSpeedKmh: Double {
        return trackingService.currentSpeed
    }
    
    var co2AvoidedGrams: Double {
    
            if emissionFactorReplaced == 0.0 { return 0.0 }
            
            // O CO2 evitado é a emissão do veículo antigo MENOS a da e-bike.
            let factor = max(emissionFactorReplaced - ebikeEmissionFactor, 0.0)
            return distanceInKm * factor
        }
    var carbonPoints: Int {
            // 1 ponto por cada 100g de CO2 evitado
            return Int(co2AvoidedGrams / 100)
        }
    
    // MARK: - FORMATADORES
    
    var formattedDuration: String {
        let minutes = Int(durationInSeconds) / 60
        let seconds = Int(durationInSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedCO2: String {
        if co2AvoidedGrams > 1000 {
            return String(format: "%.1f kg", co2AvoidedGrams / 1000)
        }
        return String(format: "%.0f g", co2AvoidedGrams)
    }
    
    private func setupEmissionFactor() {
            guard let vehicle = activeUser?.substitutedVehicle else {
                emissionFactorReplaced = 0.0
                return
            }
            
            // Valores reais de mercado em gramas de CO2 por quilómetro
            switch vehicle {
            case .car:
                emissionFactorReplaced = 150.0 // Carro a combustão individual
            case .appRide:
                emissionFactorReplaced = 160.0 // Uber/99 (inclui os quilómetros rodados vazios para chegar ao cliente)
            case .motorcycle:
                emissionFactorReplaced = 90.0  // Mota padrão
            case .bus:
                emissionFactorReplaced = 70.0  // Autocarro (pegada dividida pelos passageiros)
            case .subway:
                emissionFactorReplaced = 30.0  // Metro (elétrico, mas com pegada da rede elétrica local)
            default:
                // A pé emite zero. Se o utilizador andava a pé e passou a andar de e-bike (15g),
                // ele tecnicamente polui mais. Mantemos em 0 para não gerar saldo negativo.
                emissionFactorReplaced = 0.0
            }
        }
    
    // MARK: - CONTROLOS DA VIAGEM
    
    func startRide() {
        
            let currentName = activeUser?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if currentName == "Ciclista" || currentName.isEmpty {
                showNameRequiredAlert = true // Dispara o gatilho do alerta na View
                return // Aborta o início da corrida imediatamente!
            }
        
            setupEmissionFactor()
            currentState = .tracking
            durationInSeconds = 0
            rideStartTime = Date()
            trackingService.startTracking()
            startLiveActivity()
            startTimer()
            self.updateLiveActivity()
        
        AnalyticsManager.shared.trackEvent("Ride_Started", properties: [
                "vehicle": activeUser?.substitutedVehicle?.rawValue ?? "Nenhum"
            ])
        }
    
    func pauseRide() {
        currentState = .paused
        trackingService.pauseTracking()
        self.updateLiveActivity()
        timerTask?.cancel()
        
        AnalyticsManager.shared.trackEvent("Ride_Paused", properties: [
                "distance": distanceInKm
            ])
    }
    
    func resumeRide() {
            currentState = .tracking
            // Ajusta a hora de início para compensar o tempo que ficou pausado
            rideStartTime = Date().addingTimeInterval(-durationInSeconds)
            trackingService.resumeTracking()
            self.updateLiveActivity()
            startTimer()
        }
    
    func finishRide(localContext: ModelContext?, currentUser: User?) async {
            // 1. PRIMEIRO: Salvamos o dado (A "fonte da verdade")
            if let context = localContext {
                let newRide = LocalRide(
                    distance: distanceInKm,
                    duration: durationInSeconds,
                    co2Avoided: co2AvoidedGrams,
                    userAppleID: currentUser?.appleUserIdentifier ?? "usuario_desconhecido"
                )
                context.insert(newRide)
                
                // 🔥 A MÁGICA DO ACUMULATIVO ACONTECE AQUI
                if let user = currentUser {
                    user.totalDistance += distanceInKm
                    user.totalCO2Avoided += co2AvoidedGrams // Em gramas, para precisão
                    user.totalCarbonPoints += self.carbonPoints
                    user.spendableCarbonPoints += self.carbonPoints
                }
                
                do {
                    try context.save() // Salva a corrida E atualiza o utilizador de uma vez!
                    print("Sucesso: Viagem guardada e totais atualizados.")
                    
                    syncWithPublicLeaderboard(distance: distanceInKm, co2: co2AvoidedGrams, points: self.carbonPoints)
                } catch {
                    print("Erro crítico ao guardar localmente: \(error)")
                    return
                }
            }
            
        
        AnalyticsManager.shared.trackEvent("Ride_Finished", properties: [
                "distance_km": distanceInKm,
                "co2_avoided_g": co2AvoidedGrams,
                "points_earned": carbonPoints,
                "duration_seconds": durationInSeconds
            ])
        
        Task { @MainActor in
                    for activity in Activity<TrackingAttributes>.activities {
                        // 🔥 Encerramento seguro sem aviso amarelo
                        let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
                        await activity.end(finalContent, dismissalPolicy: .immediate)
                    }
                }
                    
                // 3. Limpeza de memória
                self.activity = nil
                self.currentState = .idle
                trackingService.stopTracking()
                timerTask?.cancel()
                timerTask = nil
        }
    func updateRideProgress(newDistance: Double) {
        // 1. Atualiza o serviço
        self.trackingService.currentDistance = newDistance
        
        // 2. Persistência de segurança (Auto-save)
        UserDefaults.standard.set(newDistance, forKey: "last_saved_distance")
        UserDefaults.standard.set(durationInSeconds, forKey: "last_saved_duration")
        
        // 3. Opcional: Chama o update da Live Activity se necessário
        self.updateLiveActivity()
    }
    
    func startLiveActivity() {
            Task { @MainActor in
                // 1. Limpeza segura das antigas (Sem usar 'nil' para evitar bugs no iOS)
                for activity in Activity<TrackingAttributes>.activities {
                    let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
                    await activity.end(finalContent, dismissalPolicy: .immediate)
                }
                
                // 2. Verifica se pode criar
                guard self.activity == nil else { return }
                
                let attributes = TrackingAttributes(startTime: Date())
                let initialContentState = TrackingAttributes.ContentState(
                    currentDistance: 0.0, currentDuration: 0.0,
                    co2Avoided: 0.0, isPaused: false, isFinishing: false
                )
                let initialContent = ActivityContent(state: initialContentState, staleDate: nil)
                
                do {
                    self.activity = try Activity.request(attributes: attributes, content: initialContent)
                    print("DEBUG: 🚀 Live Activity iniciada com sucesso: \(self.activity?.id ?? "")")
                } catch {
                    print("DEBUG: ❌ Erro crítico ao iniciar: \(error.localizedDescription)")
                }
            }
        }
       
    private func updateLiveActivity() {
        Task {
            // Garanta que os valores não são nulos. Use nil-coalescing (?? 0.0)
            let updatedContentState = TrackingAttributes.ContentState(
                currentDistance: distanceInKm,
                currentDuration: durationInSeconds,
                co2Avoided: co2AvoidedGrams,
                isPaused: currentState == .paused, isFinishing: false
            )
            let content = ActivityContent(state: updatedContentState, staleDate: nil)
            await activity?.update(content)
        }
    }
    private func startTimer() {
            timerTask?.cancel()
            
            timerTask = Task { @MainActor [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    
                    guard let self = self, self.currentState == .tracking, let startTime = self.rideStartTime else { break }
        
                    self.durationInSeconds = Date().timeIntervalSince(startTime)
                    
                    self.updateRideProgress(newDistance: self.trackingService.currentDistance)
                    // 2. Atualiza o Widget/Ilha Dinâmica a cada 1 minuto (poupa bateria)
                    if Int(self.durationInSeconds) % 60 == 0 {
                        self.updateLiveActivity()
                    }
                    
                    // 3. LÓGICA INTELIGENTE DE PARAGEM (10 MINUTOS)
                    if self.trackingService.detectedActivity == "Parado no Sinal" {
                        // O ciclista está parado. Começamos a contar o tempo de inatividade.
                        self.stationaryTimeInSeconds += 1
                        
                        // 600 segundos = 10 minutos
                        if self.stationaryTimeInSeconds >= 600 {
                            print("10 minutos de inatividade detetados. A pausar o trajeto automaticamente.")
                            self.pauseRide() // Ou self.finishRide() se preferir encerrar de vez
                            self.stationaryTimeInSeconds = 0 // Reseta o contador
                        }
                    } else {
                        // O ciclista voltou a pedalar!
                        // Zeramos o cronómetro de inatividade silenciosamente.
                        self.stationaryTimeInSeconds = 0
                    }
                }
            }
        }
    deinit {
            let service = self.trackingService
            Task { @MainActor in
                service.stopTracking()
            }
        }
    
 
    // MARK: - CLOUDKIT PUBLIC SYNC (Leaderboard & Feed Separados)
        private func syncWithPublicLeaderboard(distance: Double, co2: Double, points: Int) {
            Task {
                let publicDB = CKContainer.default().publicCloudDatabase
                
                // 1. Obter a cidade
                var city = "Local Desconhecido"
                if let location = trackingService.lastLocation {
                    do {
                        if let request = MKReverseGeocodingRequest(location: location) {
                            let mapItems: [MKMapItem] = try await withCheckedThrowingContinuation { continuation in
                                request.getMapItems { items, error in
                                    if let error = error {
                                        continuation.resume(throwing: error)
                                    } else {
                                        continuation.resume(returning: items ?? [])
                                    }
                                }
                            }
                            if let item = mapItems.first, let addressRep = item.addressRepresentations {
                                city = addressRep.cityWithContext(.full) ?? "Local Desconhecido"
                            }
                        }
                    } catch {
                        print("MapKit falhou ao buscar cidade. Usando fallback.")
                    }
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-yyyy"
                let currentMonthYear = dateFormatter.string(from: Date())
                
                
                // Puxa o veículo real do utilizador. Se por acaso falhar, assume "Carro" como padrão oficial.
                let userVehicle = activeUser?.substitutedVehicle?.rawValue ?? SubstitutedVehicle.car.rawValue
                let groupName = "\(userVehicle) - \(city) - \(currentMonthYear)"
                let userName = activeUser?.name ?? "Ciclista Desconhecido"
                let userAppleID = activeUser?.appleUserIdentifier ?? "usuario_anonimo"
                
                // ==========================================
                // PARTE A: ATUALIZAR O RANKING (1 Registo por User)
                // ==========================================
                let predicate = NSPredicate(format: "userAppleID == %@ AND groupName == %@", userAppleID, groupName)
                let query = CKQuery(recordType: "PublicLeaderboard", predicate: predicate)
                
                do {
                    let (matchResults, _) = try await publicDB.records(matching: query)
                    
                    if let firstMatch = matchResults.first, case .success(let existingRecord) = firstMatch.1 {
                        let currentDistance = existingRecord["totalDistance"] as? Double ?? 0.0
                        let currentCO2 = existingRecord["totalCO2"] as? Double ?? 0.0
                        let currentPoints = existingRecord["totalCarbonPoints"] as? Int ?? 0
                        
                        existingRecord["totalDistance"] = currentDistance + distance
                        existingRecord["totalCO2"] = currentCO2 + co2
                        existingRecord["totalCarbonPoints"] = currentPoints + points
                        existingRecord["userName"] = userName
                        
                        try await publicDB.save(existingRecord)
                        print("☁️ 🏆 CloudKit: Ranking acumulado atualizado com sucesso!")
                    } else {
                        let newRecord = CKRecord(recordType: "PublicLeaderboard")
                        newRecord["userAppleID"] = userAppleID
                        newRecord["userName"] = userName
                        newRecord["groupName"] = groupName
                        newRecord["totalDistance"] = distance
                        newRecord["totalCO2"] = co2
                        newRecord["totalCarbonPoints"] = points
                        
                        try await publicDB.save(newRecord)
                        print("☁️ 🏆 CloudKit: Novo perfil criado no Ranking!")
                    }
                } catch {
                    print("☁️ Criando tabela PublicLeaderboard pela primeira vez...")
                    let newRecord = CKRecord(recordType: "PublicLeaderboard")
                    newRecord["userAppleID"] = userAppleID
                    newRecord["userName"] = userName
                    newRecord["groupName"] = groupName
                    newRecord["totalDistance"] = distance
                    newRecord["totalCO2"] = co2
                    newRecord["totalCarbonPoints"] = points
                    try? await publicDB.save(newRecord)
                }
                
                // ==========================================
                // PARTE B: ADICIONAR AO FEED AO VIVO (Histórico de Atividades)
                // ==========================================
                let feedRecord = CKRecord(recordType: "PublicFeedActivity")
                feedRecord["userAppleID"] = userAppleID
                feedRecord["userName"] = userName
                feedRecord["groupName"] = groupName
                feedRecord["distance"] = distance
                feedRecord["co2Avoided"] = co2
                feedRecord["date"] = Date()
                
                do {
                    try await publicDB.save(feedRecord)
                    print("☁️ 📰 CloudKit: Nova atividade adicionada ao Feed ao Vivo!")
                } catch {
                    print("☁️ ❌ Erro ao salvar atividade no feed: \(error.localizedDescription)")
                }
            }
        }
}
