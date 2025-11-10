

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    let destination: Destination?

    var body: some View {
        VStack {
            Text(trip.title!)
                .font(.largeTitle)
                .padding()

            if let destination = destination {
                Text("\(destination.city ?? "city"), \(destination.country ?? "country")")
                    .font(.title2)
                    .foregroundColor(.gray)
            } else {
                Text("Destination info not available")
                    .font(.title2)
                    .foregroundColor(.gray)
            }

            Text("Duration: \(trip.startDate! + trip.endDate!) days")
                .font(.title3)

            Spacer()
        }
        .navigationTitle("Trip Details")
    }
}
