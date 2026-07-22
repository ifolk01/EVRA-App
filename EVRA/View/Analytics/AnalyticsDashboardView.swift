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
    
    // O estado que controla qual gráfico está a ser mostrado
    @State private var selectedMetric: DashboardMetric
    
    // Permite que o ecrã inicie na aba certa dependendo de qual cartão o utilizador clicou
    init(initialMetric: DashboardMetric = .co2) {
        _selectedMetric = State(initialValue: initialMetric)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Cabeçalho e Seletor
                VStack(alignment: .leading, spacing: 16) {
                    Text("Análise de Desempenho")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    // O seletor que alterna entre CO2 e Distância
                    Picker("Métrica", selection: $selectedMetric) {
                        ForEach(DashboardMetric.allCases, id: \.self) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // MARK: - Gráfico Dinâmico
                VStack(alignment: .leading, spacing: 16) {
                    Text("Últimos 7 dias")
                        .font(.headline)
                        .foregroundColor(.black)
                    
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
                                // Se for CO2 fica verde, se for Distância fica o Azul da LEV
                                colors: selectedMetric == .co2
                                    ? [.green, .green.opacity(0.5)]
                                    : [AppColors.levBlue, AppColors.levBlue.opacity(0.5)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6)
                        .annotation(position: .top) {
                            let value = selectedMetric == .co2 ? dataPoint.co2Kg : dataPoint.distanceKm
                            if value > 0 {
                                Text(String(format: "%.1f", value))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(height: 250)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal)
                
                // MARK: - Destaques e Métricas
                HStack(spacing: 15) {
                    // Métrica 1: Melhor Dia
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        Text("Melhor Dia")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(bestDayText)
                            .font(.headline)
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(20)
                    
                    // Métrica 2: Total da Semana
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: selectedMetric == .co2 ? "leaf.fill" : "location.fill")
                            .foregroundColor(selectedMetric == .co2 ? .green : AppColors.levBlue)
                            .font(.title2)
                        
                        Text("Nesta Semana")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(String(format: selectedMetric == .co2 ? "%.1f kg" : "%.1f km", totalThisWeek))
                            .font(.headline)
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .background(AppColors.levGreenBg.edgesIgnoringSafeArea(.all))
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
