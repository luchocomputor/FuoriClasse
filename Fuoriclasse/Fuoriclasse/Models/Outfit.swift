import Foundation
import CoreData

@objc(Outfit)
public class Outfit: NSManagedObject {}

extension Outfit {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Outfit> {
        NSFetchRequest<Outfit>(entityName: "Outfit")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var season: String?
    @NSManaged public var style: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var items: NSSet?

    var itemsArray: [DressingItem] {
        (items as? Set<DressingItem> ?? []).sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
}
