import SwiftUI
import SceneKit

struct Avatar3DView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()

        // Charger le modèle MyAvatar.usdz
        if let avatarNode = load3DModel() {
            avatarNode.scale = SCNVector3(0.8, 0.8, 0.8) // Ajuste la taille
            avatarNode.position = SCNVector3(0, 0.5, 0) // 🔥 Remonte l'avatar
            scene.rootNode.addChildNode(avatarNode)
        }

        // Configuration de la SCNView
        scnView.scene = scene
        scnView.allowsCameraControl = true  // Permet les déplacements
        scnView.autoenablesDefaultLighting = true // Lumière par défaut
        scnView.backgroundColor = UIColor.clear // Supprime le fond blanc

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        print("🔄 Mise à jour de SCNView")

        // Suppression des anciens nodes
        uiView.scene?.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        if let avatarNode = load3DModel() {
            avatarNode.scale = SCNVector3(0.8, 0.8, 0.8) // Ajuste la taille
            avatarNode.position = SCNVector3(0, -0.5, 0) // 🔥 Assure que l'avatar est bien remonté
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
