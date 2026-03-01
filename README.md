# Sub-Atomica ⚛️

**Sub-Atomica** is an immersive and educational iOS application built with SwiftUI, ARKit, and RealityKit. Dive into the invisible world of quantum physics by bringing complex, theoretical concepts right into your living room through the power of Augmented Reality.

Designed as a Swift Playgrounds App (`.swiftpm`), Sub-Atomica lets you interact with quantum phenomena, run simulations, and capture your findings in an integrated Lab Notebook.

---

## 🌟 Key Features

*   **Interactive AR Simulations**: Explore real-time rendering of six fundamental quantum mechanics concepts:
    *   **Superposition**: Observe the probability cloud of a particle before interaction.
    *   **Wave-Particle Duality**: Witness the dual nature of light and matter.
    *   **Quantum Entanglement**: Understand how particles become inextricably linked across distances.
    *   **Quantum Tunneling**: See particles bypass classical energy barriers.
    *   **The Observer Effect**: Experience how the mere act of measurement collapses the wavefunction.
    *   **Zero-Point Tesseract**: Delve into higher-dimensional geometric anomalies.
*   **Integrated Lab Notebook**:
    *   Capture photos of your augmented reality experiments.
    *   Receive simulated "AI Analysis" logging the Core Coherence, Quantum Signature, and Field Stability of your interactions.
*   **Dynamic RealityKit Physics Loop**:
    *   Gestures (Tap, Panning, and Pinching) directly influence the quantum models.
    *   A physics engine and physics intensity control modulate particle speeds, tunneling frequency, and wave fluctuations.
*   **Environmental Light Estimation**: Utilizes ARKit frames and `CoreImage` to perform real-time environmental lighting evaluation. It updates physical-based materials iteratively, seamlessly blending simulations into your real-world environment.

---

## 🛠 Tech Stack & Architecture

*   **Swift 6 & iOS 16.0+**: Leveraging the latest in Apple's Swift language.
*   **SwiftUI**: Drives the user interface, including modular tabs for `HomeView` (Research), `LabNotebookView`, and `ProfileView` (Facility). 
*   **RealityKit & ARKit**: Used for `ARWorldTrackingConfiguration` with plane detection (horizontal and vertical). Core to procedural model generation and real-time physical interaction via `ARViewContainer`.
*   **CoreImage**: Analyzes incoming `CVPixelBuffer` frames (`CIAreaAverage`) to compute environmental luminance and update model emissive intensities in real time.
*   **Concurrency**: Extensive use of Swift's `async`/`await` and `@MainActor` patterns to safely manage state—especially around AI analysis generation and camera buffer processing.

---

## 🚀 Getting Started

### Prerequisites
*   An iPhone or iPad running **iOS 16.0** or later.
*   A device with an A-series (or M-series) chip capable of running ARKit.
*   Xcode 16+ or the Swift Playgrounds app installed on your iPad/Mac.

### Installation & Running

1. **Clone the repository** or download the `Sub-Atomica.swiftpm` package.
2. **Open with Xcode** (on macOS) or **Swift Playgrounds** (on iPadOS/macOS).
    *   *Xcode*: Double-click `Sub-Atomica.swiftpm`. Select your deployment target device and hit run (`Cmd + R`).
    *   *Swift Playgrounds*: Open the `.swiftpm` file and tap **Play**.
3. **Permissions**: The app requires permission to access the **Camera** (for the AR experience) and the **Photo Library** (to save Lab Notebook captures).

---

## 🎮 How to Use

1. **Research (Home View)**: Start by selecting a Quantum Concept to explore.
2. **Place the Environment**: Move your device around to scan the room. Once the AR coaching overlay detects a flat surface, tap the screen to anchor your particle/wave simulation.
3. **Interact**:
    *   **Pinch** to scale the quantum phenomena.
    *   **Pan** to move the simulation across surfaces.
    *   **Tap** to interact and execute concept-specific simulations (e.g., collapse a superposition or observe a particle).
4. **Notebook**: Take a snapshot of your simulation. Navigate to the *Notebook* tab to review your collected images along with theoretical AI analyses.

---

## 📝 License

This project is not licensed for redistribution without permission. 

*Designed and developed to make the invisible cosmos visible.* 🌌
