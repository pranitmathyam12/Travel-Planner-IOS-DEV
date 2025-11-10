
import Foundation

struct APITrip: Decodable {
    var id: Int
    var title: String
    var destinationID: Int
    var startDate: String
    var endDate: String

    var duration: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let start = formatter.date(from: startDate),
           let end = formatter.date(from: endDate) {
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            return days + 1
        }
        return 0
    }
}
