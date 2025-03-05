import SwiftUI
import SceneKit

struct Avatar3DView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()

        // Charger le modèle MyAvatar.usdz
        if let avatarNode = load3DModel() {
            scene.rootNode.addChildNode(avatarNode)
        }

        // Configuration de la SCNView
        scnView.scene = scene
        scnView.allowsCameraControl = true  // Permet de zoomer et tourner autour du modèle
        scnView.autoenablesDefaultLighting = true // Lumière par défaut

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        print("🔄 Mise à jour de SCNView")

        // Suppression des anciens nodes
        uiView.scene?.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        if let avatarNode = load3DModel() {
            uiView.scene?.rootNode.addChildNode(avatarNode)
        }
    }

    private func load3DModel() -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "MyAvatar", withExtension: "usdz") else {
            print("❌ Impossible de trouver le modèle 3D local")
            return nil
        }

        let scene = try? SCNScene(url: url, options: nil)
        return scene?.rootNode
    }
}
