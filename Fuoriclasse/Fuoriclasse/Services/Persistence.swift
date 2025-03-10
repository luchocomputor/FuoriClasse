import Foundation
import CoreData
import SwiftUI

class Persistence {
    static let shared = Persistence()
    
    private var itemsDTO: [DressingItemDTO] = []
    
    init() {
        loadItems()
    }
    
    // Convertit un DressingItem en DTO et le stocke en JSON
    func addItem(_ dto: DressingItemDTO) {
        itemsDTO.append(dto)
        saveItems()
    }

    
    func getAllItems() -> [DressingItemDTO] {
        return itemsDTO
    }
    
    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(itemsDTO)
            let url = getDocumentsDirectory().appendingPathComponent("dressing.json")
            try data.write(to: url)
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }
    
    private func loadItems() {
        let url = getDocumentsDirectory().appendingPathComponent("dressing.json")
        guard let data = try? Data(contentsOf: url) else { return }
        do {
            let decoded = try JSONDecoder().decode([DressingItemDTO].self, from: data)
            itemsDTO = decoded
        } catch {
            print("Erreur lors du chargement : \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    func refreshItems() {
        loadItems()
    }
    func deleteItem(_ item: DressingItemDTO) {
        itemsDTO.removeAll { $0.id == item.id }
        saveItems()
    }
    func updateItem(updatedItem: DressingItemDTO) {
        if let index = itemsDTO.firstIndex(where: { $0.id == updatedItem.id }) {
            itemsDTO[index] = updatedItem
            saveItems()
        }
    }



}
