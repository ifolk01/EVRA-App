import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

// MARK: - 2. A VIEW DO ECRÃ DE BLOQUEIO (Sem botões, focada em métricas)
struct TrackingLockScreenView: View {
    let state: TrackingAttributes.ContentState
    let startDate: Date
    
    struct AppColors {
        static let neonGreen = Color(red: 0.85, green: 1.0, blue: 0.3)
        static let levGreenBg = Color(red: 0.76, green: 0.86, blue: 0.55)
        static let levBlue = Color(red: 0.2, green: 0.3, blue: 0.8)
        static let levButtonBg = Color(red: 0.63, green: 0.74, blue: 0.42)
    }
    
    // A cor verde neon da sua marca
    let neonGreen = Color(red: 0.85, green: 1.0, blue: 0.3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // CABEÇALHO: Data e Saudação
            VStack(alignment: .leading, spacing: 2) {
                Text("Hoje")
                    .font(.caption)
                    .foregroundColor(.black)
                
                Text(greetingText)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.levBlue)
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            
            // LINHA DE MÉTRICAS (CO2 Gigante + Secundárias)
            HStack(alignment: .bottom, spacing: 15) {
                
                // DESTAQUE: CO2
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", state.co2Avoided))
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text("g CO2")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Secundária 1: Distância
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.2f", state.currentDistance))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("km")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // Secundária 2: Tempo
                VStack(alignment: .leading, spacing: 2) {
                    if state.isPaused {
                        Text(formatTime(interval: state.currentDuration))
                            .font(.headline).fontWeight(.bold).foregroundColor(.black)
                    } else {
                        Text(startDate, style: .timer)
                            .font(.headline).fontWeight(.bold).foregroundColor(.black)
                    }
                    Text("Duração")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // Secundária 3: Velocidade Média
                VStack(alignment: .leading, spacing: 2) {
                    let avgSpeed = calculateAverageSpeed(distance: state.currentDistance, timeInSeconds: state.currentDuration)
                    Text(String(format: "%.1f", avgSpeed))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("km/h med")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(height: 160) // Altura otimizada e limpa para a Live Activity
        .background(Color.white) // Fundo escuro elegante
    }
    
    // MARK: - Funções Auxiliares da Live Activity
    
    private func formatTime(interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func calculateAverageSpeed(distance: Double, timeInSeconds: TimeInterval) -> Double {
        let hours = timeInSeconds / 3600.0
        return hours > 0 ? (distance / hours) : 0.0
    }
    
    private var greetingText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE"
        let dayString = formatter.string(from: startDate).lowercased()
        
        let hour = Calendar.current.component(.hour, from: startDate)
        let period: String
        
        if hour >= 6 && hour < 12 {
            period = "diurna"
        } else if hour >= 12 && hour < 18 {
            period = "vespertina"
        } else {
            period = "noturna"
        }
        
        return "\(dayString) pedalada \(period)"
    }
}


// MARK: - 3. O WIDGET PRINCIPAL
struct TrackingWidget: Widget {
    let neonGreen = Color(red: 0.85, green: 1.0, blue: 0.3)
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrackingAttributes.self) { context in
            // ECRÃ DE BLOQUEIO (View customizada limpa, sem botões)
            TrackingLockScreenView(state: context.state, startDate: context.attributes.startTime)

        } dynamicIsland: { context in
            // ILHA DINÂMICA
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bicycle").font(.title2).foregroundColor(neonGreen)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text("PAUSA").font(.headline).foregroundColor(.gray)
                    } else {
                        Text(context.attributes.startTime, style: .timer).font(.headline).monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Distância").font(.caption).foregroundColor(.gray)
                            Text(String(format: "%.2f km", context.state.currentDistance)).font(.title3).fontWeight(.bold)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("CO2 Evitado").font(.caption).foregroundColor(.gray)
                            Text(String(format: "%.0f g", context.state.co2Avoided)).font(.title3).fontWeight(.bold).foregroundColor(neonGreen)
                        }
                    }
                    .padding(.top, 5)
                }
            } compactLeading: {
                Image(systemName: "bicycle").foregroundColor(neonGreen)
            } compactTrailing: {
                Text(String(format: "%.1f km", context.state.currentDistance)).font(.caption).fontWeight(.bold).foregroundColor(neonGreen)
            } minimal: {
                Image(systemName: "leaf.fill").foregroundColor(neonGreen)
            }
            .keylineTint(neonGreen)
        }
    }
}

@main
struct VelosWidgets: WidgetBundle {
    var body: some Widget {
        TrackingWidget()
    }
}
