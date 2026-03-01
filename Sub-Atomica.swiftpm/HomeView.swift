import SwiftUI

struct HomeView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.05).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        headerSection
                        
                        VStack(spacing: 16) {
                            ForEach(QuantumConcept.allCases) { concept in
                                NavigationLink(destination: LessonDetailView(concept: concept)) {
                                    ConceptRow(concept: concept, isCompleted: progressManager.completedConcepts.contains(concept))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RESEARCH FACILITY")
                .font(.system(.caption, design: .monospaced)).foregroundStyle(.cyan).tracking(4)
            Text("Sub-Atomica")
                .font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            
            HStack {
                Text("\(progressManager.completedConcepts.count) / 6 Modules Logged")
                Spacer()
                Text("\(progressManager.totalSimulationsRun) Sims")
            }
            .font(.system(.caption, design: .monospaced)).foregroundStyle(.gray)
            .padding(.top, 10)
        }
        .padding(24)
    }
}

struct ConceptRow: View {
    let concept: QuantumConcept
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            Circle()
                .fill(concept.themeColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: isCompleted ? "checkmark" : "atom").foregroundStyle(concept.themeColor))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(concept.title.uppercased())
                    .font(.system(.subheadline, design: .monospaced)).bold()
                Text(concept.tagline)
                    .font(.caption).foregroundStyle(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.white.opacity(0.3))
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(isCompleted ? concept.themeColor.opacity(0.3) : .clear, lineWidth: 1))
    }
}
