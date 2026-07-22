//
//  HealthKitService.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 20/07/26.
//

import Foundation
internal import HealthKit

class HealthKitService {
    private let healthStore = HKHealthStore()
    
    // 1. Pede permissão para ler apenas os treinos de Ciclismo e Distância
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    // 2. Busca todas as pedaladas a partir da última data de sincronização
    func fetchNewCyclingWorkouts(since date: Date?) async throws -> [HKWorkout] {
        let cyclingPredicate = HKQuery.predicateForWorkouts(with: .cycling)
        
        // Se for a primeira vez (nil), puxa os últimos 7 dias. Se não, puxa a partir da última sincronização.
        let startDate = date ?? Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [cyclingPredicate, datePredicate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }
}
