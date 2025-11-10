import Foundation
import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "Assignment10")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
    }
    
    private let baseURL = "https://67e9d41abdcaa2b7f5ba40cb.mockapi.io/"
    
    // MARK: - Preload
    func preloadIfNeeded(completion: (() -> Void)? = nil) {
        if !UserDefaults.standard.bool(forKey: "hasPreloaded") {
            syncDestinations { success, error in
                if success {
                    self.syncTrips { success, error in
                        if success {
                            UserDefaults.standard.set(true, forKey: "hasPreloaded")
                            print("✅ Data preloaded successfully!")
                        } else {
                            print("⚠️ Failed syncing trips")
                        }
                        completion?()
                    }
                } else {
                    print("⚠️ Failed syncing destinations")
                    completion?()
                }
            }
        } else {
            completion?()
        }
    }
    
    // MARK: - Network Operations
    private func fetchFromAPI<T: Decodable>(endpoint: String, completion: @escaping (Result<[T], Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode([T].self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Sync Methods
    func syncDestinations(completion: @escaping (Bool, Error?) -> Void) {
        fetchFromAPI(endpoint: "destination") { [weak self] (result: Result<[APIDestination], Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let apiDestinations):
                self.context.perform {
                    do {
                        let existingDestinations = try self.context.fetch(Destination.fetchRequest()) as! [Destination]
                        
                        for apiDest in apiDestinations {
                            if let existing = existingDestinations.first(where: { $0.id == Int32(apiDest.id) }) {
                                // Update existing
                                existing.city = apiDest.city
                                existing.country = apiDest.country
                                self.downloadAndSetImage(for: existing, urlString: apiDest.pictureURL)
                            } else {
                                // Create new
                                let newDestination = Destination(context: self.context)
                                newDestination.id = Int32(apiDest.id)
                                newDestination.city = apiDest.city
                                newDestination.country = apiDest.country
                                self.downloadAndSetImage(for: newDestination, urlString: apiDest.pictureURL)
                            }
                        }
                        try self.context.save()
                        completion(true, nil)
                    } catch {
                        completion(false, error)
                    }
                }
                
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    func syncTrips(completion: @escaping (Bool, Error?) -> Void) {
        fetchFromAPI(endpoint: "trips") { [weak self] (result: Result<[APITrip], Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let apiTrips):
                self.context.perform {
                    do {
                        let existingTrips = try self.context.fetch(Trip.fetchRequest()) as! [Trip]
                        
                        for apiTrip in apiTrips {
                            if let existing = existingTrips.first(where: { $0.id == Int32(apiTrip.id) }) {
                                existing.title = apiTrip.title
                                existing.startDate = apiTrip.startDate
                                existing.endDate = apiTrip.endDate
                                existing.destinationID = Int32(apiTrip.destinationID)
                            } else {
                                let newTrip = Trip(context: self.context)
                                newTrip.id = Int32(apiTrip.id)
                                newTrip.title = apiTrip.title
                                newTrip.startDate = apiTrip.startDate
                                newTrip.endDate = apiTrip.endDate
                                newTrip.destinationID = Int32(apiTrip.destinationID)
                            }
                        }
                        try self.context.save()
                        completion(true, nil)
                    } catch {
                        completion(false, error)
                    }
                }
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    // MARK: - Helper to Download Image and Set to CoreData
    private func downloadAndSetImage(for destination: Destination, urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    destination.pictureURL = data
                    self.saveContext()  // Save each image after download ✅
                }
            }
        }.resume()
    }
    
    // MARK: - CRUD Helpers
    func fetchDestinations() -> [Destination] {
        let request: NSFetchRequest<Destination> = Destination.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
    
     func addDestination(city: String, country: String) {
        let destination = Destination(context: context)
        destination.city = city
        destination.country = country
        saveContext()
    }
    
    func deleteDestination(destination: Destination) {
        context.delete(destination)
        saveContext()
    }
    
    func fetchTrips() -> [Trip] {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
    
    @MainActor func addTrip(destination: Destination, title: String, startDate: String, endDate: String) {
        let trip = Trip(context: context)
        trip.title = title
        trip.startDate = startDate
        trip.endDate = endDate
        trip.destination = destination
        saveContext()
    }
    
    @MainActor func deleteTrip(trip: Trip) {
        context.delete(trip)
        saveContext()
    }
    
    // MARK: - Save Context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save CoreData context: \(error.localizedDescription)")
            }
        }
    }
}
