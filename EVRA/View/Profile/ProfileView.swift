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
    
    // Estados para alertas e exclusão
    @State private var showAlert = false
    @State private var successMessage = ""
    @State private var mostrarAlertaExclusao = false
    
    // MARK: - Novos Estados para Edição de Perfil
    @State private var isEditingProfile = false
    @State private var editName = ""
    @State private var editEmail = ""
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // 1. Cabeçalho do Perfil (Foto e Nome)
                    VStack(spacing: 16) {
                        Circle()
                            .fill(AppColors.levBlue.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(getInitials(from: homeVM.currentUser?.name ?? "Ciclista"))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.levBlue)
                            )
                        
                        VStack(spacing: 4) {
                            HStack {
                                Text(homeVM.currentUser?.name ?? "Ciclista")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                // O BOTÃO DE EDITAR
                                Button(action: {
                                    prepararEdicao()
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(AppColors.levBlue)
                                        .font(.title3)
                                }
                            }
                            
                            Text(homeVM.currentUser?.email ?? "email@exemplo.com")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 30)
                    
                    // 2. Seção Editável de Preferências
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
                                    // Sincroniza com a nuvem também as preferências
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
                    
                    // 3. Botão de Excluir Conta Permanentemente
                    Button(action: {
                        mostrarAlertaExclusao = true
                    }) {
                        Text("Excluir Conta Permanentemente")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .alert("Excluir Conta Permanentemente?", isPresented: $mostrarAlertaExclusao) {
                        Button("Cancelar", role: .cancel) { }
                        
                        Button("Excluir Tudo", role: .destructive) {
                            if let user = homeVM.currentUser {
                                let userId = user.id
                                
                                Task {
                                    let ckService = CloudKitService()
                                    try? await ckService.deleteUser(userId: userId)
                                }
                                
                                modelContext.delete(user)
                                try? modelContext.save()
                            }
                            
                            UserDefaults.standard.removeObject(forKey: "apple_user_id")
                            UserDefaults.standard.set(false, forKey: "isLoggedIn")
                            
                            // Redireciona o utilizador de volta ao início
                            router.currentState = .login
                        }
                    } message: {
                        Text("Esta ação é irreversível. Todos os seus dados, histórico de pedaladas e Carbon Points serão apagados permanentemente.")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(AppColors.levGreenBg.edgesIgnoringSafeArea(.all))
            .navigationTitle("Meu Perfil")
            .navigationBarTitleDisplayMode(.inline)
            
            // Alerta de sucesso geral
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
                            Button("Guardar") {
                                salvarDadosPessoais()
                            }
                            // Impede de guardar um nome totalmente em branco
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
