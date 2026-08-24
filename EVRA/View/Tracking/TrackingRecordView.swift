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
import MapKit

struct TrackingRecordView: View {
    @Environment(TrackingViewModel.self) private var trackingVM
    var homeVM: HomeViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    
    // 🌙 Detetor de Tema
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        @Bindable var bindableVM = trackingVM
        
        let isDark = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let panelBg = isDark ? deepDark.opacity(0.95) : Color.white.opacity(0.95)
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        let playButtonColor = isDark ? neonGreen : AppColors.levBlue
        
        ZStack(alignment: .bottom) {
            
            // MARK: - 1. O Mapa em Background
            Map(position: $cameraPosition) {
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
            }
            .ignoresSafeArea()
            
            VStack {
                            HStack {
                                
                                Button(action: {
                                    router.showActiveTracking = false
                                }) {
                                    Image(systemName: "chevron.down.circle.fill")
                                        .font(.system(size: 34))
                                        // Adapta-se ao Dark Mode e ganha um leve fundo para não sumir no mapa
                                        .foregroundColor(primaryText.opacity(0.8))
                                        .background(Circle().fill(panelBg).frame(width: 30, height: 30))
                                        .shadow(radius: 5)
                                }
                                .padding(.leading, 17)
                                .padding(.top, 16)
                                Spacer()
                            }
                            Spacer() // Este Spacer é a magia que empurra o botão lá para o topo!
                        }
                        .zIndex(1)
            
            
            // MARK: - 2. Painel Flutuante de Telemetria
            VStack(spacing: 24) {
                
                // Cabeçalho: Veículo Substituído
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Substituindo")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(secondaryText)
                        
                        HStack(spacing: 8) {
                            let vehicleIcon = getVehicleIcon(for: homeVM.currentUser?.substitutedVehicle)
                            Image(systemName: vehicleIcon)
                                .foregroundColor(accentColor)
                                .font(.system(size: 16, weight: .bold))
                            
                            Text(homeVM.currentUser?.substitutedVehicle?.rawValue ?? "Veículo")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(primaryText)
                        }
                    }
                    Spacer()
                    
                    // Indicador de Estado Visual (A Gravar)
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                
                Divider().background(secondaryText.opacity(0.3))
                
                // Métricas Principais (O Grande Destaque do CO2)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: -4) {
                        Text(trackingVM.formattedCO2)
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundColor(primaryText)
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                        
                        Text("g CO₂ evitados")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(secondaryText)
                    }
                    
                    Spacer()
                    
                    // Gamificação dinâmica
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(trackingVM.co2AvoidedGrams / 100))")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(accentColor)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        
                        Text("Pts")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(secondaryText)
                    }
                }
                
                // Métricas Secundárias
                HStack(spacing: 0) {
                    let hours = trackingVM.durationInSeconds / 3600.0
                    let avgSpeed = hours > 0 ? (trackingVM.distanceInKm / hours) : 0.0
                    
                    metricItem(title: "Tempo", value: trackingVM.formattedDuration, primary: primaryText, secondary: secondaryText)
                    Divider().frame(height: 30).background(secondaryText.opacity(0.3))
                    metricItem(title: "Distância", value: String(format: "%.2f km", trackingVM.distanceInKm), primary: primaryText, secondary: secondaryText)
                    Divider().frame(height: 30).background(secondaryText.opacity(0.3))
                    metricItem(title: "Média", value: String(format: "%.1f km/h", avgSpeed), primary: primaryText, secondary: secondaryText)
                }
                
                // MARK: - 3. Controlos de Ação
                HStack(spacing: 20) {
                    if trackingVM.currentState == .idle {
                        // Botão Iniciar Gigante
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                toggleTrackingState()
                            }
                        }) {
                            Text("Iniciar Pedalada")
                                .font(.title3)
                                .fontWeight(.black)
                                .foregroundColor(isDark ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(playButtonColor)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: playButtonColor.opacity(0.4), radius: 10, x: 0, y: 5)
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
                                .foregroundColor(isDark ? .black : .white)
                                .frame(width: 75, height: 75)
                                .background(trackingVM.currentState == .tracking ? Color.orange : playButtonColor)
                                .clipShape(Circle())
                                .shadow(color: (trackingVM.currentState == .tracking ? Color.orange : playButtonColor).opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        
                        Spacer()
                        
                        // Botão Finalizar (O seu HoldToFinish original!)
                        HoldToFinishButton {
                            Task {
                                await trackingVM.finishRide(localContext: modelContext, currentUser: homeVM.currentUser)
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
            .padding(28)
            .background(panelBg)
            // Canto e Sombra ao estilo Apple Maps flutuante
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .shadow(color: Color.black.opacity(isDark ? 0.4 : 0.1), radius: 20, y: -5)
            .padding(.horizontal, 16)
            .padding(.bottom, 30) // Respiro para a TabBar
            
            // ALERTAS (Mantidos exatamente iguais)
            .alert("Falta pouco!", isPresented: $bindableVM.showNameRequiredAlert) {
                Button("Entendido", role: .cancel) { }
            } message: {
                Text("Para iniciarmos o rastreio e contabilizar os seus pontos no Ranking, por favor, vá à aba 'Perfil' e adicione o seu nome.")
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Ação Necessária"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Entendi"))
            )
        }
        .onAppear {
            CLLocationManager().requestWhenInUseAuthorization()
            AnalyticsManager.shared.trackScreen("Tracking_Record_Screen")
        }
    }
    
    // MARK: - Componente Auxiliar de Métrica (Responsivo)
    @ViewBuilder
    private func metricItem(title: String, value: String, primary: Color, secondary: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(secondary)
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

