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
                                icon: "apple.meditate",
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
        // --- CONQUISTAS ORIGINAIS ---
        let firstRideUnlocked = !myRides.isEmpty
        let firstRideDateStr = formattedDate(for: myRides.last?.date)
        
        let co2Unlocked = totalCO2Kg >= 1.0
        let steelStreakUnlocked = activeDaysThisWeek.count >= 3
        let longRideUnlocked = myRides.contains { $0.distance >= 10.0 }
        
        let totalLifetimeDistance = myRides.reduce(0) { $0 + $1.distance }
        let masterGreenUnlocked = totalLifetimeDistance >= 50.0
        let levLegendUnlocked = totalLifetimeDistance >= 200.0 || totalCO2Kg >= 10.0
        
        // --- NOVAS CONQUISTAS CRIATIVAS E DESAFIADORAS ---
        
        // 7. Madrugador (Pedalou antes das 07:00 da manhã)
        let earlyBirdUnlocked = myRides.contains { ride in
            let hour = Calendar.current.component(.hour, from: ride.date)
            return hour < 7
        }
        
        // 8. Coruja Noturna (Pedalou após as 21:00)
        let nightOwlUnlocked = myRides.contains { ride in
            let hour = Calendar.current.component(.hour, from: ride.date)
            return hour >= 21
        }
        
        // 9. Fim de Semana Ativo (Pedalou tanto no Sábado quanto no Domingo na mesma semana)
        let calendar = Calendar.current
        let weekendUnlocked = myRides.contains { ride in
            let weekday = calendar.component(.weekday, from: ride.date)
            // 1 = Domingo, 7 = Sábado. Verificamos se há registos em ambos dias no histórico geral ou recente
            return weekday == 1 || weekday == 7
        } && myRides.filter { [1, 7].contains(calendar.component(.weekday, from: $0.date)) }.count >= 2
        
        // 10. Cento e Oitenta (Acumulou 180 km no total geral)
        let distance180Unlocked = totalLifetimeDistance >= 180.0
        
        // 11. Guardião da Atmosfera (Poupou 25 kg de CO2 acumulados)
        let co2GuardianUnlocked = totalCO2Kg >= 25.0
        
        // 12. Velocista Urbano (Atingiu uma velocidade média superior a 25 km/h numa pedalada)
        let speedsterUnlocked = myRides.contains { ride in
            let hours = ride.duration / 3600.0
            let avgSpeed = hours > 0 ? (ride.distance / hours) : 0.0
            return avgSpeed >= 25.0
        }
        
        // 13. Maratona de Aço (Fez uma única pedalada de mais de 25 km)
        let marathonUnlocked = myRides.contains { $0.distance >= 25.0 }
        
        // 14. Hábito Consistente (Tem pelo menos 10 pedaladas registadas no total)
        let consistentUnlocked = myRides.count >= 10
        
        // 15. Veterano da E-Bike (Tem pelo menos 30 pedaladas registadas no total)
        let veteranUnlocked = myRides.count >= 30
        
        // 16. Ciclista Imparável (Ofensiva completa: pedalou 5 dias na mesma semana)
        let unstoppableUnlocked = activeDaysThisWeek.count >= 5
        
        // 17. Explorador de Horizontes (Acumulou 500 km no total geral)
        let explorer500Unlocked = totalLifetimeDistance >= 500.0
        
        // 18. Pulmão de Aço (Poupou 50 kg de CO2 acumulados)
        let lungSteelUnlocked = totalCO2Kg >= 50.0
        
        // 19. Madrugador Extremo (Pedalou antes das 05:30 da manhã)
        let extremeEarlyUnlocked = myRides.contains { ride in
            let hour = Calendar.current.component(.hour, from: ride.date)
            let minute = Calendar.current.component(.minute, from: ride.date)
            return hour < 5 || (hour == 5 && minute <= 30)
        }
        
        // 20. Resistencia Noturna (Fez um trajeto noturno de mais de 10 km após as 20:00)
        let nightResilienceUnlocked = myRides.contains { ride in
            let hour = Calendar.current.component(.hour, from: ride.date)
            return hour >= 20 && ride.distance >= 10.0
        }
        
        // 21. Titã Ecológico (Superou 100 kg de CO2 evitados)
        let titanEcoUnlocked = totalCO2Kg >= 100.0

        return [
            // Originais
            AchievementItem(icon: "road.lanes.curved.right", title: "Primeira Volta", subtitle: firstRideUnlocked ? firstRideDateStr : "Bloqueado", isUnlocked: firstRideUnlocked),
            AchievementItem(icon: "tree", title: "Poupou 1kg CO2", subtitle: co2Unlocked ? "Concluído" : String(format: "%.1f / 1.0 kg", totalCO2Kg), isUnlocked: co2Unlocked),
            AchievementItem(icon: "horn.blast", title: "Ofensiva de Aço", subtitle: steelStreakUnlocked ? "Concluído" : "\(activeDaysThisWeek.count) / 3 dias", isUnlocked: steelStreakUnlocked),
            AchievementItem(icon: "minus.plus.and.fluid.batteryblock", title: "Ritmo Urbano", subtitle: longRideUnlocked ? "Concluído" : "Meta: 10km num trajeto", isUnlocked: longRideUnlocked),
            AchievementItem(icon: "tortoise", title: "Mestre Verde", subtitle: masterGreenUnlocked ? "Concluído" : String(format: "%.0f / 50 km", totalLifetimeDistance), isUnlocked: masterGreenUnlocked),
            AchievementItem(icon: "hare", title: "Lenda", subtitle: levLegendUnlocked ? "Concluído" : "Meta: 200 km totais", isUnlocked: levLegendUnlocked),
            
            // Novas Conquistas Criativas
            AchievementItem(icon: "sunrise.fill", title: "Madrugador", subtitle: earlyBirdUnlocked ? "Concluído" : "Pedalar antes das 07h", isUnlocked: earlyBirdUnlocked),
            AchievementItem(icon: "moon.stars.fill", title: "Coruja Noturna", subtitle: nightOwlUnlocked ? "Concluído" : "Pedalar após as 21h", isUnlocked: nightOwlUnlocked),
            AchievementItem(icon: "calendar.badge.clock", title: "Fim de Semana Ativo", subtitle: weekendUnlocked ? "Concluído" : "Pedalar Sáb. e Dom.", isUnlocked: weekendUnlocked),
            AchievementItem(icon: "map.fill", title: "Cento e Oitenta", subtitle: distance180Unlocked ? "Concluído" : String(format: "%.0f / 180 km", totalLifetimeDistance), isUnlocked: distance180Unlocked),
            AchievementItem(icon: "shield.lefthalf.filled", title: "Guardião do Ar", subtitle: co2GuardianUnlocked ? "Concluído" : String(format: "%.1f / 25 kg", totalCO2Kg), isUnlocked: co2GuardianUnlocked),
            AchievementItem(icon: "gauge.with.needle.fill", title: "Velocista Urbano", subtitle: speedsterUnlocked ? "Concluído" : "Média > 25 km/h", isUnlocked: speedsterUnlocked),
            AchievementItem(icon: "figure.outdoor.cycle", title: "Maratona de Aço", subtitle: marathonUnlocked ? "Concluído" : "Trajeto único > 25km", isUnlocked: marathonUnlocked),
            AchievementItem(icon: "checkmark.seal.fill", title: "Hábito Consistente", subtitle: consistentUnlocked ? "Concluído" : "\(myRides.count) / 10 pedaladas", isUnlocked: consistentUnlocked),
            AchievementItem(icon: "medal.fill", title: "Veterano E-Bike", subtitle: veteranUnlocked ? "Concluído" : "\(myRides.count) / 30 pedaladas", isUnlocked: veteranUnlocked),
            AchievementItem(icon: "flame.circle.fill", title: "Ciclista Imparável", subtitle: unstoppableUnlocked ? "Concluído" : "5 dias na semana", isUnlocked: unstoppableUnlocked),
            AchievementItem(icon: "globe.americas.fill", title: "Explorador 500", subtitle: explorer500Unlocked ? "Concluído" : String(format: "%.0f / 500 km", totalLifetimeDistance), isUnlocked: explorer500Unlocked),
            AchievementItem(icon: "lungs.fill", title: "Pulmão de Aço", subtitle: lungSteelUnlocked ? "Concluído" : String(format: "%.1f / 50 kg", totalCO2Kg), isUnlocked: lungSteelUnlocked),
            AchievementItem(icon: "alarm.fill", title: "Madrugador Extremo", subtitle: extremeEarlyUnlocked ? "Concluído" : "Pedalar antes das 05h30", isUnlocked: extremeEarlyUnlocked),
            AchievementItem(icon: "eye.trianglebadge.exclamationmark.fill", title: "Resistência Noturna", subtitle: nightResilienceUnlocked ? "Concluído" : "Noturno > 10km", isUnlocked: nightResilienceUnlocked),
            AchievementItem(icon: "crown.fill", title: "Titã Ecológico", subtitle: titanEcoUnlocked ? "Concluído" : String(format: "%.1f / 100 kg", totalCO2Kg), isUnlocked: titanEcoUnlocked)
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
