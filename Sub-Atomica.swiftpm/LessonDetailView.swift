import SwiftUI

struct LessonDetailView: View {
    let concept: QuantumConcept
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var progressManager: UserProgressManager
    
    @State private var executeSimulation = false
    @State private var resetSimulation = false
    @State private var capturePhoto = false
    @State private var isModelPlaced = false
    @State private var physicsIntensity: Float = 1.0
    @State private var capturedImage: UIImage?
    @State private var showInfo = true
    
    var body: some View {
        ZStack {
            ARViewContainer(
                concept: concept,
                executeSimulation: $executeSimulation,
                resetSimulation: $resetSimulation,
                capturePhoto: $capturePhoto,
                isModelPlaced: $isModelPlaced,
                physicsIntensity: $physicsIntensity,
                capturedImage: $capturedImage
            )
            .ignoresSafeArea()
            
            VStack {
                // Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left").bold()
                            .padding().background(.ultraThinMaterial).clipShape(Circle())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(concept.title).font(.headline)
                        Text("SIMULATION ACTIVE").font(.system(size: 10, design: .monospaced)).foregroundStyle(concept.themeColor)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(.ultraThinMaterial).clipShape(Capsule())
                }
                .padding()
                
                Spacer()
                
                // Bottom Controls
                VStack(spacing: 20) {
                    if showInfo {
                        Text(concept.description)
                            .font(.footnote).foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            executeSimulation.toggle()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }) {
                            Label("EXECUTE", systemImage: "play.fill")
                                .font(.system(.headline, design: .monospaced))
                                .padding().frame(maxWidth: .infinity)
                                .background(concept.themeColor).foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button(action: {
                            capturePhoto = true
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        }) {
                            Image(systemName: "camera.viewfinder")
                                .font(.title).padding()
                                .background(.white).foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onChange(of: capturedImage) { newImage in
            if let img = newImage {
                progressManager.addRecord(image: img, for: concept)
            }
        }
    }
}
