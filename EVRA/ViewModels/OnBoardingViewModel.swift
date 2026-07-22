//
//  OnBoardingViewModel.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import Foundation
import Observation
import AuthenticationServices
import SwiftData

// MARK: - Tipos Auxiliares do Onboarding
// Eles refletem perfeitamente as opções das suas telas de UI.

enum UsageFrequency: String, CaseIterable {
    case everyday = "Todo dia"
    case frequently = "Frequentemente"
    case sometimes = "Às vezes"
    case occasionally = "Ocasionalmente"
}

enum UsualRoute: String, CaseIterable, Identifiable {
    case work = "Trabalho"
    case college = "Faculdade"
    case gym = "Academia"
    case market = "Mercado"
    case leisure = "Lazer"
    
    var id: String { self.rawValue }
}

// MARK: - Onboarding ViewModel

/// ViewModel responsável por coletar todos os dados durante o fluxo de registro
/// e, ao final, consolidar a criação do usuário no banco de dados.
@Observable
class OnboardingViewModel {
    
    // MARK: - Dependências
    
    // Injetamos o serviço para que a ViewModel não converse direto com o banco
    private let cloudKitService: CloudKitService
    
    // MARK: - Dados Coletados (Estado)
    
    // 1. Dados de Autenticação (Vindos do Sign in with Apple/Google/Email)
    var appleUserIdentifier: String = ""
    var name: String = ""
    var email: String = ""
    
    // 2. Dados da Bicicleta e Hábitos
    var bikeSerialNumber: String = ""
    var frequency: String = ""
    var selectedFrequency: UsageFrequency? = nil
    var selectedRoutes: Set<UsualRoute> = [] // Set é ideal pois evita itens duplicados (Multi-select)
    var substitutedVehicle: SubstitutedVehicle? = nil
    var routes: [String] = []
    // MARK: - Controle de UI
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var showError: Bool = false
    
    // Quando isso virar true, o seu AppRouter saberá que deve sair do Onboarding e ir pra Home
    var isRegistrationComplete: Bool = false
    
    // MARK: - Inicializador
    
    init(cloudKitService: CloudKitService = CloudKitService()) {
        self.cloudKitService = cloudKitService
    }
    
    // MARK: - Ações de UI
    
    /// Adiciona ou remove uma rota da seleção múltipla (Tela: "Quais trajetos você mais realiza?")
    func toggleRoute(_ route: UsualRoute) {
        if selectedRoutes.contains(route) {
            selectedRoutes.remove(route)
        } else {
            selectedRoutes.insert(route)
        }
    }
    
    /// Simula o preenchimento dos dados do Sign In With Apple.
    /// Em um cenário real, isso seria chamado no delegate do ASAuthorizationController
    func handleAppleSignIn(identifier: String, fullName: String?, email: String?) {
        self.appleUserIdentifier = identifier
        if let fullName = fullName, !fullName.isEmpty {
            self.name = fullName
        }
        if let email = email {
            self.email = email
        }
    }
    
    // MARK: - Finalização e Persistência
  
        
        /// Constrói o modelo final e envia para o SwiftData (que sincroniza com CloudKit sozinho)
    func completeRegistration(context: ModelContext) async {
            let fetchDescriptor = FetchDescriptor<User>()
            let existingUsers = (try? context.fetch(fetchDescriptor)) ?? []
            
            if let user = existingUsers.first {
                // 1. ATUALIZAÇÃO SEGURA
                // Só atualizamos nome e email se a Apple os tiver enviado (evita apagar o que já estava no CloudKit)
                if !self.name.isEmpty { user.name = self.name }
                if !self.email.isEmpty { user.email = self.email }
                
                // 2. Garante que pega no veículo independentemente da variável que a UI alimentou
                let vehicleToSave = self.substitutedVehicle?.rawValue ?? self.substitutedVehicle?.rawValue ?? ""
                if !vehicleToSave.isEmpty {
                    user.substitutedVehicleRawValue = vehicleToSave
                }
                
                user.frequency = self.frequency
                user.routes = self.routes
                
            } else {
                // 3. CRIAÇÃO DE UM UTILIZADOR TOTALMENTE NOVO
                let vehicleToSave = self.substitutedVehicle?.rawValue ?? self.substitutedVehicle?.rawValue ?? ""
                let newUser = User(
                    appleUserIdentifier: self.appleUserIdentifier,
                    name: self.name.isEmpty ? "Ciclista" : self.name,
                    email: self.email,
                    bikeSerialNumber: nil,
                    substitutedVehicleRawValue: vehicleToSave,
                    frequency: self.frequency,
                    routes: self.routes
                )
                context.insert(newUser)
            }
            
            do {
                try context.save()
                print("✅ Registo concluído/atualizado com sucesso!")
            } catch {
                print("❌ Erro ao salvar registo: \(error.localizedDescription)")
            }
        }
    
    private func triggerError(message: String) {
        self.errorMessage = message
        self.showError = true
        self.isLoading = false
    }
}

extension OnboardingViewModel {
    
    func processAppleSignInResult(credential: ASAuthorizationAppleIDCredential) {
        // O "user" aqui é o identificador único que a Apple nos dá
        let userId = credential.user
        
        // Extraímos o nome (opcional)
        let fullName = credential.fullName
        let nameString = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        // Extraímos o e-mail (só disponível na primeira vez que o usuário loga)
        let email = credential.email ?? ""
        
        // Chamamos a função que já tínhamos planeado
        self.handleAppleSignIn(identifier: userId, fullName: nameString, email: email)
        
       
    }
}
