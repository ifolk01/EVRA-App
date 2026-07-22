// LaunchScreenView.swift
// Cada letra aparece individualmente com scale + delay sequencial


import SwiftUI

struct LaunchScreenView: View {
    // Uma animação por letra para efeito staggered
    @State private var scaleE: CGFloat = 0.0
    @State private var scaleV: CGFloat = 0.0
    @State private var scaleR: CGFloat = 0.0
    @State private var scaleA: CGFloat = 0.0
    
    @State private var opacityE: Double = 0.0
    @State private var opacityV: Double = 0.0
    @State private var opacityR: Double = 0.0
    @State private var opacityA: Double = 0.0
    
    var onAnimationFinished: () -> Void
    
    var body: some View {
        ZStack {
            Color("LevGreen")
                .ignoresSafeArea()
            
            AnimatedGradient()
                .transition(.opacity)
            
            HStack(spacing: 10) {
                Image("Letter_E_BebasNeue")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(scaleE)
                    .opacity(opacityE)
                
                Image("Letter_V_BebasNeue")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(scaleV)
                    .opacity(opacityV)
                
                Image("Letter_R_BebasNeue")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(scaleR)
                    .opacity(opacityR)
                
                Image("Letter_A_BebasNeue")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(scaleA)
                    .opacity(opacityA)
            }
        }
        .onAppear {
            // Letra E - delay 0.5s
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.5)) {
                scaleE = 1.0
                opacityE = 1.0
            }
            
            // Letra V - delay 0.75s (0.25s após E começar)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.75)) {
                scaleV = 1.0
                opacityV = 1.0
            }
            
            // Letra R - delay 1.0s (0.25s após V começar)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(1.0)) {
                scaleR = 1.0
                opacityR = 1.0
            }
            
            // Letra A - delay 1.25s (0.25s após R começar)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(1.25)) {
                scaleA = 1.0
                opacityA = 1.0
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                onAnimationFinished()
            }
        }
    }
}

struct AnimatedGradient: View {
    @State private var animate = false
    
    var body: some View {
        LinearGradient(
            colors: animate ? [Color("LevGreenDark"), Color(AppColors.levGreenBg)] : [Color(AppColors.levGreenBg), Color("LevGreenDark")],
            startPoint: .bottomTrailing,
            endPoint: .top
        )
        .onAppear {
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LaunchScreenView(onAnimationFinished: {})
}
