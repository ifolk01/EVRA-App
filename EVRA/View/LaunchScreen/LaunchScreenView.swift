// LaunchScreenView.swift
// Cada letra aparece individualmente com scale + delay sequencial


import SwiftUI

struct LaunchScreenView: View {
    // Uma animação por letra para efeito staggered
    @State private var scaleV: CGFloat = 0.0
    @State private var scaleE: CGFloat = 0.0
    @State private var scaleL: CGFloat = 0.0
    @State private var scaleO: CGFloat = 0.0
    @State private var scaleS: CGFloat = 0.0

    
    @State private var opacityV: Double = 0.0
    @State private var opacityE: Double = 0.0
    @State private var opacityL: Double = 0.0
    @State private var opacityO: Double = 0.0
    @State private var opacityS: Double = 0.0
    
    var onAnimationFinished: () -> Void
    
    var body: some View {
        ZStack {
            Color("LevGreen")
                .ignoresSafeArea()
            
            AnimatedGradient()
                .transition(.opacity)
            
            HStack(spacing: 8) {
                
                Image("Letter_V_plain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(scaleV)
                    .opacity(opacityV)
                
                Image("Letter_E_plain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(scaleE)
                    .opacity(opacityE)
                
            
                Image("Letter_L_plain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(scaleL)
                    .opacity(opacityL)
                
                Image("Letter_O_plain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(scaleO)
                    .opacity(opacityO)
                
                Image("Letter_S_plain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(scaleS)
                    .opacity(opacityS)
            }
        }
        .onAppear {
            // Letra V - delay 0.5s
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.5)) {
                scaleV = 1.0
                opacityV = 1.0
            }
            
            // Letra E - delay 0.75s (0.25s após E começar)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.75)) {
                scaleE = 1.0
                opacityE = 1.0
            }
            
            // Letra L - delay 1.0s (0.25s após V começar)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(1.0)) {
                scaleL = 1.0
                opacityL = 1.0
            }
            
            // Letra O - delay 1.25s (0.25s após R começar)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(1.25)) {
                scaleO = 1.0
                opacityO = 1.0
            }
            
            // Letra S - delay 1.50s (0.25s após R começar)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(1.50)) {
                scaleS = 1.0
                opacityS = 1.0
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
