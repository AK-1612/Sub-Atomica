import SwiftUI
import RealityKit
import ARKit
import Combine
import CoreImage

final class SendablePixelBuffer: @unchecked Sendable {
    let buffer: CVPixelBuffer
    init(_ buffer: CVPixelBuffer) { self.buffer = buffer }
}

actor LightEstimator {
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var lastProcessTime: TimeInterval = 0
    
    func process(boxedBuffer: SendablePixelBuffer) -> Float? {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessTime > 0.1 else { return nil }
        lastProcessTime = currentTime
        
        let inputImage = CIImage(cvPixelBuffer: boxedBuffer.buffer)
        let extent = inputImage.extent
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: inputImage,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ]), let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        let lum = (CGFloat(bitmap[0]) * 0.2126 + CGFloat(bitmap[1]) * 0.7152 + CGFloat(bitmap[2]) * 0.0722) / 255.0
        return Float(max(0.15, 1.0 - lum))
    }
}

@MainActor
struct ARViewContainer: UIViewRepresentable {
    let concept: QuantumConcept
    @Binding var executeSimulation: Bool
    @Binding var resetSimulation: Bool
    @Binding var capturePhoto: Bool
    @Binding var isModelPlaced: Bool
    @Binding var physicsIntensity: Float
    @Binding var capturedImage: UIImage?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        arView.environment.sceneUnderstanding.options = [.occlusion]
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .none
        
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .anyPlane
        coaching.activatesAutomatically = true
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coaching)
        
        arView.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap)))
        arView.addGestureRecognizer(UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch)))
        arView.addGestureRecognizer(UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan)))
        
        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if executeSimulation {
            context.coordinator.triggerInteraction()
            Task { @MainActor in executeSimulation = false }
        }
        if resetSimulation {
            context.coordinator.buildSpecificModel()
            Task { @MainActor in resetSimulation = false }
        }
        if capturePhoto {
            context.coordinator.takeSnapshot()
            Task { @MainActor in capturePhoto = false }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        weak var arView: ARView?
        var rootAnchor: AnchorEntity?
        var modelBase = Entity()
        var subscription: Cancellable?
        
        var isSimulating = false
        var timeElapsed: Float = 0
        var initialScale: SIMD3<Float> = [1, 1, 1]
        var isDragging = false
        
        var currentTargetBrightness: Float = 0.5
        let lightEstimator = LightEstimator()

        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
        }
        
        nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let rawBuffer = frame.capturedImage
            let boxedBuffer = SendablePixelBuffer(rawBuffer)
            
            Task {
                if let targetBrightness = await lightEstimator.process(boxedBuffer: boxedBuffer) {
                    await MainActor.run {
                        self.applyBrightnessUpdate(targetBrightness)
                    }
                }
            }
        }
        
        func applyBrightnessUpdate(_ targetBrightness: Float) {
            currentTargetBrightness = (currentTargetBrightness * 0.8) + (targetBrightness * 0.2)
            if parent.isModelPlaced {
                applyBrightnessToModel(brightness: currentTargetBrightness)
            }
        }
        
        func applyBrightnessToModel(brightness: Float) {
            updateMaterialsRecursively(entity: modelBase, brightness: brightness)
        }

        func updateMaterialsRecursively(entity: Entity, brightness: Float) {
            if entity.name == "collision_box" || !entity.isEnabled { return }

            if let modelEntity = entity as? ModelEntity {
                var newMaterials: [RealityKit.Material] = []
                for mat in modelEntity.model?.materials ?? [] {
                    if var pbr = mat as? PhysicallyBasedMaterial {
                        pbr.emissiveIntensity = brightness * 3.0
                        newMaterials.append(pbr)
                    } else {
                        newMaterials.append(mat)
                    }
                }
                modelEntity.model?.materials = newMaterials
            }

            for child in entity.children {
                updateMaterialsRecursively(entity: child, brightness: brightness)
            }
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = sender.location(in: arView)
            
            if rootAnchor != nil, let _ = arView.entity(at: location) {
                triggerInteraction()
                return
            }
            
            if rootAnchor == nil {
                let transform = getTransform(at: location, in: arView)
                let anchor = AnchorEntity(world: transform)
                
                let padMesh = MeshResource.generateBox(size: [0.4, 0.002, 0.4], cornerRadius: 0.2)
                var padMat = PhysicallyBasedMaterial()
                padMat.baseColor = .init(tint: parent.concept.uiColor.withAlphaComponent(0.2))
                padMat.blending = .transparent(opacity: 0.2)
                let pad = ModelEntity(mesh: padMesh, materials: [padMat])
                anchor.addChild(pad)
                
                let collisionBox = ShapeResource.generateBox(size: [0.5, 0.5, 0.5])
                let collisionEntity = Entity()
                collisionEntity.name = "collision_box"
                collisionEntity.components.set(CollisionComponent(shapes: [collisionBox]))
                modelBase.addChild(collisionEntity)
                
                anchor.addChild(modelBase)
                arView.scene.addAnchor(anchor)
                self.rootAnchor = anchor
                
                self.parent.isModelPlaced = true
                buildSpecificModel()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
        
        @objc func handlePan(_ sender: UIPanGestureRecognizer) {
            guard let arView = arView, let anchor = rootAnchor else { return }
            let location = sender.location(in: arView)
            
            if sender.state == .began && arView.entity(at: location) != nil {
                isDragging = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else if sender.state == .changed && isDragging {
                anchor.transform.matrix = getTransform(at: location, in: arView)
            } else if sender.state == .ended || sender.state == .cancelled {
                isDragging = false
            }
        }
        
        @objc func handlePinch(_ sender: UIPinchGestureRecognizer) {
            guard rootAnchor != nil else { return }
            if sender.state == .began {
                initialScale = modelBase.scale
            } else if sender.state == .changed || sender.state == .ended {
                let s = max(min(initialScale.x * Float(sender.scale), 4.0), 0.2)
                modelBase.scale = [s, s, s]
            }
        }
        
        private func getTransform(at location: CGPoint, in arView: ARView) -> simd_float4x4 {
            if let result = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any).first { return result.worldTransform }
            if let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first { return result.worldTransform }
            
            guard let camera = arView.session.currentFrame?.camera.transform else { return matrix_identity_float4x4 }
            let pos = SIMD3<Float>(camera.columns.3.x, camera.columns.3.y, camera.columns.3.z)
            let fwd = -SIMD3<Float>(camera.columns.2.x, camera.columns.2.y, camera.columns.2.z)
            let spawnPos = pos + (normalize(fwd) * 0.4)
            var transform = matrix_identity_float4x4
            transform.columns.3 = simd_float4(spawnPos, 1)
            return transform
        }
        
        func takeSnapshot() {
            arView?.snapshot(saveToHDR: false) { image in
                guard let image = image else { return }
                // Hand the image directly back to the SwiftUI binding
                self.parent.capturedImage = image
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
        
        func buildSpecificModel() {
            let oldEntities = modelBase.children.filter { $0.name != "collision_box" }
            for entity in oldEntities {
                entity.removeFromParent()
            }
            
            isSimulating = false
            let uiColor = parent.concept.uiColor
            
            switch parent.concept {
            case .superposition:
                let core = ModelEntity(mesh: .generateSphere(radius: 0.015), materials: [UnlitMaterial(color: uiColor)])
                modelBase.addChild(core)
                
                var cloudMat = PhysicallyBasedMaterial()
                cloudMat.baseColor = .init(tint: uiColor.withAlphaComponent(0.3))
                cloudMat.blending = .transparent(opacity: 0.3)
                cloudMat.emissiveColor = .init(color: uiColor)
                
                for i in 0..<100 {
                    let node = ModelEntity(mesh: .generateSphere(radius: 0.003), materials: [cloudMat])
                    node.name = "prob_\(i)"
                    let radius = Float.random(in: 0.02...0.12)
                    let theta = Float.random(in: 0...(2 * .pi))
                    let phi = acos(Float.random(in: -1...1))
                    node.position = [radius * sin(phi) * cos(theta), radius * sin(phi) * sin(theta), radius * cos(phi)]
                    modelBase.addChild(node)
                }
                
                let collapsed = ModelEntity(mesh: .generateSphere(radius: 0.01), materials: [UnlitMaterial(color: uiColor)])
                collapsed.name = "collapsed_particle"
                collapsed.isEnabled = false
                modelBase.addChild(collapsed)

            case .waveParticle:
                var waveMat = PhysicallyBasedMaterial()
                waveMat.baseColor = .init(tint: uiColor.withAlphaComponent(0.3))
                waveMat.blending = .transparent(opacity: 0.3)
                waveMat.emissiveColor = .init(color: uiColor)
                
                let wall = ModelEntity(mesh: .generateBox(size: [0.2, 0.2, 0.02]), materials: [UnlitMaterial(color: .gray.withAlphaComponent(0.5))])
                wall.position = [0, 0.1, -0.05]
                modelBase.addChild(wall)
                
                for x in -8...8 {
                    for z in 0...10 {
                        let node = ModelEntity(mesh: .generateSphere(radius: 0.004), materials: [waveMat])
                        node.name = "wave_node"
                        node.position = [Float(x) * 0.015, 0.05, Float(z) * 0.015]
                        modelBase.addChild(node)
                    }
                }

            case .entanglement:
                let e1 = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [UnlitMaterial(color: .white)])
                let e2 = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [UnlitMaterial(color: .white)])
                e1.name = "e1"; e2.name = "e2"
                modelBase.addChild(e1); modelBase.addChild(e2)

            case .tunneling:
                let barrier = ModelEntity(mesh: .generateBox(size: [0.05, 0.15, 0.15]), materials: [UnlitMaterial(color: uiColor.withAlphaComponent(0.4))])
                barrier.position = [0, 0.075, 0]
                modelBase.addChild(barrier)
                
                let particle = ModelEntity(mesh: .generateSphere(radius: 0.015), materials: [UnlitMaterial(color: .white)])
                particle.position = [-0.15, 0.075, 0]
                particle.name = "tunnel_particle"
                modelBase.addChild(particle)
                
            case .observer:
                let wave = ModelEntity(mesh: .generateBox(size: [0.15, 0.01, 0.05]), materials: [UnlitMaterial(color: uiColor.withAlphaComponent(0.5))])
                wave.position = [0, 0.1, 0]
                wave.name = "unobserved_wave"
                modelBase.addChild(wave)
                
                let particle = ModelEntity(mesh: .generateSphere(radius: 0.015), materials: [UnlitMaterial(color: uiColor)])
                particle.position = [0, 0.1, 0]
                particle.name = "observed_particle"
                particle.isEnabled = false
                modelBase.addChild(particle)
                
                let detector = ModelEntity(mesh: .generateBox(size: [0.03, 0.03, 0.03]), materials: [UnlitMaterial(color: .red)])
                detector.position = [0, 0.2, 0]
                detector.name = "detector"
                detector.isEnabled = false
                modelBase.addChild(detector)

            case .tesseract:
                var shellMat = PhysicallyBasedMaterial()
                shellMat.baseColor = .init(tint: uiColor.withAlphaComponent(0.3))
                shellMat.blending = .transparent(opacity: 0.3)
                shellMat.emissiveColor = .init(color: uiColor)

                let shell = ModelEntity(mesh: .generateBox(size: 0.15), materials: [shellMat])
                shell.name = "tesseract_shell"
                shell.position = [0, 0.15, 0]

                let core = ModelEntity(mesh: .generateBox(size: 0.05), materials: [UnlitMaterial(color: .white)])
                core.name = "tesseract_core"
                
                let halo = ModelEntity(mesh: .generateBox(size: 0.07), materials: [UnlitMaterial(color: uiColor.withAlphaComponent(0.5))])
                halo.name = "tesseract_halo"

                shell.addChild(halo); shell.addChild(core)
                modelBase.addChild(shell)
            }
            
            subscription?.cancel()
            subscription = arView?.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in self?.physicsLoop() }
        }

        func physicsLoop() {
            // Apply the physics intensity slider natively
            timeElapsed += 0.016 * parent.physicsIntensity
            
            modelBase.position.y = sin(timeElapsed) * 0.005
            modelBase.orientation *= simd_quatf(angle: 0.002, axis: [0, 1, 0])
            
            switch parent.concept {
            case .superposition:
                if !isSimulating {
                    modelBase.children.forEach {
                        if $0.name.starts(with: "prob") {
                            let speed = 1.0 + Float($0.name.hashValue % 10) * 0.1
                            $0.position += [sin(timeElapsed * speed) * 0.0005, cos(timeElapsed * speed) * 0.0005, sin(timeElapsed * speed * 0.8) * 0.0005]
                        }
                    }
                }
            case .waveParticle:
                if !isSimulating {
                    modelBase.children.forEach {
                        if $0.name == "wave_node" {
                            let yOffset = sin(timeElapsed * 5.0 - $0.position.z * 60.0) * 0.02
                            $0.position.y = 0.05 + yOffset
                        }
                    }
                } else {
                    modelBase.children.forEach {
                        if $0.name == "wave_node" {
                            $0.position.z -= (0.01 * parent.physicsIntensity)
                            if $0.position.z < -0.1 {
                                $0.position.z = 0.15
                            }
                        }
                    }
                }
            case .entanglement:
                if let e1 = modelBase.findEntity(named: "e1"), let e2 = modelBase.findEntity(named: "e2") {
                    let radius: Float = 0.1
                    let speed = isSimulating ? 10.0 : 3.0
                    e1.position = [sin(timeElapsed * Float(speed)) * radius, 0.1, cos(timeElapsed * Float(speed)) * radius]
                    e2.position = [-sin(timeElapsed * Float(speed)) * radius, 0.1, -cos(timeElapsed * Float(speed)) * radius]
                }
            case .tunneling:
                if let p = modelBase.findEntity(named: "tunnel_particle") {
                    if isSimulating {
                        p.position.x += (0.005 * parent.physicsIntensity)
                        if p.position.x > 0.15 { p.position.x = -0.15 }
                    }
                }
            case .observer:
                modelBase.findEntity(named: "unobserved_wave")?.orientation *= simd_quatf(angle: 0.05 * parent.physicsIntensity, axis: [1, 0, 0])
            case .tesseract:
                if let shell = modelBase.findEntity(named: "tesseract_shell") {
                    shell.orientation *= simd_quatf(angle: isSimulating ? 0.08 : 0.01, axis: [1, 1, 1])
                    shell.findEntity(named: "tesseract_core")?.orientation *= simd_quatf(angle: -0.05 * parent.physicsIntensity, axis: [0, 1, 0])
                    shell.findEntity(named: "tesseract_halo")?.orientation *= simd_quatf(angle: -0.05 * parent.physicsIntensity, axis: [0, 1, 0])
                }
            }
        }

        func triggerInteraction() {
            if isSimulating { return }
            isSimulating = true
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            
            switch parent.concept {
            case .superposition:
                modelBase.children.forEach { if $0.name.starts(with: "prob") { $0.isEnabled = false } }
                if let collapsed = modelBase.findEntity(named: "collapsed_particle") {
                    collapsed.isEnabled = true
                    collapsed.position = [Float.random(in: -0.05...0.05), Float.random(in: 0...0.1), Float.random(in: -0.05...0.05)]
                }
                
            case .waveParticle:
                modelBase.children.forEach {
                    if $0.name == "wave_node" {
                        $0.position.y = 0.05
                    }
                }
                
            case .entanglement:
                modelBase.findEntity(named: "e1")?.scale = [1.5, 1.5, 1.5]
                modelBase.findEntity(named: "e2")?.scale = [1.5, 1.5, 1.5]
                
            case .tunneling:
                break
                
            case .observer:
                modelBase.findEntity(named: "unobserved_wave")?.isEnabled = false
                modelBase.findEntity(named: "observed_particle")?.isEnabled = true
                modelBase.findEntity(named: "detector")?.isEnabled = true
                
            case .tesseract:
                if let core = modelBase.findEntity(named: "tesseract_core"), let shell = modelBase.findEntity(named: "tesseract_shell") {
                    core.move(to: Transform(scale: [3, 3, 3], translation: .zero), relativeTo: shell, duration: 0.4, timingFunction: .easeInOut)
                }
            }
            
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self.parent.resetSimulation = true
            }
        }
    }
}
