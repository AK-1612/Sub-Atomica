import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Professional Dark Lab Background
                Color(white: 0.05).ignoresSafeArea()
                
                List {
                    // MARK: - Facility Identity
                    Section {
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.cyan.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "person.badge.shield.checkfill")
                                    .font(.system(size: 35))
                                    .foregroundStyle(.cyan)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lead Researcher")
                                    .font(.system(.title3, design: .monospaced))
                                    .bold()
                                    .foregroundStyle(.white)
                                
                                Text("Sub-Atomica Facility")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundStyle(.gray)
                                
                                Text("Clearance: Level 5")
                                    .font(.system(size: 10, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.cyan.opacity(0.2))
                                    .foregroundStyle(.cyan)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 10)
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    
                    // MARK: - Research Statistics
                    Section(header: Text("Laboratory Metrics").font(.system(.caption, design: .monospaced))) {
                        StatRow(title: "Simulations Run", value: "\(progressManager.totalSimulationsRun)", icon: "atom", color: .cyan)
                        StatRow(title: "Photographic Logs", value: "\(progressManager.records.count)", icon: "camera.viewfinder", color: .teal)
                        StatRow(title: "Modules Completed", value: "\(progressManager.completedConcepts.count) / 6", icon: "checkmark.seal", color: .white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    // MARK: - Facility Settings
                    Section(header: Text("Data Management").font(.system(.caption, design: .monospaced))) {
                        Button(role: .destructive) {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            showResetAlert = true
                        } label: {
                            Label("Decommission Lab Data", systemImage: "exclamationmark.shield")
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    // MARK: - App Info
                    Section {
                        HStack {
                            Text("Build Version")
                            Spacer()
                            Text("2.0.4-Stable")
                                .foregroundStyle(.gray)
                        }
                        .font(.system(.caption, design: .monospaced))
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Facility")
            .alert("Wipe Research Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Erase All", role: .destructive) {
                    progressManager.records.removeAll()
                    progressManager.completedConcepts.removeAll()
                    progressManager.totalSimulationsRun = 0
                }
            } message: {
                Text("This action will permanently purge all photographic logs and reset your progress in the Sub-Atomica facility. This cannot be undone.")
            }
        }
    }
}

// MARK: - Supporting Components
struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(.system(.body, design: .monospaced))
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .bold()
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProgressManager())
        .preferredColorScheme(.dark)
}
