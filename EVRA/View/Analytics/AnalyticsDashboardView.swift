//
//  AnalyticsDashboardView.swift
//  EVRA
//

import SwiftUI
import SwiftData
import Charts

// Define as opções do nosso seletor
enum DashboardMetric: String, CaseIterable {
    case co2 = "CO2"
    case distance = "Distância"
}

struct AnalyticsDashboardView: View {
    @Query(sort: \LocalRide.date, order: .reverse) private var allRides: [LocalRide]
    @State private var selectedMetric: DashboardMetric
    
    // 🌙 O Detetor de Tema
    @Environment(\.colorScheme) var colorScheme
    
    init(initialMetric: DashboardMetric = .co2) {
        _selectedMetric = State(initialValue: initialMetric)
    }
    
    var body: some View {
        let isDark = colorScheme == .dark
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        
        let bgApp = isDark ? Color("LevGreenDark") : AppColors.levGreenBg
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        
        // Cores Dinâmicas Baseadas na Métrica Selecionada e no Tema
        let co2Color = isDark ? neonGreen : .green
        let distColor = isDark ? Color(red: 0.4, green: 0.8, blue: 1.0) : AppColors.levBlue // Azul mais vibrante no Dark Mode
        let activeColor = selectedMetric == .co2 ? co2Color : distColor
        
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Cabeçalho e Seletor
                VStack(alignment: .leading, spacing: 16) {
                    Text("Análise de Desempenho")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryText)
                    
                    // O seletor
                    Picker("Métrica", selection: $selectedMetric) {
                        ForEach(DashboardMetric.allCases, id: \.self) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // MARK: - Gráfico Dinâmico (Redesenhado)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Últimos 7 dias")
                        .font(.headline)
                        .foregroundColor(primaryText)
                    
                    Chart(dailyData) { dataPoint in
                        BarMark(
                            x: .value("Dia", dataPoint.date, unit: .day),
                            y: .value(
                                selectedMetric == .co2 ? "CO2 (kg)" : "Distância (km)",
                                selectedMetric == .co2 ? dataPoint.co2Kg : dataPoint.distanceKm
                            )
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [activeColor, activeColor.opacity(0.3)],
                                startPoint: .top, // Invertemos para o brilho ficar no topo da barra
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(6)
                        .annotation(position: .top) {
                            let value = selectedMetric == .co2 ? dataPoint.co2Kg : dataPoint.distanceKm
                            if value > 0 {
                                Text(String(format: "%.1f", value))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(secondaryText)
                            }
                        }
                    }
                    .frame(height: 250)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                .foregroundStyle(secondaryText) // Eixo com cor adaptável
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(secondaryText.opacity(0.3)) // Grelha mais subtil
                            AxisValueLabel()
                                .foregroundStyle(secondaryText) // Eixo com cor adaptável
                        }
                    }
                }
                .padding(20)
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 12, x: 0, y: 6)
                .padding(.horizontal)
                
                // MARK: - Destaques e Métricas (Cartões Gêmeos)
                HStack(spacing: 15) {
                    
                    // Métrica 1: Melhor Dia
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        Text("Melhor Dia")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(bestDayText)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 10, x: 0, y: 5)
                    
                    // Métrica 2: Total da Semana
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: selectedMetric == .co2 ? "leaf.fill" : "location.fill")
                            .foregroundColor(activeColor)
                            .font(.title2)
                        
                        Text("Nesta Semana")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(String(format: selectedMetric == .co2 ? "%.1f kg" : "%.1f km", totalThisWeek))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .background(bgApp)
        .navigationTitle(selectedMetric == .co2 ? "Análise de CO2" : "Análise de Distância")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - LÓGICA DE AGREGAÇÃO DE DADOS MÚLTIPLOS
    
    struct DailyStats: Identifiable {
        let id = UUID()
        let date: Date
        var co2Kg: Double
        var distanceKm: Double
    }
    
    private var dailyData: [DailyStats] {
        let calendar = Calendar.current
        var aggregated: [Date: DailyStats] = [:]
        
        let today = calendar.startOfDay(for: Date())
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // Inicia o dia com zero para as duas métricas
                aggregated[date] = DailyStats(date: date, co2Kg: 0.0, distanceKm: 0.0)
            }
        }
        
        for ride in allRides {
            let startOfDay = calendar.startOfDay(for: ride.date)
            if aggregated[startOfDay] != nil {
                // Soma simultaneamente a distância e o CO2 para aquele dia
                aggregated[startOfDay]!.co2Kg += (ride.co2Avoided / 1000.0)
                aggregated[startOfDay]!.distanceKm += ride.distance
            }
        }
        
        return aggregated.values.sorted { $0.date < $1.date }
    }
    
    private var bestDayText: String {
        let best: DailyStats?
        if selectedMetric == .co2 {
            best = dailyData.max(by: { $0.co2Kg < $1.co2Kg })
            if best?.co2Kg == 0 { return "N/A" }
        } else {
            best = dailyData.max(by: { $0.distanceKm < $1.distanceKm })
            if best?.distanceKm == 0 { return "N/A" }
        }
        
        guard let bestDate = best?.date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: bestDate).capitalized
    }
    
    private var totalThisWeek: Double {
        if selectedMetric == .co2 {
            return dailyData.reduce(0) { $0 + $1.co2Kg }
        } else {
            return dailyData.reduce(0) { $0 + $1.distanceKm }
        }
    }
}

#Preview {
    AnalyticsDashboardView()
        .modelContainer(for: LocalRide.self, inMemory: true)
}
