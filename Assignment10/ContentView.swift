
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DestinationListView()
                .tabItem {
                    Label("Destinations", systemImage: "mappin.and.ellipse")
                }
            TripListView()
                .tabItem {
                    Label("Trips", systemImage: "airplane")
                }
        }
    }
}

#Preview {
    ContentView()
}
