
import SwiftUI

struct TripListView: View {
    @FetchRequest(
        entity: Trip.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Trip.startDate, ascending: true)]
    ) private var trips: FetchedResults<Trip>

    @State private var searchText = ""
    @State private var editingTrip: Trip?   // ✅ For editing
    @State private var showAddSheet = false // ✅ For adding
    @State private var showAlert = false
    @State private var alertMessage = ""

    var filteredTrips: [Trip] {
        if searchText.isEmpty {
            return Array(trips)
        } else {
            return trips.filter { ($0.title ?? "").localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            List {
                if filteredTrips.isEmpty {
                    Text("No trips found")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(filteredTrips, id: \.self) { trip in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(trip.title ?? "Unknown Trip")
                                    .font(.headline)
                                Text("\(trip.startDate ?? "") → \(trip.endDate ?? "")")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: iconName(for: trip))
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 5)
                        .onTapGesture {
                            editingTrip = trip
                        }
                    }
                    .onDelete(perform: deleteTrip)
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingTrip) { trip in
                AddEditTripView(trip: trip) {
                    // Nothing manual needed
                }
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
            }
            .sheet(isPresented: $showAddSheet) {
                AddEditTripView(trip: nil) {
                    // Nothing manual needed
                }
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
            }
            .searchable(text: $searchText)
            .onAppear {
                CoreDataManager.shared.preloadIfNeeded()
            }
            .alert("Cannot Delete", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func deleteTrip(at offsets: IndexSet) {
        for index in offsets {
            let trip = filteredTrips[index]
            CoreDataManager.shared.deleteTrip(trip: trip)
        }
    }

    private func iconName(for trip: Trip) -> String {
        guard let startString = trip.startDate, let endString = trip.endDate else {
            return "calendar"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let start = formatter.date(from: startString),
              let end = formatter.date(from: endString) else {
            return "calendar"
        }

        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0

        if days <= 2 {
            return "calendar"
        } else if days <= 6 {
            return "calendar.badge.clock"
        } else {
            return "calendar.badge.exclamationmark"
        }
    }
}
