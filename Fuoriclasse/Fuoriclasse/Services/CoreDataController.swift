import CoreData
import Foundation

/// Singleton gérant le conteneur Core Data
class CoreDataController {
    static let shared = CoreDataController()
    
    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext { persistentContainer.viewContext }
    
    private init() {
        // Nom du modèle .xcdatamodeld (ex: "FuoriclasseModel")
        persistentContainer = NSPersistentContainer(name: "Fuoriclasse")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Erreur lors du chargement du store: \(error)")
            }
        }
    }
}
