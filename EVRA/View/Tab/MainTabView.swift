//
//  MainTabView.swift
//  EVRA
//
//  Created by Filipe Pinto Cunha on 08/07/26.
//

import SwiftUI
import CoreLocation
import SwiftData

struct MainTabView: View {
    // Instanciamos o ViewModel global que partilha os dados do utilizador
    var homeVM: HomeViewModel
    var trackingVM: TrackingViewModel
    private let locationManager = CLLocationManager()
    @Query private var savedUsers: [User]
    
    var body: some View {
        TabView {
            // Aba 1: Dashboard (Início)
            HomeDashboardView(homeVM: homeVM)
                .tabItem {
                    Label("Início", systemImage: "house.fill")
                }
            
            // Aba 2: Metas
            ActivitiesView()
                            .tabItem {
                                Image(systemName: "list.bullet.rectangle.portrait")
                                    .environment(\.symbolVariants, .none)
                                Text("Atividades")
                            }
            
            
            TrackingRecordView(trackingVM: trackingVM, homeVM: homeVM)
                            .tabItem {
                                Label("Pedalar", systemImage: "record.circle")
                            }
            
           
            GroupsView()
                .tabItem {
                    Label("Grupos", systemImage: "person.3.fill")
                }
            
            // Aba 5: Perfil
            ProfileView(homeVM: homeVM)
                .tabItem {
                    Label("Perfil", systemImage: "person.crop.circle")
                }
        }
        .tint(AppColors.levBlue) // A cor do ícone quando a aba está selecionada
        .onAppear {
                    // 🔥 Injeta o utilizador instantaneamente assim que a TabBar carrega
                    if let user = savedUsers.first {
                        homeVM.currentUser = user
                    }
                    
                    locationManager.requestWhenInUseAuthorization()
                    locationManager.requestAlwaysAuthorization()
                }
                .onChange(of: savedUsers) { _, users in
                    if let user = users.first {
                        homeVM.currentUser = user
                    }
                }
            }
        }

