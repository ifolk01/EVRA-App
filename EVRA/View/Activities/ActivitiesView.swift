//
//  ActivitiesView.swift
//  EVRA
//

import SwiftUI
import SwiftData
import CoreLocation

struct ActivitiesView: View {
    @Query(sort: \LocalRide.date, order: .reverse) private var allRides: [LocalRide]
    @Environment(HomeViewModel.self) private var homeVM
    @Environment(\.colorScheme) var colorScheme
        // Variável que vai receber a lista filtrada
        @State private var myRides: [LocalRide] = []
        @Environment(\.modelContext) private var modelContext
    
    var body: some View {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        if myRides.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bicycle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.black.opacity(0.5))
                                Text("Ainda não tem atividades registadas.")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 50)
                        } else {
                            // Gera um cartão para cada corrida na base de dados
                            ForEach(myRides) { ride in
                                ActivityCardView(ride: ride)
                            }
                        }
                    }
                    .padding()
                }
                .background(
                  
                    (colorScheme == .dark ? Color("LevGreenDark") : AppColors.levGreenBg)
                        .edgesIgnoringSafeArea(.all)
                )
                .navigationTitle("Atividades")
                .onAppear {
                    fetchMyRides()
                }
            }
        }
    
    private func fetchMyRides() {
            // Pega o ID do utilizador que fez o login
            guard let myID = homeVM.currentUser?.appleUserIdentifier else { return }
            
            // Cria a regra: Só buscar as pedaladas carimbadas com o MEU appleUserIdentifier
            let fetchDescriptor = FetchDescriptor<LocalRide>(
                predicate: #Predicate { $0.userAppleID == myID },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            do {
                myRides = try modelContext.fetch(fetchDescriptor)
            } catch {
                print("❌ Erro ao buscar atividades privadas: \(error)")
            }
        }
}


// MARK: - Componente do Cartão Redesenhado e Responsivo
struct ActivityCardView: View {
    let ride: LocalRide
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let isDark = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        
        HStack(spacing: 12) {
            
            // LADO ESQUERDO: Dados e Métricas organizados VERTICALMENTE
            VStack(alignment: .leading, spacing: 18) { // Aumentamos o espaçamento para usar bem a altura
                
                // 1. Cabeçalho
                VStack(alignment: .leading, spacing: 4) {
                    Text(relativeDateText(for: ride.date))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(secondaryText)
                    
                    Text(dynamicTitle(for: ride.date))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                
                // 2. O Gigante CO2 (Agora reina sozinho na sua própria linha)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", ride.co2Avoided))
                        .font(.system(size: 46, weight: .black, design: .rounded)) // Aumentado um pouco já que tem espaço
                        .foregroundColor(primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    
                    VStack(alignment: .leading, spacing: -2) {
                        Text("g")
                        Text("CO2")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(secondaryText)
                }
                
                // 3. As métricas secundárias (Ganham a largura inteira da coluna esquerda)
                HStack(spacing: 16) {
                    metricColumn(value: String(format: "%.2f", ride.distance), unit: "km", primary: primaryText, secondary: secondaryText)
                    
                    metricColumn(value: formattedDuration(ride.duration), unit: "Duração", primary: primaryText, secondary: secondaryText)
                    
                    metricColumn(value: String(format: "%.1f", averageSpeed), unit: "km/h med", primary: primaryText, secondary: secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // LADO DIREITO: O Traço da Rota (Centrado automaticamente na nova altura do cartão)
            let realCoordinates = ride.route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            
            if realCoordinates.isEmpty {
                Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                    .font(.system(size: 36))
                    .foregroundColor(secondaryText.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .padding(.trailing, 4)
            } else {
                RouteTraceView(coordinates: realCoordinates, lineColor: .orange)
                    .frame(width: 90, height: 90)
                    .padding(.trailing, 4)
            }
        }
        .padding(20) // Aumentamos o respiro interno do cartão
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 12, x: 0, y: isDark ? 8 : 6)
    }
    
    // 🔥 Subcomponente BLINDADO
    @ViewBuilder
    private func metricColumn(value: String, unit: String, primary: Color, secondary: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) { // Alinhamento à esquerda fica mais elegante nesta nova disposição
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text(unit)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
        // Dá um tamanho base para ele não esmagar os outros
    
    
    // MARK: - Funções de Lógica e Formatação (Mantidas intocáveis)
    private var averageSpeed: Double {
        let hours = ride.duration / 3600.0
        return hours > 0 ? (ride.distance / hours) : 0.0
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func relativeDateText(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoje"
        } else if calendar.isDateInYesterday(date) {
            return "Ontem"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.dateFormat = "dd MMM"
            return formatter.string(from: date)
        }
    }
    
    private func dynamicTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: date).lowercased()
        
        let hour = Calendar.current.component(.hour, from: date)
        let period: String
        
        switch hour {
        case 0..<12:
            period = "matinal"
        case 12..<18:
            period = "vespertina"
        default:
            period = "noturna"
        }
        
        return "\(dayName) pedalada \(period)"
    }
}

#Preview {
    ActivitiesView()
        .modelContainer(for: LocalRide.self, inMemory: true)
        .environment(HomeViewModel())
        
}
