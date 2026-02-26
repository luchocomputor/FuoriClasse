import SwiftUI
import SceneKit
import ModelIO
import SceneKit.ModelIO

/// Viewer SceneKit pour fichiers .glb — drag to rotate, pinch to zoom
struct Model3DView: UIViewRepresentable {
    let fileURL: URL

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)
        scnView.backgroundColor       = .clear
        scnView.allowsCameraControl   = true
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode      = .multisampling4X
        scnView.preferredFramesPerSecond = 60

        let scene = buildScene()
        scnView.scene = scene
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    // MARK: - Construction de la scène

    private func buildScene() -> SCNScene {
        // Chargement via ModelIO (supporte .glb / .obj / .dae)
        let asset = MDLAsset(url: fileURL)
        asset.loadTextures()
        let scene = SCNScene(mdlAsset: asset)

        centerModel(in: scene)
        addLighting(to: scene)
        addCamera(to: scene)

        return scene
    }

    private func centerModel(in scene: SCNScene) {
        let root = scene.rootNode
        let (minV, maxV) = root.boundingBox
        let isEmpty = minV.x == maxV.x && minV.y == maxV.y && minV.z == maxV.z
        guard !isEmpty else { return }

        let cx = (minV.x + maxV.x) / 2
        let cy = (minV.y + maxV.y) / 2
        let cz = (minV.z + maxV.z) / 2

        for child in root.childNodes {
            child.position = SCNVector3(
                child.position.x - cx,
                child.position.y - cy,
                child.position.z - cz
            )
        }
    }

    private func addCamera(to scene: SCNScene) {
        let (minV, maxV) = scene.rootNode.boundingBox
        let size = max(maxV.x - minV.x, max(maxV.y - minV.y, maxV.z - minV.z))
        let dist = max(Float(size) * 2.5, 1.0)

        let cam     = SCNCamera()
        cam.zNear   = 0.01
        cam.zFar    = Double(dist) * 20
        cam.fieldOfView = 45

        let camNode = SCNNode()
        camNode.camera   = cam
        camNode.position = SCNVector3(0, Float(size) * 0.15, dist)
        scene.rootNode.addChildNode(camNode)
    }

    private func addLighting(to scene: SCNScene) {
        // Lumière ambiante douce
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type      = .ambient
        ambientNode.light?.intensity = 300
        ambientNode.light?.color     = UIColor(white: 1.0, alpha: 1.0)
        scene.rootNode.addChildNode(ambientNode)

        // Lumière principale (avant-haut-gauche)
        addDirectional(to: scene, position: SCNVector3(-2, 3, 3), intensity: 800)

        // Lumière de remplissage (arrière-droite)
        addDirectional(to: scene, position: SCNVector3(3, 1, -2), intensity: 350)

        // Lumière de sol (bas)
        addDirectional(to: scene, position: SCNVector3(0, -3, 1), intensity: 150)
    }

    private func addDirectional(to scene: SCNScene, position: SCNVector3, intensity: CGFloat) {
        let node      = SCNNode()
        node.light    = SCNLight()
        node.light?.type      = .directional
        node.light?.intensity = intensity
        node.light?.color     = UIColor(white: 1.0, alpha: 1.0)
        node.position = position

        let constraint = SCNLookAtConstraint(target: scene.rootNode)
        constraint.isGimbalLockEnabled = true
        node.constraints = [constraint]

        scene.rootNode.addChildNode(node)
    }
}
