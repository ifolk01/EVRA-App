import SwiftUI
import SwiftData
internal import HealthKit

struct HomeDashboardView: View {
        @Environment(TrackingViewModel.self) private var trackingVM
        @Environment(\.modelContext) private var modelContext
        @Environment(\.colorScheme) var colorScheme
    
    var homeVM: HomeViewModel

    // 🔥 1. Adicionamos a consulta ao banco de dados local
        @Query(sort: \LocalRide.date, order: .reverse) private var allRides: [LocalRide]

        // 🔥 2. Lógica para calcular os trajetos desta semana
        private var ridesThisWeek: Int {
            let calendar = Calendar.current
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            return allRides.filter { $0.date >= startOfWeek }.count
        }
        
        // 🔥 3. Lógica para calcular a percentagem exata
        private var ridesGoalPercentage: Int {
            let progress = (Double(ridesThisWeek) / 15.0) * 100
            return min(Int(progress), 100) // Limita a 100% para não quebrar o layout se ele fizer 16/15
        }
    
    var body: some View {
        NavigationStack{
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Cabeçalho
                    headerSection
                    
                    // Estado de Rastreio Ativo
                    if trackingVM.currentState != .idle {
                        
                        ActiveTrackingBanner(
                            durationText: trackingVM.formattedDuration,
                            isBlinking: trackingVM.durationInSeconds.truncatingRemainder(dividingBy: 2) == 0
                        )
                    }
                    
                    // Carbon Points com Lógica de Níveis
                    NavigationLink(destination: CarbonPointsDetailView(homeVM: homeVM)) {
                        pointsCard
                    }
                    
                    // Estatísticas: CO2 e Distância
                    HStack(spacing: 15) {
                        let totalCO2InKg = (homeVM.currentUser?.totalCO2Avoided ?? 0.0) / 1000.0
                        let totalDistance = homeVM.currentUser?.totalDistance ?? 0.0
                        
                        
                        NavigationLink(destination: AnalyticsDashboardView(initialMetric: .co2)) {
                            DashboardStatCard(
                                title: "CO2 Evitado",
                                value: String(format: "%.1f", totalCO2InKg),
                                unit: "kg",
                                icon: "aqi.medium",
                                iconColor: .green
                            )
                        }
                        
                        // 2. Cartão de Distância (Abre com a aba de Distância ativa)
                        NavigationLink(destination: AnalyticsDashboardView(initialMetric: .distance)) {
                            DashboardStatCard(
                                title: "Distância",
                                value: String(format: "%.1f", totalDistance),
                                unit: "km",
                                icon: "location.north",
                                iconColor: .blue
                            )
                        }
                    }
                    
                    // 5. Meta Semanal
                    // UTILIZANDO O NOVO COMPONENTE
                    NavigationLink(destination: GoalsView()) {
                                        DashboardGoalCard(
                                            title: "Meta Semanal",
                                            subtitle: "\(ridesThisWeek) de 15 trajetos",
                                            percentageText: "\(ridesGoalPercentage)%"
                                        )
                                    }
                    
                    // 6. Benefícios
                    benefitsSection
                    
                    
                }
                .padding()
            }
            .background(
                (colorScheme == .dark ? Color("LevGreenDark") : AppColors.levGreenBg)
                                .edgesIgnoringSafeArea(.all)
                        )
            .task {
                await syncHealthKitData()
            }
        }
        .onAppear {
                   
                    trackingVM.activeContext = modelContext
                    trackingVM.activeUser = homeVM.currentUser
            
                    AnalyticsManager.shared.trackScreen("Tab_Dashboard")
                }
    }
    
    // MARK: - SECÇÕES LOCAIS DA INTERFACE
    // (Mantemos apenas o que é estritamente específico desta view e não é reutilizável)
    
    private var headerSection: some View {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Olá,")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor((colorScheme == .dark ? Color.white : Color.black).opacity(0.6))
                    
                    Text(homeVM.currentUser?.name ?? "Ciclista")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 10)
        }
    
    private var pointsCard: some View {
            let totalPoints = homeVM.currentUser?.totalCarbonPoints ?? 0
            let pointsPerLevel = 1500
            let maxLevel = 10
            let prestigeCount = totalPoints / (pointsPerLevel * maxLevel)
            let pointsInCurrentCycle = totalPoints % (pointsPerLevel * maxLevel)
            let currentLevel = (pointsInCurrentCycle / pointsPerLevel) + 1
            let pointsInCurrentLevel = pointsInCurrentCycle % pointsPerLevel
            let progressRatio = Double(pointsInCurrentLevel) / Double(pointsPerLevel)
            let percentageText = "\(Int(progressRatio * 100))%"
            
            // Cores Dinâmicas Baseadas no Tema
            let isDark = colorScheme == .dark
            let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
            let deepDark = Color(red: 0.08, green: 0.08, blue: 0.1)
            
            let primaryText = isDark ? Color.white : Color.black
            let accentColor = isDark ? neonGreen : AppColors.levBlue
            let secondaryText = isDark ? Color.white.opacity(0.6) : Color.gray
            
            return VStack(alignment: .leading, spacing: 24) {
                
                // Topo do Cartão
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                        Text("Carbon Points")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(primaryText)
                    }
                    
                    Spacer()
                    
                    // Badge de Nível Adaptável
                    HStack(spacing: 4) {
                        if prestigeCount > 0 {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(isDark ? .black : .white)
                            Text("\(prestigeCount)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(isDark ? .black : .white)
                        }
                        Text("Nível \(currentLevel)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(isDark ? .black : .white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(Capsule())
                }
                
                // O Grande Número
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(totalPoints)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(primaryText)
                    Text("XP")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                }
                
                // Barra de Progresso
                VStack(spacing: 12) {
                    HStack {
                        Text("Faltam \(pointsPerLevel - pointsInCurrentLevel) pts")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(secondaryText)
                        Spacer()
                        Text(percentageText)
                            .font(.caption)
                            .fontWeight(.black)
                            .foregroundColor(accentColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .frame(width: geometry.size.width, height: 10)
                                .foregroundColor(isDark ? Color.white.opacity(0.1) : Color(UIColor.systemGray5))
                            
                            Capsule()
                                .frame(width: geometry.size.width * CGFloat(progressRatio), height: 10)
                                .foregroundColor(accentColor)
                                .shadow(color: isDark ? accentColor.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 0)
                        }
                    }
                    .frame(height: 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progressRatio)
                }
            }
            .padding(28)
            .background(
                // Fundo mutante: Gradiente tecnológico no Dark, Branco puro no Light
                isDark
                ? AnyShapeStyle(LinearGradient(gradient: Gradient(colors: [deepDark, Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing))
                : AnyShapeStyle(Color.white)
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.05), radius: 20, x: 0, y: isDark ? 15 : 8)
        }
    
    private var benefitsSection: some View {
        let isDark = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        _ = Color(red: 0.08, green: 0.08, blue: 0.1)
        
        let primaryText = isDark ? Color.white : Color.black
        _ = isDark ? neonGreen : AppColors.levBlue
        _ = isDark ? Color.white.opacity(0.6) : Color.gray
        
        return VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Benefícios")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)
                
                Spacer()
//                Text("Ver todos >")
//                    .font(.caption)
//                    .foregroundColor(AppColors.levBlue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // UTILIZANDO O NOVO COMPONENTE
                    DashboardBenefitsLinkCard(homeVM: homeVM)
                }
            }
        }
    }
    private func syncHealthKitData() async {
            let hkService = HealthKitService()
            
            do {
                try await hkService.requestAuthorization()
                
                // Chave única por utilizador para não misturar sincronizações
                guard let appleID = homeVM.currentUser?.appleUserIdentifier else { return }
                let syncKey = "lastHKSync_\(appleID)"
                let lastSyncDate = UserDefaults.standard.object(forKey: syncKey) as? Date
                
                let workouts = try await hkService.fetchNewCyclingWorkouts(since: lastSyncDate)
                guard !workouts.isEmpty else { return } // Nada novo para sincronizar
                
                // Define o Fator de Emissão
                let vehicle = homeVM.currentUser?.substitutedVehicle
                let emissionFactor: Double
                switch vehicle {
                    case .car: emissionFactor = 150.0
                    case .appRide: emissionFactor = 160.0
                    case .motorcycle: emissionFactor = 90.0
                    case .bus: emissionFactor = 70.0
                    case .subway: emissionFactor = 30.0
                    default: emissionFactor = 0.0
                }
                
                let factor = max(emissionFactor - 15.0, 0.0)
                if factor == 0.0 { return } // A pé ou Sem Veículo não gera saldo
                
                var totalNewDistance = 0.0
                var totalNewCO2 = 0.0
                var latestWorkoutDate = lastSyncDate ?? Date.distantPast
                
                // Processa cada corrida
                for workout in workouts {
                    guard let distanceStat = workout.statistics(for: HKQuantityType.quantityType(forIdentifier: .distanceCycling)!),
                          let distanceMeters = distanceStat.sumQuantity()?.doubleValue(for: .meter()) else { continue }
                    
                    let distanceKm = distanceMeters / 1000.0
                    let co2Grams = distanceKm * factor
                    let currentAppleID = UserDefaults.standard.string(forKey: "apple_user_id") ?? "usuario_desconhecido"
                    
                    totalNewDistance += distanceKm
                    totalNewCO2 += co2Grams
                    
                    if workout.endDate > latestWorkoutDate {
                        latestWorkoutDate = workout.endDate
                    }
                    
                    // Grava o histórico individual (opcional para exibir listas depois)
                    let newRide = LocalRide(distance: distanceKm, duration: workout.duration, co2Avoided: co2Grams, date: workout.endDate, userAppleID: currentAppleID)
                    modelContext.insert(newRide)
                }
                
                // Soma ao montante do Utilizador e salva o momento da sincronização
                if totalNewDistance > 0 {
                    homeVM.currentUser?.totalDistance += totalNewDistance
                    homeVM.currentUser?.totalCO2Avoided += totalNewCO2
                    
                    UserDefaults.standard.set(latestWorkoutDate, forKey: syncKey)
                    try? modelContext.save()
                }
                
            } catch {
                print("Erro na Sincronização do HealthKit: \(error.localizedDescription)")
            }
        }
}
    

#Preview {
    HomeDashboardView(homeVM: HomeViewModel())
        .modelContainer(for: LocalRide.self, inMemory: true)
        .environment(TrackingViewModel())
        
}
