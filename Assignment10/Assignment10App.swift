
import SwiftUI

@main
struct Assignment11App: App {
    init() {
        CoreDataManager.shared.preloadIfNeeded()  // ✅ API to CoreData
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataManager.shared.context)  // ✅ inject CoreData context globally
        }
    }
}
