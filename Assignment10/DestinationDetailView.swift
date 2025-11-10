
import SwiftUI

struct DestinationDetailView: View {
    let destination: Destination

    var body: some View {
        VStack {
            Text("City: " + destination.city!)
                .font(.largeTitle)
                .padding()
            Text("Country: " + destination.country!)
                .font(.title2)
                .foregroundColor(.gray)
            Spacer()
        }
        .navigationTitle("Details")
    }
}
