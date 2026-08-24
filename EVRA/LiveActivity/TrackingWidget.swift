import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

// MARK: - 1. A VIEW DO ECRÃ DE BLOQUEIO (Responsiva ao Tema)
struct TrackingLockScreenView: View {
    let state: TrackingAttributes.ContentState
    let startDate: Date
    
    @Environment(\.colorScheme) var colorScheme
    
    struct AppColors {
        static let neonGreen = Color(red: 0.85, green: 1.0, blue: 0.3)
        static let levGreenBg = Color(red: 0.76, green: 0.86, blue: 0.55)
        static let levBlue = Color(red: 0.2, green: 0.3, blue: 0.8)
        static let levButtonBg = Color(red: 0.63, green: 0.74, blue: 0.42)
    }
    
    var body: some View {
        let isDark = colorScheme == .dark
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        let accentColor = isDark ? AppColors.neonGreen : AppColors.levBlue
        
        VStack(alignment: .leading, spacing: 14) {
            // CABEÇALHO: Data e Saudação
            VStack(alignment: .leading, spacing: 2) {
                Text("Hoje")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(secondaryText)
                
                Text(greetingText)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            
            // LINHA DE MÉTRICAS (CO2 Gigante + Secundárias com Responsividade)
            HStack(alignment: .bottom, spacing: 15) {
                
                // DESTAQUE: CO2
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    let co2Formatted = formatWidgetCO2(state.co2Avoided)
                    
                    Text(co2Formatted.value)
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(primaryText)
                        .minimumScaleFactor(0.4) // 🔥 Forte proteção contra números enormes (ex: 5000g)
                        .lineLimit(1)
                    
                    Text(co2Formatted.unit)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(secondaryText)
                }
                
                Spacer()
                
                // Secundária 1: Distância
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.2f", state.currentDistance))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(primaryText)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("km")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(secondaryText)
                }
                
                // Secundária 2: Tempo
                VStack(alignment: .leading, spacing: 2) {
                    if state.isPaused {
                        Text(formatTime(interval: state.currentDuration))
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(primaryText)
                    } else {
                        Text(startDate, style: .timer)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(primaryText)
                    }
                    Text("Duração")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(secondaryText)
                }
                
                // Secundária 3: Velocidade Média
                VStack(alignment: .leading, spacing: 2) {
                    let avgSpeed = calculateAverageSpeed(distance: state.currentDistance, timeInSeconds: state.currentDuration)
                    Text(String(format: "%.1f", avgSpeed))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(primaryText)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("km/h med")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(secondaryText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(height: 160)
        .background(cardBg) // 🔥 Fundo que reage ao Dark Mode
    }
    
    // MARK: - Funções Auxiliares (Mantidas Intactas)
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
    
    private func formatWidgetCO2(_ grams: Double) -> (value: String, unit: String) {
        if grams >= 1000.0 {
            let kg = grams / 1000.0
            return (String(format: "%.1f", kg), "kg CO2")
        } else {
            return (String(format: "%.0f", grams), "g CO2")
        }
    }
}


// MARK: - 2. O WIDGET PRINCIPAL (Configuração da Ilha Dinâmica)
struct TrackingWidget: Widget {
    let neonGreen = Color(red: 0.85, green: 1.0, blue: 0.3)
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrackingAttributes.self) { context in
            // ECRÃ DE BLOQUEIO
            TrackingLockScreenView(state: context.state, startDate: context.attributes.startTime)
            
        } dynamicIsland: { context in
            // ILHA DINÂMICA (Sempre escura, logo as fontes têm de ser claras/vibrantes)
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bicycle")
                        .font(.title2)
                        .foregroundColor(neonGreen)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text("PAUSA")
                            .font(.headline)
                            .foregroundColor(.gray)
                    } else {
                        Text(context.attributes.startTime, style: .timer)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Distância")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(String(format: "%.2f km", context.state.currentDistance))
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7) // 🔥 Proteção Responsiva
                                .lineLimit(1)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("CO2 Evitado")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(String(format: "%.0f g", context.state.co2Avoided))
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(neonGreen)
                                .minimumScaleFactor(0.7) // 🔥 Proteção Responsiva
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 5)
                }
            } compactLeading: {
                Image(systemName: "bicycle").foregroundColor(neonGreen)
            } compactTrailing: {
                Text(String(format: "%.1f km", context.state.currentDistance))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(neonGreen)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
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
