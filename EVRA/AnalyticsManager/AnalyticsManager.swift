//
//  AnalyticsManager.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 22/07/26.
//

import Foundation
import PostHog

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    /// Inicializa o SDK (Chamar no App.swift)
    func setup() {
        // Substitua pelas chaves que o PostHog lhe vai dar ao criar o projeto
        let config = PostHogConfig(projectToken: "phc_sRBiKPw3vzZ2KauQMmVMBXJsnazqSwWkKzdoYWbEhqD8", host: "https://us.i.posthog.com")
        // Ativa a gravação de ecrã (opcional, mas incrível para MVPs)
        config.sessionReplay = true
        
        PostHogSDK.shared.setup(config)
    }
    
    /// Regista quando um utilizador entra num ecrã
    func trackScreen(_ screenName: String) {
        PostHogSDK.shared.capture("Screen Viewed", properties: ["screen_name": screenName])
    }
    
    /// Regista ações específicas (cliques, compras, resgates)
    func trackEvent(_ eventName: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(eventName, properties: properties)
    }
    
    /// Associa os eventos ao utilizador que fez o login
    func identifyUser(id: String, name: String, email: String) {
        PostHogSDK.shared.identify(id, userProperties: [
            "name": name,
            "email": email
        ])
    }
    
    /// Limpa o rastreio (Chamar no Logout)
    func resetUser() {
        PostHogSDK.shared.reset()
    }
}
