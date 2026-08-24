//
//  GoalsView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 21/07/26.
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(sort: \LocalRide.date, order: .reverse) private var allRides: [LocalRide]
    @Environment(HomeViewModel.self) private var homeVM
    @Environment(\.colorScheme) var colorScheme
    
    private var myRides: [LocalRide] {
        guard let myID = homeVM.currentUser?.appleUserIdentifier else { return [] }
        return allRides.filter { $0.userAppleID == myID }
    }
    
    // Lógica para calcular os trajetos desta semana
    private var ridesThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return myRides.filter { $0.date >= startOfWeek }.count
    }
    
    // Lógica para calcular a distância total do mês
    private var totalDistanceThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return myRides.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.distance }
    }
    
    // Lógica para calcular o CO2 total evitado (em kg)
    private var totalCO2Kg: Double {
        let totalGrams = myRides.reduce(0) { $0 + $1.co2Avoided }
        return totalGrams / 1000.0
    }
    
    // Identifica os dias da semana em que pedalou
    private var activeDaysThisWeek: Set<Int> {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let ridesThisWeekList = myRides.filter { $0.date >= startOfWeek }
        let weekdayNumbers = ridesThisWeekList.map { calendar.component(.weekday, from: $0.date) }
        return Set(weekdayNumbers)
    }

    var body: some View {
        let isDark = colorScheme == .dark
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        
        let bgApp = isDark ? Color("LevGreenDark") : AppColors.levGreenBg
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .black.opacity(0.7)
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        
        NavigationStack {
            ZStack {
                bgApp.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // MARK: - 1. A sua Ofensiva
                        VStack(alignment: .leading, spacing: 12) {
                            Text("A sua Ofensiva")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(primaryText)
                            
                            Text("Mantenha o foco nos seus pedais diários!")
                                .font(.subheadline)
                                .foregroundColor(secondaryText)
                            
                            let weekDaysInfo = [
                                (label: "D", weekdayIndex: 1), (label: "S", weekdayIndex: 2),
                                (label: "T", weekdayIndex: 3), (label: "Q", weekdayIndex: 4),
                                (label: "Q", weekdayIndex: 5), (label: "S", weekdayIndex: 6),
                                (label: "S", weekdayIndex: 7)
                            ]
                            
                            HStack(spacing: 8) {
                                ForEach(weekDaysInfo, id: \.weekdayIndex) { dayInfo in
                                    let hasPedaledOnThisDay = activeDaysThisWeek.contains(dayInfo.weekdayIndex)
                                    
                                    VStack(spacing: 6) {
                                        Text(dayInfo.label)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                        
                                        Circle()
                                            .fill(hasPedaledOnThisDay ? accentColor : Color.gray.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(isDark && hasPedaledOnThisDay ? .black : .white)
                                                    .opacity(hasPedaledOnThisDay ? 1 : 0)
                                            )
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .background(cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 12, x: 0, y: 6)
                        }
                        
                        // MARK: - 2. Metas Atuais
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Metas Atuais")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(primaryText)
                            
                            GoalProgressRow(
                                title: "Explorador Urbano",
                                subtitle: "Percorrer 50 km este mês",
                                progress: min(totalDistanceThisMonth / 50.0, 1.0),
                                currentText: String(format: "%.1f / 50 km", totalDistanceThisMonth),
                                icon: "map.fill",
                                color: accentColor
                            )
                            
                            GoalProgressRow(
                                title: "Rotina Sustentável",
                                subtitle: "15 trajetos na semana",
                                progress: min(Double(ridesThisWeek) / 15.0, 1.0),
                                currentText: "\(ridesThisWeek) / 15",
                                icon: "leaf.fill",
                                color: isDark ? .green : .green // Verde sempre verde!
                            )
                        }
                        
                        // MARK: - 3. As Suas Conquistas
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Conquistas")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(primaryText)
                            
                            let achievements = calculateAchievements()
                            
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)], spacing: 15) {
                                ForEach(achievements) { item in
                                    AchievementBox(
                                        icon: item.icon,
                                        title: item.title,
                                        subtitle: item.subtitle,
                                        isUnlocked: item.isUnlocked
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Metas")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    // ... [MANTENHA A LÓGICA DAS CONQUISTAS (calculateAchievements) INTACTA AQUI] ...
    
    // MARK: - Lógica de Avaliação Automática das Conquistas
    private struct AchievementItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
        let isUnlocked: Bool
    }
    
    private func calculateAchievements() -> [AchievementItem] {
        // 1. Primeira Volta (Desbloqueia se houver pelo menos 1 pedalada)
        let firstRideUnlocked = !myRides.isEmpty // <- Alterado
                let firstRideDateStr = formattedDate(for: myRides.last?.date) // <- Alterado
                
                // 2. Poupou 1kg de CO2 (Desbloqueia se totalCO2Kg >= 1.0)
                let co2Unlocked = totalCO2Kg >= 1.0
                
                // 3. Ofensiva de Aço (Desbloqueia se pedalou 3 ou mais dias na semana)
                let steelStreakUnlocked = activeDaysThisWeek.count >= 3
                
                // 4. Ritmo Urbano (Desbloqueia se houver uma corrida > 10 km)
                let longRideUnlocked = myRides.contains { $0.distance >= 10.0 } // <- Alterado
                
                // 5. Mestre Verde (Desbloqueia se a distância total acumulada geral >= 50 km)
                let totalLifetimeDistance = myRides.reduce(0) { $0 + $1.distance } // <- Alterado
                let masterGreenUnlocked = totalLifetimeDistance >= 50.0
                
                // 6. Lenda LEV (Desbloqueia se total Lifetime Distance >= 200 km ou 10kg de CO2)
                let levLegendUnlocked = totalLifetimeDistance >= 200.0 || totalCO2Kg >= 10.0
        
        return [
            AchievementItem(
                icon: "bicycle",
                title: "Primeira Volta",
                subtitle: firstRideUnlocked ? firstRideDateStr : "Bloqueado",
                isUnlocked: firstRideUnlocked
            ),
            AchievementItem(
                icon: "leaf.fill",
                title: "Poupou 1kg CO2",
                subtitle: co2Unlocked ? "Concluído" : String(format: "%.1f / 1.0 kg", totalCO2Kg),
                isUnlocked: co2Unlocked
            ),
            AchievementItem(
                icon: "flame.fill",
                title: "Ofensiva de Aço",
                subtitle: steelStreakUnlocked ? "Concluído" : "\(activeDaysInfoText())",
                isUnlocked: steelStreakUnlocked
            ),
            AchievementItem(
                icon: "bolt.fill",
                title: "Ritmo Urbano",
                subtitle: longRideUnlocked ? "Concluído" : "Meta: 10km num trajeto",
                isUnlocked: longRideUnlocked
            ),
            AchievementItem(
                icon: "star.fill",
                title: "Mestre Verde",
                subtitle: masterGreenUnlocked ? "Concluído" : String(format: "%.0f / 50 km", totalLifetimeDistance),
                isUnlocked: masterGreenUnlocked
            ),
            AchievementItem(
                icon: "trophy.fill",
                title: "Lenda",
                subtitle: levLegendUnlocked ? "Concluído" : "Meta: 200 km totais",
                isUnlocked: levLegendUnlocked
            )
        ]
    }
    
    private func formattedDate(for date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }
    
    private func activeDaysInfoText() -> String {
        let count = activeDaysThisWeek.count
        return "\(count) de 3 dias"
    }
}

// MARK: - Componentes de UI
// MARK: - Componentes de UI
struct GoalProgressRow: View {
    @Environment(\.colorScheme) var colorScheme
    var title: String
    var subtitle: String
    var progress: CGFloat
    var currentText: String
    var icon: String
    var color: Color
    
    var body: some View {
        let isDark = colorScheme == .dark
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        
        HStack(spacing: 16) {
            // Anéis de Progresso
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(secondaryText)
                    .lineLimit(1)
                
                Text(currentText)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(color)
                    .padding(.top, 2)
            }
            Spacer()
        }
        .padding()
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 12, x: 0, y: 6)
    }
}

struct AchievementBox: View {
    @Environment(\.colorScheme) var colorScheme
    var icon: String
    var title: String
    var subtitle: String
    var isUnlocked: Bool
    
    var body: some View {
        let isDark = colorScheme == .dark
        let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        
        let cardBg = isDark ? deepDark : .white
        let primaryText = isDark ? Color.white : .black
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        let lockedIconColor = isDark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
        let unlockedIconColor = isDark ? accentColor.opacity(0.15) : AppColors.levBlue.opacity(0.15)
        
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? unlockedIconColor : lockedIconColor)
                    .frame(width: 55, height: 55)
                Image(systemName: icon)
                    .foregroundColor(isUnlocked ? accentColor : .gray)
                    .font(.system(size: 22, weight: isUnlocked ? .bold : .regular))
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(subtitle)
                    .font(.caption2)
                    .fontWeight(isUnlocked ? .bold : .regular)
                    .foregroundColor(isUnlocked ? accentColor : .gray)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.04), radius: 12, x: 0, y: 6)
        .opacity(isUnlocked ? 1.0 : 0.7) // Dá um efeito ligeiramente "apagado" se estiver bloqueado
    }
}

#Preview {
    NavigationStack {
        GoalsView()
            .modelContainer(for: LocalRide.self, inMemory: true)
            .environment(HomeViewModel()) // 🔥 A SOLUÇÃO ESTÁ AQUI! Injetamos o modelo para o Preview não crashar.
    }
}
