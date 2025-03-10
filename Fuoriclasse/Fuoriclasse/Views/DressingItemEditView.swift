import SwiftUI

struct DressingItemEditView: View {
    @Binding var isPresented: Bool
    var dto: DressingItemDTO

    @State private var title: String
    @State private var category: String
    @State private var size: String
    @State private var color: String
    @State private var brand: String
    @State private var additionalInfo: String
    @State private var dotClass: String
    @State private var imageData: Data?

    init(isPresented: Binding<Bool>, dto: DressingItemDTO) {
        self._isPresented = isPresented
        self._title = State(initialValue: dto.title)
        self._category = State(initialValue: dto.category)
        self._size = State(initialValue: dto.size)
        self._color = State(initialValue: dto.color)
        self._brand = State(initialValue: dto.brand)
        self._additionalInfo = State(initialValue: dto.additionalInfo)
        self._dotClass = State(initialValue: dto.dotClass)
        self._imageData = State(initialValue: dto.image)
        self.dto = dto
    }

    var body: some View {
        VStack {
            TextField("Titre", text: $title)
                .padding()

            // Ajoute tes autres champs ici (Picker, PhotoPicker...)

            Button("Enregistrer") {
                saveChanges()
            }
        }
        .padding()
    }

    private func saveChanges() {
        let updatedDTO = DressingItemDTO(
            id: dto.id,
            title: title,
            category: category,
            size: size,
            color: color,
            brand: brand,
            image: imageData,
            dotClass: dotClass,
            additionalInfo: additionalInfo
        )

        Persistence.shared.updateItem(updatedItem: updatedDTO) // FIXED
        isPresented = false
    }
}
