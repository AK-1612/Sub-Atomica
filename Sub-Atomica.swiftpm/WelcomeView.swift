import Foundation
import SwiftUI

struct WelcomeView: View {
    @Binding var isPresented: Bool
    @State private var pulse = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            Color(white: 0.02).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Pulsing Quantum Core
                ZStack {
                    Circle()
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                        .frame(width: pulse ? 250 : 100)
                        .opacity(pulse ? 0 : 1)
                    
                    Image(systemName: "atom")
                        .font(.system(size: 80, weight: .ultraLight))
                        .foregroundStyle(.cyan)
                        .shadow(color: .cyan.opacity(0.8), radius: 15)
                }
                
                VStack(spacing: 12) {
                    Text("Sub-Atomica")
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .tracking(8)
                        .foregroundStyle(.white)
                        .opacity(showText ? 1 : 0)
                        .offset(y: showText ? 0 : 20)
                    
                    Text("Welcome to the strange world of quantum mechanics")
                        .font(.system(.title3, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .foregroundStyle(.gray)
                        .opacity(showText ? 1 : 0)
                        .offset(y: showText ? 0 : 20)
                }
                
                Spacer()
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.8)) { isPresented = false }
                }) {
                    Text("INITIALIZE EXPERIMENT")
                        .font(.system(.headline, design: .monospaced).bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.cyan)
                        .clipShape(Capsule())
                        .shadow(color: .cyan.opacity(0.5), radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(showText ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false)) { pulse = true }
            withAnimation(.easeOut(duration: 1.2).delay(0.5)) { showText = true }
        }
    }
}
