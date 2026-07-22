//
//  EVRAApp.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI
import SwiftData
import ActivityKit

@main
struct VelosApp: App {
    // 1. Monitoriza a fase da cena (Background, Active, Inactive)
    @Environment(\.scenePhase) private var scenePhase
    
    // Injetamos a ViewModel aqui se ela for usada globalmente,
    // ou usamos uma instância partilhada.
    @State private var trackingVM = TrackingViewModel()

    init() {
            // 🔥 COLOCA-SE AQUI! Garante que roda uma única vez ao abrir o app
            if UserDefaults.standard.string(forKey: "apple_user_id") == nil {
                UserDefaults.standard.set(UUID().uuidString, forKey: "apple_user_id")
                UserDefaults.standard.set("Filipe Cunha", forKey: "user_name")
                print("👤 ID de utilizador e nome gerados para o CloudKit com sucesso!")
            }
        AnalyticsManager.shared.setup()
        }
    
    var body: some Scene {
            WindowGroup {
                RootView()
                    .preferredColorScheme(.light)
                    .environment(trackingVM)
            }
            .modelContainer(for: [User.self, LocalRide.self])
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    // 🔥 Mantém o canal de comunicação da Live Activity acordado ao abrir o app
                    Task {
                        for activity in Activity<TrackingAttributes>.activities {
                            print("DEBUG: Live Activity detetada em plano de fundo: \(activity.id)")
                        }
                    }
                }
            }
        }
    }
