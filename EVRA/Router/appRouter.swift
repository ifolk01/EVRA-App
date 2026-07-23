//
//  appRouter.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 07/07/26.
//

import SwiftUI
import Observation


/// Define em qual "fase" macro o aplicativo está no momento.
enum AppState {
    case splash // Tela de carregamento inicial (verificando sessão no CloudKit)
    case login // Tela de Autenticação (Sign in with Apple/Google)
    case onboarding // Fluxo de registro de dados e preferências
    case main // App principal com a Tab Bar
}


/// Representa todas as telas possíveis dentro do fluxo de Onboarding.
/// Hashable é obrigatório para usar no NavigationPath do SwiftUI.
enum OnboardingStep: Hashable {
    case connectLEV // Tela "Conecte sua LEV" (Nº de Série)
    case substitutedVehicle // Tela "Qual transporte sua bicicleta mais substitui?"
    case frequency // Tela "Com que frequência você utiliza sua LEV?"
    case routes // Tela "Quais trajetos você mais realiza?"
    case locationPermission // Tela "Permissão de localização"
    case readyToStart // Tela final "Pedale, acompanhe seu impacto..."
}


/// O maestro da navegação do aplicativo.
/// Injetaremos essa classe no ambiente (@Environment) para que qualquer botão possa mudar de tela.
@Observable
class AppRouter {
    
    // O estado atual do aplicativo. Começamos na splash screen enquanto checamos o banco.
    var currentState: AppState = .splash
    
    // O caminho de navegação atual do Onboarding.
    // Uma array vazia significa que estamos na raiz (primeira tela).
     var onboardingPath = NavigationPath()
    
    // MARK: - Ações de Estado Macro
    
    /// Chamado após o usuário fazer login com sucesso
    func startOnboarding() {
        // Limpa qualquer navegação residual
        onboardingPath = NavigationPath()
        currentState = .onboarding
    }
    
    /// Chamado na última tela do onboarding após salvar os dados no CloudKit
    func finishOnboardingAndGoHome() {
        currentState = .main
    }
    
    /// Desloga o usuário e devolve para a tela de login
    func logout() {
        onboardingPath = NavigationPath()
        currentState = .login
    }
    
    // MARK: - Ações de Navegação Interna (NavigationStack)
    
    /// Empilha uma nova tela no fluxo atual
    func navigate(to step: OnboardingStep) {
        onboardingPath.append(step)
    }
    
    /// Remove a última tela da pilha (botão de voltar)
    func pop() {
        guard !onboardingPath.isEmpty else { return }
        onboardingPath.removeLast()
    }
    
    /// Volta diretamente para a raiz do NavigationStack atual
    func popToRoot() {
        onboardingPath = NavigationPath()
    }
}
