//
//  ActivitiesView.swift
//  EVRA
//

import SwiftUI
import SwiftData

struct ActivitiesView: View {
    // 🔥 Puxa o histórico real e atualizado diretamente do SwiftData
    @Query(sort: \LocalRide.date, order: .reverse) private var allRides: [LocalRide]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    if allRides.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bicycle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("Ainda não tem atividades registadas.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 50)
                    } else {
                        // Gera um cartão para cada corrida na base de dados
                        ForEach(allRides) { ride in
                            ActivityCardView(ride: ride)
                        }
                    }
                }
                .padding()
            }
            .background(AppColors.levGreenBg.edgesIgnoringSafeArea(.all)) // Mantém o fundo da App
            .navigationTitle("Atividades")
        }
    }
}

// MARK: - Componente do Cartão (Design Live Activity)

struct ActivityCardView: View {
    let ride: LocalRide
    
    // Cor néon exata da imagem de referência
    private let neonColor = Color(red: 0.82, green: 1.0, blue: 0.2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. Cabeçalho (Data e Título Dinâmico)
            VStack(alignment: .leading, spacing: 4) {
                Text(relativeDateText(for: ride.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(dynamicTitle(for: ride.date))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.levBlue)
            }
            
            // 2. Métricas (Alinhamento em grelha semelhante à imagem)
            HStack(alignment: .bottom) {
                
                // Bloco do CO2 (Destaque principal)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(ride.co2Avoided))")
                        .font(.system(size: 65, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        // Ajusta automaticamente o tamanho se o número for gigante
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    VStack(alignment: .leading, spacing: -2) {
                        Text("g")
                        Text("CO2")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Outras 3 métricas em colunas
                HStack(spacing: 20) {
                    // Distância
                    VStack(alignment: .center, spacing: 2) {
                        Text(String(format: "%.2f", ride.distance))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("km")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    // Duração
                    VStack(alignment: .center, spacing: 2) {
                        Text(formattedDuration(ride.duration))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("Duração")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    // Velocidade Média
                    VStack(alignment: .center, spacing: 2) {
                        Text(String(format: "%.1f", averageSpeed))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("km/h med")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(20)
        // O fundo super escuro para fazer os números brilharem
        .background(.white)
        .cornerRadius(24)
    }
    
    // MARK: - Funções de Lógica e Formatação
    
    /// Calcula a velocidade média em km/h
    private var averageSpeed: Double {
        let hours = ride.duration / 3600.0
        return hours > 0 ? (ride.distance / hours) : 0.0
    }
    
    /// Formata os segundos em MM:SS ou HH:MM:SS
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Transforma a data em "Hoje", "Ontem" ou "12 Jul"
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
    
    /// Gera o título exato como na imagem: "terça-feira pedalada vespertina"
    private func dynamicTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE" // Retorna o dia da semana (ex: terça-feira)
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
}
