import SwiftUI
import UIKit
import SceneKit

/// Visionneuse SceneKit pour l'avatar (USDZ / GLB) — drag to rotate, pinch to zoom.
/// Utilise SCNScene(url:options:) : loader natif SceneKit, supporte GLTF/GLB/USDZ
/// sans passer par ModelIO (évite les problèmes de Draco, coordonnées, etc.)
struct Avatar3DView: UIViewRepresentable {
    @ObservedObject var avatarManager: AvatarManager

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)
        scnView.backgroundColor             = .clear
        scnView.allowsCameraControl         = true
        scnView.autoenablesDefaultLighting  = true   // plus fiable que lumières manuelles
        scnView.antialiasingMode            = .multisampling4X
        scnView.preferredFramesPerSecond    = 60

        if let url = avatarManager.avatarURL {
            scnView.scene = buildScene(from: url)
        }
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let url = avatarManager.avatarURL else { return }
        // Reconstruit seulement si l'URL a changé ou si la scène est vide
        if uiView.scene == nil || uiView.scene?.rootNode.childNodes.isEmpty == true {
            uiView.scene = buildScene(from: url)
        }
    }

    // MARK: - Construction scène

    private func buildScene(from url: URL) -> SCNScene {
        // SCNScene(url:) est le loader GLTF natif de SceneKit :
        // supporte .glb / .gltf / .usdz / .dae sans passer par MDLAsset.
        // .convertToYUp corrige les modèles Z-up (Blender, etc.)
        let options: [SCNSceneSource.LoadingOption: Any] = [
            .convertToYUp: true
        ]
        let scene = (try? SCNScene(url: url, options: options)) ?? SCNScene()

        addCamera(to: scene)
        return scene
    }

    // MARK: - Caméra adaptative

    private func addCamera(to scene: SCNScene) {
        let root = scene.rootNode

        // Bounding box globale (enfants inclus via presentationNode si nécessaire)
        var (minV, maxV) = root.boundingBox

        // Si la rootNode n'a pas de bounds propres, agrège les enfants
        if minV == maxV {
            var lo = SCNVector3( Float.infinity,  Float.infinity,  Float.infinity)
            var hi = SCNVector3(-Float.infinity, -Float.infinity, -Float.infinity)
            root.childNodes.forEach { child in
                let (cMin, cMax) = child.boundingBox
                lo.x = min(lo.x, cMin.x); lo.y = min(lo.y, cMin.y); lo.z = min(lo.z, cMin.z)
                hi.x = max(hi.x, cMax.x); hi.y = max(hi.y, cMax.y); hi.z = max(hi.z, cMax.z)
            }
            if lo.x != Float.infinity { minV = lo; maxV = hi }
        }

        let sizeX = maxV.x - minV.x
        let sizeY = maxV.y - minV.y
        let sizeZ = maxV.z - minV.z
        let maxSize = max(sizeX, max(sizeY, sizeZ))
        let dist    = maxSize > 0 ? max(Float(maxSize) * 2.2, 0.5) : 2.5
        let centerY = maxSize > 0 ? (minV.y + maxV.y) / 2 : 0.7

        let cam         = SCNCamera()
        cam.zNear       = 0.001
        cam.zFar        = Double(dist) * 20
        cam.fieldOfView = 42

        let camNode      = SCNNode()
        camNode.camera   = cam
        camNode.position = SCNVector3(0, centerY, dist)

        // Point de regard : légèrement en dessous du centre (tête/buste)
        let lookTarget   = SCNNode()
        lookTarget.position = SCNVector3(0, centerY * 0.85, 0)
        root.addChildNode(lookTarget)

        let constraint = SCNLookAtConstraint(target: lookTarget)
        constraint.isGimbalLockEnabled = true
        camNode.constraints = [constraint]

        root.addChildNode(camNode)
    }
}

// MARK: - SCNVector3 Equatable helper
private func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
    lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}
