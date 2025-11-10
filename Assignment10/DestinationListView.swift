
import SwiftUI

struct DestinationListView: View {
    @FetchRequest(
        entity: Destination.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Destination.city, ascending: true)]
    ) private var destinations: FetchedResults<Destination>

    @State private var searchText = ""
    @State private var editingDestination: Destination?
    @State private var showAddSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var filteredDestinations: [Destination] {
        if searchText.isEmpty {
            return Array(destinations)
        } else {
            return destinations.filter { ($0.city ?? "").localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            List {
                if filteredDestinations.isEmpty {
                    Text("No destinations found")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(filteredDestinations, id: \.self) { destination in
                        HStack(spacing: 12) {
                            DestinationImageView(destination: destination)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading) {
                                Text(destination.city ?? "Unknown City")
                                    .font(.headline)
                                Text(destination.country ?? "Unknown Country")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 5)
                        .onTapGesture {
                            editingDestination = destination
                        }
                    }
                    .onDelete(perform: deleteDestination)
                }
            }
            .navigationTitle("Destinations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingDestination) { destination in
                AddEditDestinationView(destination: destination) {
                    // No need to reload manually due to @FetchRequest
                }
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
            }
            .sheet(isPresented: $showAddSheet) {
                AddEditDestinationView(destination: nil) {
                    // No manual reload required
                }
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
            }
            .searchable(text: $searchText)
            .onAppear {
                CoreDataManager.shared.preloadIfNeeded()
            }
            .alert("Cannot Delete Destination", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func deleteDestination(at offsets: IndexSet) {
        for index in offsets {
            let destination = filteredDestinations[index]
            let trips = CoreDataManager.shared.fetchTrips()
            let linkedTrips = trips.filter { $0.destinationID == destination.id }

            if linkedTrips.isEmpty {
                CoreDataManager.shared.deleteDestination(destination: destination)
            } else {
                alertMessage = "Cannot delete this destination because it is linked to existing trips."
                showAlert = true
            }
        }
    }
}

struct DestinationImageView: View {
    @ObservedObject var destination: Destination  // Make sure Destination conforms to ObservableObject

    var body: some View {
        if let imageData = destination.pictureURL, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .foregroundColor(.gray)
        }
    }
}

