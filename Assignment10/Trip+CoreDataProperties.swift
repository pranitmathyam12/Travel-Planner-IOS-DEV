
import Foundation
import CoreData


extension Trip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        return NSFetchRequest<Trip>(entityName: "Trip")
    }

    @NSManaged public var id: Int32
    @NSManaged public var destinationID: Int32
    @NSManaged public var startDate: String?
    @NSManaged public var endDate: String?
    @NSManaged public var title: String?
    @NSManaged public var destination: Destination?

}

extension Trip : Identifiable {

}
