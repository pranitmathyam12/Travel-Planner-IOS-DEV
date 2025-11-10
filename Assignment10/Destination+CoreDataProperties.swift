
import Foundation
import CoreData


extension Destination {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Destination> {
        return NSFetchRequest<Destination>(entityName: "Destination")
    }

    @NSManaged public var id: Int32
    @NSManaged public var city: String?
    @NSManaged public var country: String?
    @NSManaged public var pictureURL: Data?
    @NSManaged public var trip: Trip?

}

extension Destination : Identifiable {

}
