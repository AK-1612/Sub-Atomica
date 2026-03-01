import SwiftUI

struct LabNotebookView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var selectedRecord: LabRecord?
    
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            if #available(iOS 17.0, *) {
                ZStack {
                    Color(white: 0.05).ignoresSafeArea()
                    
                    if progressManager.records.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(progressManager.records) { record in
                                    NotebookCard(record: record)
                                        .onTapGesture {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            selectedRecord = record
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Research Logs")
                .navigationDestination(item: $selectedRecord) { record in
                    LabDetailView(record: record)
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 50)).foregroundStyle(.gray)
            Text("No Logs Recorded").font(.headline).foregroundStyle(.white)
            Text("Complete simulations in the Research wing to populate your notebook.").font(.subheadline).foregroundStyle(.gray).multilineTextAlignment(.center)
        }.padding(40)
    }
}

struct NotebookCard: View {
    let record: LabRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let img = record.uiImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.concept.title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(record.concept.themeColor)
                Text(record.timestamp.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .padding(10)
        }
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
    }
}

struct LabDetailView: View {
    let record: LabRecord
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let img = record.uiImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("LABORATORY ANALYSIS")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(record.concept.themeColor)
                    
                    Text(record.aiAnalysis)
                        .font(.system(.body, design: .monospaced))
                        .lineSpacing(6)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("TIMESTAMP").font(.caption2).foregroundStyle(.gray)
                            Text(record.timestamp.formatted())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("FIELD TYPE").font(.caption2).foregroundStyle(.gray)
                            Text("Quantum AR Scan")
                        }
                    }
                    .font(.system(.subheadline, design: .monospaced))
                    .padding(.top, 10)
                }
            }
            .padding()
        }
        .background(Color(white: 0.05).ignoresSafeArea())
        .navigationTitle(record.concept.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(item: Image(uiImage: record.uiImage ?? UIImage()), preview: SharePreview("Quantum Log", image: Image(uiImage: record.uiImage ?? UIImage()))) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}
