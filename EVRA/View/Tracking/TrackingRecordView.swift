//
//  TrackingRecordView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 08/07/26.
//


import SwiftUI
import SwiftData
import CoreLocation
import CoreMotion
import MapKit // 🔥 Adicionado para o fundo imersivo

struct TrackingRecordView: View {
    // Recebe as ViewModels injetadas
    var trackingVM: TrackingViewModel
    var homeVM: HomeViewModel
    @Environment(\.modelContext) private var modelContext
    
    // Estados para controlar o Alerta de Bloqueio
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    
    // Controlo da câmara do mapa
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // MARK: - 1. O Mapa em Background
            Map(position: $cameraPosition) {
                UserAnnotation() // Mostra a bolinha azul nativa com a direção do utilizador
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
            }
            .ignoresSafeArea()
            
            // MARK: - 2. Painel Flutuante de Telemetria
            VStack(spacing: 24) {
                
                // Cabeçalho: Veículo Substituído
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Substituindo")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 8) {
                            let vehicleIcon = getVehicleIcon(for: homeVM.currentUser?.substitutedVehicle)
                            Image(systemName: vehicleIcon)
                                .foregroundColor(AppColors.levBlue)
                            
                            Text(homeVM.currentUser?.substitutedVehicle?.rawValue ?? "Veículo")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }
                    }
                    Spacer()
                    
                    // Indicador de Estado Visual
                    if trackingVM.currentState == .tracking {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("A Gravar")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                Divider().background(Color.gray.opacity(0.2))
                
                // Métricas Principais (O Grande Destaque do CO2)
                HStack {
                    VStack(alignment: .leading, spacing: -2) {
                        Text(trackingVM.formattedCO2)
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        
                        Text("CO₂ evitados")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Gamificação dinâmica (Cálculo direto: 1 pt por cada 100g)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(trackingVM.co2AvoidedGrams / 100))")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(AppColors.levBlue)
                        
                        Text("Carbon Points")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
                
                // Métricas Secundárias
                HStack(spacing: 0) {
                    metricItem(title: "Tempo", value: trackingVM.formattedDuration)
                    Divider().frame(height: 30)
                    metricItem(title: "Distância", value: String(format: "%.2f km", trackingVM.distanceInKm))
                    Divider().frame(height: 30)
                    
                    // Cálculo de velocidade média
                    let hours = trackingVM.durationInSeconds / 3600.0
                    let avgSpeed = hours > 0 ? (trackingVM.distanceInKm / hours) : 0.0
                    metricItem(title: "Média", value: String(format: "%.1f km/h", avgSpeed))
                }
                
                // MARK: - 3. Controlos de Ação
                HStack(spacing: 20) {
                    if trackingVM.currentState == .idle {
                        // Botão Iniciar Gigante
                        Button(action: {
                            withAnimation(.spring()) {
                                toggleTrackingState()
                            }
                        }) {
                            Text("Iniciar Pedalada")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.levBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.neonGreen)
                                .cornerRadius(16)
                        }
                    } else {
                        // Botão Play/Pause
                        Button(action: {
                            withAnimation(.easeInOut) {
                                toggleTrackingState()
                            }
                        }) {
                            Image(systemName: trackingVM.currentState == .tracking ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(trackingVM.currentState == .tracking ? Color.orange : AppColors.neonGreen)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Botão Finalizar (Segurar 4 segundos)
                        HoldToFinishButton {
                            Task {
                                await trackingVM.finishRide(localContext: modelContext, currentUser: homeVM.currentUser)
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(UIColor.systemBackground).opacity(0.95))
                    .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 30) // Respiro para a TabBar
        }
        // 🔥 ALERTA DE SEGURANÇA E PERMISSÕES (Mantido intocável)
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Ação Necessária"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Entendi"))
            )
        }
        .onAppear {
            // Garante que o mapa foca no utilizador e pede permissão
            CLLocationManager().requestWhenInUseAuthorization()
            AnalyticsManager.shared.trackScreen("Tracking_Record_Screen")
        }
    }
    
    // MARK: - Componentes Visuais Auxiliares
    
    @ViewBuilder
    private func metricItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Lógica Rigorosa de Estado
    
    private func toggleTrackingState() {
        if trackingVM.currentState == .idle {
            // 🔥 A sua validação original executa aqui
            if canStartTracking() {
                trackingVM.activeContext = modelContext
                trackingVM.activeUser = homeVM.currentUser
                trackingVM.startRide()
            }
        } else if trackingVM.currentState == .tracking {
            trackingVM.pauseRide()
        } else if trackingVM.currentState == .paused {
            trackingVM.resumeRide()
        }
    }
    
    private func canStartTracking() -> Bool {
        guard let user = homeVM.currentUser else {
            alertMessage = "Inicie a sessão com a sua conta Apple no seu perfil para começar a calcular os seus dados."
            showErrorAlert = true
            return false
        }
        
        if user.substitutedVehicle == nil {
            alertMessage = "Falta definir o veículo que a sua bicicleta substitui. Vá ao seu Perfil para completar o seu registo."
            showErrorAlert = true
            return false
        }
        
        let locationStatus = CLLocationManager().authorizationStatus
        if locationStatus == .denied || locationStatus == .restricted {
            alertMessage = "A Velos precisa do acesso à sua localização para registar os quilómetros. Por favor, ative nas Definições do iOS."
            showErrorAlert = true
            return false
        }
        
        let motionStatus = CMMotionActivityManager.authorizationStatus()
        if motionStatus == .denied || motionStatus == .restricted {
            alertMessage = "Para pausar o trajeto automaticamente, precisamos de aceder aos sensores de movimento. Ative nas Definições do iOS."
            showErrorAlert = true
            return false
        }
        
        return true
    }
    
    private func getVehicleIcon(for vehicle: SubstitutedVehicle?) -> String {
        switch vehicle {
        case .car: return "car.fill"
        case .motorcycle: return "motorcycle"
        case .appRide: return "car.side.fill"
        case .bus: return "bus.fill"
        case .subway: return "tram.fill"
        case .walking: return "figure.walk"
        case .none: return "bicycle"
        }
    }
}

#Preview {
    TrackingRecordView(trackingVM: TrackingViewModel(), homeVM: HomeViewModel())
}
