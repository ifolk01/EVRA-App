//
//  ProfileView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 08/07/26.
//
import SwiftUI
import SwiftData


struct ProfileView: View {
    @Bindable var homeVM: HomeViewModel
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    
    // 🌙 Detetor de Tema
    @Environment(\.colorScheme) var colorScheme
    
    // Estados para alertas e exclusão
    @State private var showAlert = false
    @State private var successMessage = ""
    @State private var mostrarAlertaExclusao = false
    
    // Estados para Edição de Perfil
    @State private var isEditingProfile = false
    @State private var editName = ""
    @State private var editEmail = ""
    
    var body: some View {
        // Cores do nosso Design System
        let isDark = colorScheme == .dark
        let neonGreen = Color(red: 0.82, green: 1.0, blue: 0.2)
        
        let bgApp = isDark ? Color("LevGreenDark") : AppColors.levGreenBg
        let primaryText = isDark ? Color.white : .black
        let secondaryText = isDark ? Color.white.opacity(0.6) : .gray
        let accentColor = isDark ? neonGreen : AppColors.levBlue
        let redAccent = isDark ? Color(red: 1.0, green: 0.4, blue: 0.4) : Color.red
        
        NavigationStack {
            ZStack {
                bgApp.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) { // Aumentado um pouco o espaçamento geral
                        
                        // MARK: - 1. Cabeçalho do Perfil (Foto e Nome)
                        VStack(spacing: 16) {
                            
                            // Avatar Premium com Sombra
                            ZStack {
                                Circle()
                                    .fill(accentColor.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                
                                Text(getInitials(from: homeVM.currentUser?.name ?? "Ciclista"))
                                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                                    .foregroundColor(accentColor)
                            }
                            // Um leve glow no modo escuro, sombra no modo claro
                            .shadow(color: accentColor.opacity(isDark ? 0.3 : 0.1), radius: 15, x: 0, y: 8)
                            
                            VStack(spacing: 4) {
                                HStack(alignment: .center, spacing: 8) {
                                    Text(homeVM.currentUser?.name ?? "Ciclista")
                                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                                        .foregroundColor(primaryText)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    // O BOTÃO DE EDITAR
                                    Button(action: {
                                        prepararEdicao()
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(accentColor)
                                            .font(.title2)
                                    }
                                }
                                
                                Text(homeVM.currentUser?.email ?? "email@exemplo.com")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(secondaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .padding(.top, 30)
                        
                        // MARK: - 2. Seção Editável de Preferências
                        if let user = homeVM.currentUser {
                            ProfilePreferencesSection(
                                substitutedVehicle: Binding(
                                    get: { user.substitutedVehicle ?? .car },
                                    set: { user.substitutedVehicle = $0 }
                                ),
                                bikeSerialNumber: Binding(
                                    get: { user.bikeSerialNumber ?? "" },
                                    set: { user.bikeSerialNumber = $0 }
                                ),
                                routes: Binding(
                                    get: { Set(user.routes) },
                                    set: { user.routes = Array($0) }
                                ),
                                onSave: { message, shouldAlert in
                                    do {
                                        try modelContext.save()
                                        UserDefaults.standard.set(user.substitutedVehicle?.rawValue, forKey: "user_substituted_vehicle")
                                        Task { try? await CloudKitService().saveUser(user) }
                                        
                                        if shouldAlert {
                                            successMessage = message
                                            showAlert = true
                                        }
                                    } catch {
                                        print("❌ Erro ao salvar preferências: \(error.localizedDescription)")
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                                                
                        Spacer(minLength: 40)
                        
                        // MARK: - 3. Botão de Excluir Conta Permanentemente
                        Button(action: {
                            mostrarAlertaExclusao = true
                        }) {
                            Text("Excluir Conta Permanentemente")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(redAccent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        // Resto dos modificadores do botão de exclusão
                        .alert("Excluir Conta Permanentemente?", isPresented: $mostrarAlertaExclusao) {
                            Button("Cancelar", role: .cancel) { }
                            Button("Excluir Tudo", role: .destructive) {
                                if let user = homeVM.currentUser {
                                    let userId = user.id
                                    Task { try? await CloudKitService().deleteUser(userId: userId) }
                                    modelContext.delete(user)
                                    try? modelContext.save()
                                }
                                UserDefaults.standard.removeObject(forKey: "apple_user_id")
                                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                                router.currentState = .login
                            }
                        } message: {
                            Text("Esta ação é irreversível. Todos os seus dados, histórico de pedaladas e Carbon Points serão apagados permanentemente.")
                        }
                        .padding(.horizontal, 24) // Alinhado perfeitamente com as margens
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Meu Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sucesso", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(successMessage)
            }
            // MARK: - Janela de Edição de Dados Pessoais
            .sheet(isPresented: $isEditingProfile) {
                NavigationStack {
                    Form {
                        Section(header: Text("Informações Públicas")) {
                            TextField("O seu nome", text: $editName)
                                .textContentType(.name)
                            
                            TextField("O seu e-mail", text: $editEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                        }
                    }
                    .navigationTitle("Editar Perfil")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") { isEditingProfile = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Guardar") { salvarDadosPessoais() }
                                .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .onAppear { AnalyticsManager.shared.trackScreen("Tab_Profile") }
    }
    
    
    // MARK: - Lógica de Edição de Perfil
    
    private func prepararEdicao() {
        // Se for "Ciclista", entregamos o campo vazio para ele não ter de apagar a palavra
        let nomeAtual = homeVM.currentUser?.name ?? ""
        editName = (nomeAtual == "Ciclista") ? "" : nomeAtual
        
        let emailAtual = homeVM.currentUser?.email ?? ""
        editEmail = (emailAtual == "email@exemplo.com") ? "" : emailAtual
        
        isEditingProfile = true
    }
    
    private func salvarDadosPessoais() {
        guard let user = homeVM.currentUser else { return }
        let novoNome = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        user.name = novoNome.isEmpty ? "Ciclista" : novoNome
        user.email = editEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Salva localmente (SwiftData garante que a interface atualiza de imediato)
        do {
            try modelContext.save()
            
            // 2. Dispara a atualização para o CloudKit em background (A Base do Ranking!)
            Task {
                let ckService = CloudKitService()
                try? await ckService.saveUser(user)
            }
            
            // 3. Feedback visual
            successMessage = "Os seus dados foram atualizados e sincronizados com sucesso!"
            showAlert = true
            isEditingProfile = false
            
        } catch {
            print("❌ Erro ao guardar o perfil: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Funções Auxiliares
    private func getInitials(from name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            let first = words.first?.first?.uppercased() ?? ""
            let last = words.last?.first?.uppercased() ?? ""
            return first + last
        } else if let first = words.first?.prefix(2).uppercased() {
            return String(first)
        }
        return "CL"
    }
}
