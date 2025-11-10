import SwiftUI

struct AddEditTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        entity: Destination.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Destination.city, ascending: true)]
    ) private var destinations: FetchedResults<Destination>

    @State var trip: Trip?
    @State private var title = ""
    @State private var destinationID: Int32?
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var showAlert = false
    
    var onSave: (() -> Void)?

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                Picker("Destination", selection: $destinationID) {
                    ForEach(destinations) { destination in
                        Text(destination.city ?? "Unknown").tag(Optional(destination.id))
                    }
                }
                .pickerStyle(MenuPickerStyle())

                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            .navigationTitle(trip == nil ? "Add Trip" : "Edit Trip")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if title.isEmpty || destinationID == nil || startDate > endDate {
                            showAlert = true
                        } else {
                            saveTrip()
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Missing Fields or Invalid Dates"),
                    message: Text("Please correct all fields"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                loadTripData()
            }
        }
    }

    private func saveTrip() {
        if trip == nil {
            trip = Trip(context: context)
            trip?.id = Int32(Int.random(in: 100...10000))
        }
        trip?.title = title
        trip?.startDate = formatDate(date: startDate)
        trip?.endDate = formatDate(date: endDate)
        trip?.destinationID = destinationID ?? 0

        CoreDataManager.shared.saveContext()
        onSave?()
        presentationMode.wrappedValue.dismiss()
    }

    private func loadTripData() {
        if let trip = trip {
            title = trip.title ?? ""
            destinationID = trip.destinationID
            startDate = parseDate(dateString: trip.startDate ?? "") ?? Date()
            endDate = parseDate(dateString: trip.endDate ?? "") ?? Date()
        }
    }

    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func parseDate(dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}
