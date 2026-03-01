import SwiftUI

@main
struct PlanckApp: App {
    @StateObject private var progressManager = UserProgressManager()
    @State private var showWelcome = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showWelcome {
                    WelcomeView(isPresented: $showWelcome)
                } else {
                    TabView {
                        HomeView()
                            .tabItem { Label("Research", systemImage: "atom") }
                        
                        LabNotebookView()
                            .tabItem { Label("Notebook", systemImage: "text.book.closed.fill") }
                        
                        ProfileView()
                            .tabItem { Label("Facility", systemImage: "building.2.fill") }
                    }
                }
            }
            .environmentObject(progressManager)
            .preferredColorScheme(.dark)
        }
    }
}
