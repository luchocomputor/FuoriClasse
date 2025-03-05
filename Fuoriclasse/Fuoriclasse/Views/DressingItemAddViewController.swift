import UIKit
import CoreData

class DressingItemAddViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!

    @IBAction func saveButtonTapped(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty,
              let category = categoryTextField.text, !category.isEmpty else {
            return
        }
        let photoData = itemImageView.image?.jpegData(compressionQuality: 0.8)

        // Récupérer le contexte via le singleton
        let context = CoreDataController.shared.context

        // Créer l’objet Core Data
        let newItem = DressingItem(context: context)
        newItem.id = UUID()
        newItem.title = name
        newItem.category = category
        newItem.size = "M"  // Valeur par défaut ou à compléter
        newItem.color = ""
        newItem.image = photoData
        newItem.dotClass = DotClass.green.rawValue
        newItem.additionalInfo = ""

        // Persister l’objet via le service Persistence
        Persistence.shared.addItem(newItem)

        // Fermer la vue
        navigationController?.popViewController(animated: true)
    }
}
