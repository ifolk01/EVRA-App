import SwiftUI
import SwiftData
internal import HealthKit

struct HomeDashboardView: View {
        @Environment(TrackingViewModel.self) private var trackingVM
        @Environment(\.modelContext) private var modelContext
    
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
                                icon: "leaf",
                                iconColor: .green
                            )
                        }
                        
                        // 2. Cartão de Distância (Abre com a aba de Distância ativa)
                        NavigationLink(destination: AnalyticsDashboardView(initialMetric: .distance)) {
                            DashboardStatCard(
                                title: "Distância",
                                value: String(format: "%.1f", totalDistance),
                                unit: "km",
                                icon: "location",
                                iconColor: AppColors.levBlue
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
            .background(AppColors.levGreenBg.edgesIgnoringSafeArea(.all))
            .task {
                await syncHealthKitData()
            }
        }
        .onAppear {
                    // 🔥 Entrega as chaves do banco de dados para a ViewModel usar mais tarde
                    trackingVM.activeContext = modelContext
                    trackingVM.activeUser = homeVM.currentUser
            
                    AnalyticsManager.shared.trackScreen("Tab_Dashboard")
                }
    }
    
    // MARK: - SECÇÕES LOCAIS DA INTERFACE
    // (Mantemos apenas o que é estritamente específico desta view e não é reutilizável)
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Olá,")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
                
                Text(homeVM.currentUser?.name ?? "Ciclista")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            Spacer()
   
        }
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
        
        return VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(AppColors.levBlue)
                Text("Carbon Points")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                
                HStack(spacing: 4) {
                    if prestigeCount > 0 {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text("\(prestigeCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Nível \(currentLevel)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.levBlue)
                .clipShape(Capsule())
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(totalPoints)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
                Text("pts totais")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Para o Nível \(currentLevel == 10 ? "Máximo!" : "\(currentLevel + 1)"): \(pointsPerLevel - pointsInCurrentLevel) pts")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(percentageText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.levBlue)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .frame(width: geometry.size.width, height: 6)
                            .foregroundColor(Color.gray.opacity(0.3))
                        
                        Capsule()
                            .frame(width: geometry.size.width * CGFloat(progressRatio), height: 6)
                            .foregroundColor(AppColors.levBlue)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progressRatio)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Benefícios")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
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
}
