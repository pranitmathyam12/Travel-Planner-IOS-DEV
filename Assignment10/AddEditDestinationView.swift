import SwiftUI
import PhotosUI

struct AddEditDestinationView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var context

    @State var destination: Destination?
    @State private var city = ""
    @State private var country = ""
    @State private var selectedUIImage: UIImage?
    @State private var showAlert = false
    @State private var showImagePicker = false

    var onSave: (() -> Void)?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Destination Info")) {
                    TextField("City", text: $city)
                    TextField("Country", text: $country)
                }

                Section(header: Text("Image")) {
                    if let selectedUIImage = selectedUIImage {
                        Image(uiImage: selectedUIImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .clipped()
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .foregroundColor(.gray)
                    }

                    Button {
                        showImagePicker = true
                    } label: {
                        Label("Select Image", systemImage: "photo.on.rectangle")
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(destination?.city == nil ? "Add Destination" : "Edit Destination")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if city.isEmpty || country.isEmpty {
                            showAlert = true
                        } else {
                            saveDestination()
                        }
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedUIImage)
            }
            .alert("Missing Fields", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please fill all fields.")
            }
            .onAppear {
                loadDestinationData()
            }
        }
    }

    private func saveDestination() {
        if destination == nil {
            destination = Destination(context: context)
            destination?.id = Int32(Int.random(in: 100...10000))
        }
        destination?.city = city
        destination?.country = country

        if let selectedImage = selectedUIImage {
            destination?.pictureURL = selectedImage.jpegData(compressionQuality: 0.8)
        }

        CoreDataManager.shared.saveContext()
        onSave?()
        presentationMode.wrappedValue.dismiss()
    }

    private func loadDestinationData() {
        if let destination = destination {
            city = destination.city ?? ""
            country = destination.country ?? ""
            if let data = destination.pictureURL, let uiImage = UIImage(data: data) {
                selectedUIImage = uiImage
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}
