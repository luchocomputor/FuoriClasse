import Foundation
import CoreData
import SwiftUI

// MARK: - Enum DotClass
/// Trois statuts avec un rond coloré, adapté à iOS / Mac Catalyst
enum DotClass: String, CaseIterable {
    case green  = "Rond Vert"
    case orange = "Rond Orange"
    case red    = "Rond Rouge"
    
    /// Couleur SwiftUI associée
    var color: Color {
        switch self {
        case .green:
            return Color(.systemGreen)
        case .orange:
            return Color(.systemOrange)
        case .red:
            return Color(.systemRed)
        }
    }
}

// MARK: - NSManagedObject pour Core Data
@objc(DressingItem)
public class DressingItem: NSManagedObject {
    // Fonctions custom éventuelles
}

// MARK: - Extension Core Data
extension DressingItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DressingItem> {
        NSFetchRequest<DressingItem>(entityName: "DressingItem")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var category: String
    @NSManaged public var size: String
    @NSManaged public var color: String
    @NSManaged public var brand: String
    @NSManaged public var image: Data?
    @NSManaged public var dotClass: String
    @NSManaged public var additionalInfo: String
    // Nouveaux attributs (optional car ajoutés par migration)
    @NSManaged public var material: String?
    @NSManaged public var season: String?
    @NSManaged public var fit: String?
    @NSManaged public var style: String?
    @NSManaged public var price: String?
    
    // Computed property pour manipuler l’énum DotClass
    var dotClassEnum: DotClass {
        get { DotClass(rawValue: dotClass) ?? .green }
        set { dotClass = newValue.rawValue }
    }
}


