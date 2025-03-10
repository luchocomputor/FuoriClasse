import UIKit

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

        let newItemDTO = DressingItemDTO(
            id: UUID(),
            title: name,
            category: category,
            size: "M", // Tu peux changer ça dynamiquement selon tes besoins
            color: "",
            brand: "",
            image: photoData,
            dotClass: DotClass.green.rawValue,
            additionalInfo: ""
        )

        Persistence.shared.addItem(newItemDTO)

        navigationController?.popViewController(animated: true)
    }
}
