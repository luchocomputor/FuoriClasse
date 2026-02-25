import CoreData
import Foundation

class CoreDataController {
    static let shared = CoreDataController()

    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext { persistentContainer.viewContext }

    private init() {
        persistentContainer = NSPersistentContainer(name: "Fuoriclasse")
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Erreur Core Data: \(error)")
            }
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }

    func delete(_ item: DressingItem) {
        context.delete(item)
        save()
    }

    func delete(_ outfit: Outfit) {
        context.delete(outfit)
        save()
    }
}
