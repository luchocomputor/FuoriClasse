import SwiftUI
import SceneKit

struct Avatar3DView: UIViewRepresentable {
    @ObservedObject var avatarManager: AvatarManager  // ✅ Instance pour récupérer l'URL du modèle

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()

        if let avatarNode = load3DModel() {  // ✅ Suppression de l'argument incorrect
            scene.rootNode.addChildNode(avatarNode)
        }

        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.clear

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene?.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        if let avatarNode = load3DModel() {  // ✅ Suppression de l'argument incorrect
            uiView.scene?.rootNode.addChildNode(avatarNode)
        }
    }

    private func load3DModel() -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "lucho3", withExtension: "usdz") else {
            print("❌ Impossible de trouver le modèle 3D local")
            return nil
        }

        print("✅ Avatar trouvé : \(url)")

        guard let scene = try? SCNScene(url: url, options: nil) else {
            print("❌ Échec du chargement de la scène 3D")
            return nil
        }

        let avatarNode = scene.rootNode.clone()  // ✅ Suppression de "guard let"
        print("✅ Modèle chargé avec succès, nombre de childNodes : \(avatarNode.childNodes.count)")

        avatarNode.scale = SCNVector3(0.6, 0.6, 0.6)
        avatarNode.position = SCNVector3(0, -0.2, 0)

        return avatarNode
    }
}
