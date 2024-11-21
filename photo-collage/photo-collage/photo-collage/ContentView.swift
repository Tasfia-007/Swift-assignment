import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var isPickerPresented: Bool = false
    @State private var showSaveAlert: Bool = false
    @State private var saveError: Error?
    @State private var collageStyle: CollageStyle = .grid

    var body: some View {
        NavigationView {
            VStack {
                if selectedImages.isEmpty {
                    Text("Tap '+' to add photos")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(selectedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(collageStyle == .rounded ? 20 : 0)
                                    .overlay(RoundedRectangle(cornerRadius: collageStyle == .rounded ? 20 : 0).stroke(Color.gray, lineWidth: 2))
                                    .shadow(radius: 5)
                            }
                        }
                        .padding()
                    }
                    
                    HStack {
                        Button(action: {
                            collageStyle = collageStyle == .grid ? .rounded : .grid
                        }) {
                            Text("Toggle Style")
                                .font(.subheadline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .padding([.horizontal, .bottom])
                        
                        Button(action: saveCollage) {
                            Text("Save Collage")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .padding([.horizontal, .bottom])
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Photo Collage")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPickerPresented = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Circle().fill(Color.white).shadow(radius: 5))
                    }
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                PhotoPicker(selectedImages: $selectedImages)
            }
            .alert(isPresented: $showSaveAlert) {
                if saveError == nil {
                    return Alert(title: Text("Saved!"), message: Text("Your collage has been saved to your Photos library."), dismissButton: .default(Text("OK")))
                } else {
                    return Alert(title: Text("Error"), message: Text("Could not save the collage."), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    func saveCollage() {
        guard !selectedImages.isEmpty else { return }
        
        let collageSize = CGSize(width: 1000, height: 1000)
        UIGraphicsBeginImageContext(collageSize)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(CGRect(origin: .zero, size: collageSize))
        
        let gridSize = Int(sqrt(Double(selectedImages.count)).rounded(.up))
        let cellSize = CGSize(width: collageSize.width / CGFloat(gridSize), height: collageSize.height / CGFloat(gridSize))
        
        for (index, image) in selectedImages.enumerated() {
            let row = index / gridSize
            let col = index % gridSize
            let rect = CGRect(x: CGFloat(col) * cellSize.width, y: CGFloat(row) * cellSize.height, width: cellSize.width, height: cellSize.height)
            image.draw(in: rect)
        }
        
        let collage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let collage = collage {
            UIImageWriteToSavedPhotosAlbum(collage, nil, nil, nil)
            showSaveAlert = true
            saveError = nil
        } else {
            showSaveAlert = true
            saveError = NSError(domain: "CollageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create collage."])
        }
    }
}

enum CollageStyle {
    case grid
    case rounded
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 10 // Limit to 10 images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        if let uiImage = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(uiImage)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

