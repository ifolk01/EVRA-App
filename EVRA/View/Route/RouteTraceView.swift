//
//  RouteTraceView.swift
//  Velos
//
//  Created by Filipe Pinto Cunha on 24/08/26.
//

import SwiftUI
import CoreLocation

// MARK: - Desenhador de Trajeto Vetorial (Pura Matemática, sem MapKit pesado)
struct RouteTraceView: View {
    var coordinates: [CLLocationCoordinate2D]
    var lineColor: Color = .orange
    
    var body: some View {
        GeometryReader { geometry in
            if coordinates.isEmpty {
                EmptyView()
            } else {
                // 1. Encontrar os limites do trajeto para criar a escala correta
                let minLat = coordinates.map(\.latitude).min() ?? 0
                let maxLat = coordinates.map(\.latitude).max() ?? 0
                let minLon = coordinates.map(\.longitude).min() ?? 0
                let maxLon = coordinates.map(\.longitude).max() ?? 0
                
                let latRange = maxLat - minLat == 0 ? 0.0001 : maxLat - minLat
                let lonRange = maxLon - minLon == 0 ? 0.0001 : maxLon - minLon
                
                ZStack {
                    // 2. Desenhar a linha contínua do trajeto
                    Path { path in
                        for (index, coord) in coordinates.enumerated() {
                            // Normalização de X e Y baseada no tamanho disponível
                            let x = CGFloat((coord.longitude - minLon) / lonRange) * geometry.size.width
                            let y = CGFloat(1 - (coord.latitude - minLat) / latRange) * geometry.size.height
                            
                            let point = CGPoint(x: x, y: y)
                            
                            if index == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(
                        lineColor,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                    
                    // 3. Adicionar o ponto inicial (Verde) e final (Cinza)
                    if let first = coordinates.first, let last = coordinates.last {
                        let firstX = CGFloat((first.longitude - minLon) / lonRange) * geometry.size.width
                        let firstY = CGFloat(1 - (first.latitude - minLat) / latRange) * geometry.size.height
                        
                        let lastX = CGFloat((last.longitude - minLon) / lonRange) * geometry.size.width
                        let lastY = CGFloat(1 - (last.latitude - minLat) / latRange) * geometry.size.height
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .position(x: firstX, y: firstY)
                        
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                            .position(x: lastX, y: lastY)
                    }
                }
            }
        }
    }
}
