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
    @NSManaged public var sourceURL: String?
    // Journal de port
    @NSManaged public var wearCount: Int32
    @NSManaged public var lastWorn: Date?
    @NSManaged public var outfits: NSSet?

    // Computed property pour manipuler l’énum DotClass
    var dotClassEnum: DotClass {
        get { DotClass(rawValue: dotClass) ?? .green }
        set { dotClass = newValue.rawValue }
    }

    // MARK: - Helpers journal de port

    var wornToday: Bool {
        guard let last = lastWorn else { return false }
        return Calendar.current.isDateInToday(last)
    }

    var lastWornText: String {
        guard let date = lastWorn else { return "Jamais" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        switch days {
        case 0:  return "Aujourd’hui"
        case 1:  return "Hier"
        default: return "Il y a \(days)j"
        }
    }

    var costPerWear: String? {
        guard wearCount > 0,
              let priceStr = price,
              let p = Double(priceStr.replacingOccurrences(of: ",", with: "."))
        else { return nil }
        return String(format: "%.2f €", p / Double(wearCount))
    }
}


