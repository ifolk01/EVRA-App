// LaunchScreenView.swift
// Versão Master: Arquitetura limpa (DRY), Taptic Feedback e Efeito 3D.

import SwiftUI

struct LaunchScreenView: View {
    // Array com as nossas letras para um ForEach elegante
    let letters = ["Letter_V_plain", "Letter_E_plain", "Letter_L_plain", "Letter_O_plain", "Letter_S_plain"]
    
    @State private var wordGlow: CGFloat = 1.0
    @State private var screenOpacity: Double = 1.0
    @State private var finalZoom: CGFloat = 1.0
    
    var onAnimationFinished: () -> Void
    
    var body: some View {
        ZStack {
            Color("LevGreen")
                .ignoresSafeArea()
            
            AnimatedGradient()
                .ignoresSafeArea()
            
            HStack(spacing: 8) {
                // A magia do código limpo: iteramos o array e passamos o index para calcular o delay
                ForEach(Array(letters.enumerated()), id: \.offset) { index, imageName in
                    AnimatedLetterView(imageName: imageName, index: index)
                }
            }
            .scaleEffect(wordGlow)
        }
        .scaleEffect(finalZoom)
        .opacity(screenOpacity)
        .background(Color("LevGreen").ignoresSafeArea())
        .onAppear {
            // Pulso global + Vibração pesada
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                withAnimation(.easeInOut(duration: 0.5).repeatCount(1, autoreverses: true)) {
                    wordGlow = 1.04
                }
            }
            
            // Saída ajustada para durar um total de 3.2 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeOut(duration: 0.4)) {
                    finalZoom = 1.06
                    screenOpacity = 0.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                onAnimationFinished()
            }
        }
    }
}

// MARK: - Componente Isolado da Letra
struct AnimatedLetterView: View {
    let imageName: String
    let index: Int
    
    // Cada letra tem o seu próprio estado encapsulado
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0.0
    @State private var blur: CGFloat = 8.0
    @State private var rotationX: Double = -45.0 // 🔥 Efeito 3D inicial
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 75, height: 75)
            // A letra vem ligeiramente inclinada para trás e endireita-se
            .rotation3DEffect(.degrees(rotationX), axis: (x: 1, y: 0, z: 0))
            .scaleEffect(scale)
            .blur(radius: blur)
            .opacity(opacity)
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
            .onAppear {
                let baseDelay = 0.35
                let step = 0.16
                // Calcula o atraso automaticamente baseado na posição da letra
                let delay = baseDelay + (Double(index) * step)
                
                // Feedback Háptico no momento exato em que a letra aterra
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(delay)) {
                    scale = 1.0
                    opacity = 1.0
                    blur = 0.0
                    rotationX = 0.0 // Volta à inclinação normal (0 graus)
                }
            }
    }
}

// MARK: - Fundo Animado Otimizado
struct AnimatedGradient: View {
    @State private var animate = false
    
    var body: some View {
        LinearGradient(
            colors: animate ? [Color("LevGreenDark"), Color(AppColors.neonGreen)] : [Color(AppColors.neonGreen), Color("LevGreenDark")],
            // O gradiente agora não apenas muda de cor, mas os pontos de início e fim invertem, criando rotação
            startPoint: animate ? .bottomTrailing : .topLeading,
            endPoint: animate ? .topLeading : .bottomTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LaunchScreenView(onAnimationFinished: {})
}
