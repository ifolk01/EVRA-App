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
    
    // Estados para controlar o alerta visual na identidade da app
    @State private var showAlert = false
    @State private var successMessage = ""
    
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
                            Text(homeVM.currentUser?.name ?? "Ciclista")
                                .font(.title2)
                                .fontWeight(.bold)
                            
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
                                    print("💾 Alterações persistidas com sucesso na base local!")
                                    
                                    if shouldAlert {
                                        successMessage = message
                                        showAlert = true
                                    }
                                } catch {
                                    print("❌ Erro ao salvar: \(error.localizedDescription)")
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                                            
                    Spacer(minLength: 40)
                    
                    
                    Button(action: {
                        if let user = homeVM.currentUser {
                            let userId = user.id
                            
                            // 1. Apaga do CloudKit em background (Exigência Apple)
                            Task {
                                let ckService = CloudKitService()
                                try? await ckService.deleteUser(userId: userId)
                            }
                            
                            // 2. Apaga localmente do SwiftData
                            modelContext.delete(user)
                            try? modelContext.save()
                        }
                        
                        // 3. Limpa sessão e volta ao Login
                        UserDefaults.standard.removeObject(forKey: "apple_user_id")
                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
                    }) {
                        Text("Terminar sessão")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(AppColors.levGreenBg.edgesIgnoringSafeArea(.all))
            .navigationTitle("Meu Perfil")
            .navigationBarTitleDisplayMode(.inline)
            // Alerta de confirmação ancorado na view principal
            .alert("Alteração Guardada", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(successMessage)
            }
        }
        
        .onAppear { AnalyticsManager.shared.trackScreen("Tab_Profile") }
    }
    
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

#Preview {
    ProfileView(homeVM: HomeViewModel())
        .environment(AppRouter())
}
