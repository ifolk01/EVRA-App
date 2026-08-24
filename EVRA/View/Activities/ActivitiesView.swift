//
//  ActivitiesView.swift
//  EVRA
//

import SwiftUI
import SwiftData

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
        
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. Cabeçalho (Data e Título Dinâmico)
            VStack(alignment: .leading, spacing: 4) {
                Text(relativeDateText(for: ride.date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(secondaryText)
                
                Text(dynamicTitle(for: ride.date))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)
                    .lineLimit(1) // Proteção extra no título
                    .minimumScaleFactor(0.8)
            }
            
            // 2. Métricas
            HStack(alignment: .bottom, spacing: 10) { // Espaçamento geral reduzido
                
                // Bloco do CO2 (Destaque principal)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", ride.co2Avoided))
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(primaryText)
                        .minimumScaleFactor(0.4) // Encolhe até 40% se o número for gigante
                        .lineLimit(1)
                    
                    VStack(alignment: .leading, spacing: -2) {
                        Text("g")
                        Text("CO2")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(secondaryText)
                }
                
                Spacer(minLength: 4) // Dá prioridade aos números
                
                // Outras 3 métricas em colunas (Agora flexíveis!)
                HStack(spacing: 8) {
                    metricColumn(value: String(format: "%.2f", ride.distance), unit: "km", primary: primaryText, secondary: secondaryText)
                    metricColumn(value: formattedDuration(ride.duration), unit: "Duração", primary: primaryText, secondary: secondaryText)
                    metricColumn(value: String(format: "%.1f", averageSpeed), unit: "km/h med", primary: primaryText, secondary: secondaryText)
                }
            }
        }
        .padding(20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 12, x: 0, y: isDark ? 8 : 6)
    }
    
    // 🔥 Subcomponente BLINDADO contra quebra de linha
    @ViewBuilder
    private func metricColumn(value: String, unit: String, primary: Color, secondary: Color) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(primary)
                .lineLimit(1) // PROÍBE QUEBRA DE LINHA
                .minimumScaleFactor(0.5) // Permite encolher
            Text(unit)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(minWidth: 40) // Dá um tamanho base para ele não esmagar os outros
    }
    
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
