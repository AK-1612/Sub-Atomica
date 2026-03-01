import Foundation
import SwiftUI
import UIKit

enum QuantumConcept: String, CaseIterable, Identifiable, Codable {
    case superposition, waveParticle, entanglement, tunneling, observer, tesseract
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .superposition: return "Superposition"
        case .waveParticle: return "Wave-Particle Duality"
        case .entanglement: return "Quantum Entanglement"
        case .tunneling: return "Quantum Tunneling"
        case .observer: return "The Observer Effect"
        case .tesseract: return "Zero-Point Tesseract"
        }
    }
    
    var tagline: String {
        switch self {
        case .superposition: return "Multi-state existence."
        case .waveParticle: return "Duality of matter."
        case .entanglement: return "Instantaneous correlation."
        case .tunneling: return "Bypassing barriers."
        case .observer: return "Measurement collapses reality."
        case .tesseract: return "Higher-dimensional anomalies."
        }
    }
    
    var themeColor: Color {
        switch self {
        case .superposition: return .cyan
        case .waveParticle: return .teal
        case .entanglement: return .white
        case .tunneling: return .orange
        case .observer: return .blue
        case .tesseract: return Color(red: 0.7, green: 1.0, blue: 0.9)
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .superposition: return .systemCyan
        case .waveParticle: return .systemTeal
        case .entanglement: return .white
        case .tunneling: return .systemOrange
        case .observer: return .systemBlue
        case .tesseract: return UIColor(red: 0.7, green: 1.0, blue: 0.9, alpha: 1.0)
        }
    }
    
    var description: String {
        switch self {
        case .superposition: return "A particle exists as a probability cloud of all possible states at once. It remains in flux until an interaction occurs."
        case .waveParticle: return "Quantum entities exhibit properties of both waves and particles depending on the method of measurement."
        case .entanglement: return "Particles become linked such that the state of one instantaneously influences the other, regardless of distance."
        case .tunneling: return "A phenomenon where particles pass through energy barriers that should be impassable according to classical physics."
        case .observer: return "The act of measurement collapses the quantum wavefunction, forcing a particle to choose a single definite state."
        case .tesseract: return "A four-dimensional geometric anomaly representing zero-point energy fluctuations in a stabilized vacuum."
        }
    }
}

struct LabRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let concept: QuantumConcept
    let timestamp: Date
    let imageData: Data
    var aiAnalysis: String
    var isStarred: Bool = false
    
    var uiImage: UIImage? { UIImage(data: imageData) }
}

@MainActor
class UserProgressManager: ObservableObject {
    @Published var records: [LabRecord] = []
    @Published var completedConcepts: Set<QuantumConcept> = []
    @Published var totalSimulationsRun: Int = 0
    
    func addRecord(image: UIImage, for concept: QuantumConcept) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let newRecord = LabRecord(id: UUID(), concept: concept, timestamp: Date(), imageData: data, aiAnalysis: "INITIALIZING QUANTUM SCAN...")
        
        records.insert(newRecord, at: 0)
        totalSimulationsRun += 1
        completedConcepts.insert(concept)
        
        Task {
            let analysis = await performAIAnalysis(for: concept)
            if let index = records.firstIndex(where: { $0.id == newRecord.id }) {
                records[index].aiAnalysis = analysis
            }
        }
    }
    
    private func performAIAnalysis(for concept: QuantumConcept) async -> String {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        return """
        QUANTUM SIGNATURE: VERIFIED
        COHERENCE: \(Int.random(in: 92...99))%
        FIELD STABILITY: NOMINAL
        
        Observation confirms \(concept.title) characteristics. Particle distribution matches theoretical models with zero detectable decoherence.
        """
    }
    
    func deleteRecord(at indexSet: IndexSet) {
        records.remove(atOffsets: indexSet)
    }
}
