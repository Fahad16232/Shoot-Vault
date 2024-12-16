import SwiftUI
import Combine
import MapKit

// MARK: - Models
struct Photoshoot: Identifiable, Codable {
    var id = UUID()
    var clientName: String
    var date: Date
    var location: String
    var notes: String
    var imageData: Data?
}

struct Client: Identifiable, Codable {
    var id = UUID()
    var name: String
    var contactNumber: String
    var email: String
    var address: String
    var notes: String
    var imageData: Data?
}


struct EquipmentItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var quantity: Int
    var notes: String
    var imageData: Data?
}

// MARK: - ViewModels
class PhotoshootViewModel: ObservableObject {
    @Published var photoshoots: [Photoshoot] = [] {
        didSet { saveData() }
    }
    
    private let userDefaultsKey = "photoshootsData"
    
    init() { loadData() }
    
    func addPhotoshoot(_ photoshoot: Photoshoot) { photoshoots.append(photoshoot) }
    func updatePhotoshoot(_ photoshoot: Photoshoot) {
        if let index = photoshoots.firstIndex(where: { $0.id == photoshoot.id }) {
            photoshoots[index] = photoshoot
        }
    }
    func deletePhotoshoot(at offsets: IndexSet) { photoshoots.remove(atOffsets: offsets) }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(photoshoots) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Photoshoot].self, from: data) {
            photoshoots = decoded
        }
    }
}

class ClientViewModel: ObservableObject {
    @Published var clients: [Client] = [] {
        didSet { saveData() }
    }
    
    private let userDefaultsKey = "clientsData"
    
    init() { loadData() }
    
    func addClient(_ client: Client) { clients.append(client) }
    func updateClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
        }
    }
    func deleteClient(at offsets: IndexSet) { clients.remove(atOffsets: offsets) }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(clients) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Client].self, from: data) {
            clients = decoded
        }
    }
}

class EquipmentViewModel: ObservableObject {
    @Published var items: [EquipmentItem] = [] {
        didSet { saveData() }
    }
    
    private let userDefaultsKey = "equipmentData"
    
    init() { loadData() }
    
    func addItem(_ item: EquipmentItem) { items.append(item) }
    func updateItem(_ item: EquipmentItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
    func deleteItem(at offsets: IndexSet) { items.remove(atOffsets: offsets) }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([EquipmentItem].self, from: data) {
            items = decoded
        }
    }
}

// MARK: - Views
struct ContentView: View {
    var body: some View {
        TabView {
            PhotoshootsTab()
                .tabItem {
                    Label("Photoshoots", systemImage: "camera")
                }
            ClientsTab()
                .tabItem {
                    Label("Clients", systemImage: "person.2")
                }
            EquipmentTab()
                .tabItem {
                    Label("Equipment", systemImage: "wrench.and.screwdriver")
                }
            InsightsTab()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
        }
    }
}

// SearchBar View
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .disableAutocorrection(true)
                .autocapitalization(.none)
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// ImagePicker View
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator // Make sure to set delegate
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        // Leave empty
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        // UIImagePickerControllerDelegate methods
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: Photoshoots Tab
struct PhotoshootsTab: View {
    @EnvironmentObject var viewModel: PhotoshootViewModel
    @State private var selectedPhotoshoot: Photoshoot?
    @State private var isEditMode = false
    @State private var isNavigationActive = false
    @State private var searchText = ""
    @State private var isCalendarView = false
    
    var filteredPhotoshoots: [Photoshoot] {
        if searchText.isEmpty {
            return viewModel.photoshoots
        } else {
            return viewModel.photoshoots.filter {
                $0.clientName.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if viewModel.photoshoots.isEmpty && searchText.isEmpty {
                        emptyStateView
                    } else {
                        VStack {
                            headerView
                            SearchBar(text: $searchText, placeholder: "Search Photoshoots")
                                .padding(.horizontal)
                            
                            if isCalendarView {
                                CalendarView(photoshoots: filteredPhotoshoots)
                            } else {
                                photoshootGridView
                            }
                        }
                    }
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isEditMode = false
                            selectedPhotoshoot = Photoshoot(
                                clientName: "",
                                date: Date(),
                                location: "",
                                notes: "",
                                imageData: nil
                            )
                            isNavigationActive = true
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Photoshoots")
            .background(
                NavigationLink(
                    destination: AddEditPhotoshootView(
                        photoshoot: selectedPhotoshoot ?? Photoshoot(
                            clientName: "",
                            date: Date(),
                            location: "",
                            notes: "",
                            imageData: nil
                        ),
                        isEditMode: isEditMode
                    )
                    .environmentObject(viewModel),
                    isActive: $isNavigationActive
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
    
    // Header with Toggle
    private var headerView: some View {
        HStack {
            Picker("", selection: $isCalendarView) {
                Text("Grid View").tag(false)
                Text("Calendar View").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
        .background(
            Color(UIColor.secondarySystemBackground)
                .cornerRadius(12)
                .padding(.horizontal)
        )
    }
    
    // Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Photoshoots Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Tap the '+' button to add your first photoshoot.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // Photoshoot Grid View
    private var photoshootGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(filteredPhotoshoots) { photoshoot in
                    Button(action: {
                        isEditMode = true
                        selectedPhotoshoot = photoshoot
                        isNavigationActive = true
                    }) {
                        photoshootGridItem(photoshoot: photoshoot)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    // Photoshoot Grid Item
    private func photoshootGridItem(photoshoot: Photoshoot) -> some View {
        VStack {
            if let imageData = photoshoot.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 150)
                    .cornerRadius(12)
                    .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 150)
                        .cornerRadius(12)
                    Image(systemName: "camera")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(photoshoot.clientName)
                    .font(.headline)
                    .foregroundColor(.primary)
                HStack {
                    Image(systemName: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(photoshoot.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(photoshoot.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding([.leading, .trailing, .bottom], 5)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}


struct CalendarView: View {
    var photoshoots: [Photoshoot]
    
    var groupedPhotoshoots: [Date: [Photoshoot]] {
        Dictionary(grouping: photoshoots) { photoshoot in
            Calendar.current.startOfDay(for: photoshoot.date)
        }
    }
    
    var sortedDates: [Date] {
        groupedPhotoshoots.keys.sorted()
    }
    
    var body: some View {
        List {
            ForEach(sortedDates, id: \.self) { date in
                Section(header: Text(date, style: .date).font(.headline)) {
                    ForEach(groupedPhotoshoots[date] ?? []) { photoshoot in
                        HStack {
                            if let imageData = photoshoot.imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                    .overlay(
                                        Image(systemName: "camera")
                                            .foregroundColor(.gray)
                                    )
                            }
                            VStack(alignment: .leading) {
                                Text(photoshoot.clientName)
                                    .font(.headline)
                                Text(photoshoot.location)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct AddEditPhotoshootView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: PhotoshootViewModel
    @State var photoshoot: Photoshoot
    var isEditMode: Bool

    @State private var selectedImage: UIImage? = nil
    @State private var isShowingImagePicker = false
    @State private var isLoadingImage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo Section
                ZStack {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        if let imageData = photoshoot.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit() // Maintain aspect ratio
                                .frame(maxHeight: 250) // Fixed maximum height
                                .cornerRadius(12)
                                .clipped()
                        } else {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(maxHeight: 250)
                                    .cornerRadius(12)
                                VStack {
                                    Image(systemName: "camera")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 50)
                                        .foregroundColor(.gray)
                                    Text("Tap to select a photo")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if isLoadingImage {
                        ProgressView("Loading...")
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
                .padding()
                
                // Details Section
                VStack(spacing: 15) {
                    // Client Name Field
                    VStack(alignment: .leading) {
                        Text("Client Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter client name", text: $photoshoot.clientName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Date Picker
                    VStack(alignment: .leading) {
                        Text("Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("Select date", selection: $photoshoot.date, displayedComponents: .date)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Location Field
                    VStack(alignment: .leading) {
                        Text("Location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter location", text: $photoshoot.location)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Notes Field
                    VStack(alignment: .leading) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Add additional notes", text: $photoshoot.notes)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Save Button
                Button(action: {
                    // Save the selected image data to the photoshoot
                    if let selectedImage = selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                        photoshoot.imageData = imageData
                    }
                    if isEditMode {
                        viewModel.updatePhotoshoot(photoshoot)
                    } else {
                        viewModel.addPhotoshoot(photoshoot)
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding()
                .disabled(photoshoot.clientName.isEmpty || photoshoot.location.isEmpty)
            }
        }
        .navigationTitle(isEditMode ? "Edit Photoshoot" : "Add Photoshoot")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditMode {
                    Button(action: {
                        deletePhotoshoot()
                    }) {
                        Text("Delete")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingImagePicker, onDismiss: {
            isLoadingImage = false
        }) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onAppear {
            if let imageData = photoshoot.imageData, let uiImage = UIImage(data: imageData) {
                selectedImage = uiImage
            }
        }
        .onChange(of: selectedImage) { newImage in
            isLoadingImage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Simulate loading delay
                isLoadingImage = false
                if let selectedImage = newImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                    photoshoot.imageData = imageData
                }
            }
        }
    }
    
    // Delete the photoshoot
    private func deletePhotoshoot() {
        if let index = viewModel.photoshoots.firstIndex(where: { $0.id == photoshoot.id }) {
            viewModel.photoshoots.remove(at: index)
            presentationMode.wrappedValue.dismiss()
        }
    }
}



// MARK: Clients Tab
struct ClientsTab: View {
    @EnvironmentObject var viewModel: ClientViewModel
    @State private var selectedClient: Client?
    @State private var isEditMode = false
    @State private var isNavigationActive = false
    @State private var searchText = ""

    var filteredClients: [Client] {
        if searchText.isEmpty {
            return viewModel.clients
        } else {
            return viewModel.clients.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if viewModel.clients.isEmpty && searchText.isEmpty {
                        emptyStateView
                    } else {
                        VStack {
                            // Search Bar
                            SearchBar(text: $searchText, placeholder: "Search Clients")
                                .padding(.horizontal)

                            // Clients Grid View
                            clientsGridView
                        }
                    }
                }

                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isEditMode = false
                            selectedClient = Client(
                                name: "",
                                contactNumber: "",
                                email: "",
                                address: "",
                                notes: "",
                                imageData: nil
                            )
                            isNavigationActive = true
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Clients")
            .background(
                NavigationLink(
                    destination: AddEditClientView(
                        client: selectedClient ?? Client(
                            name: "",
                            contactNumber: "",
                            email: "",
                            address: "",
                            notes: "",
                            imageData: nil
                        ),
                        isEditMode: isEditMode
                    )
                    .environmentObject(viewModel),
                    isActive: $isNavigationActive
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }

    // Clients Grid View
    private var clientsGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(filteredClients) { client in
                    Button(action: {
                        isEditMode = true
                        selectedClient = client
                        isNavigationActive = true
                    }) {
                        clientGridItem(client: client)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onDelete(perform: viewModel.deleteClient)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // Client Grid Item
    private func clientGridItem(client: Client) -> some View {
        VStack {
            if let imageData = client.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 150)
                    .cornerRadius(12)
                    .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 150)
                        .cornerRadius(12)
                    Image(systemName: "person")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50)
                        .foregroundColor(.gray)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(client.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                HStack {
                    Image(systemName: "envelope")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(client.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding([.leading, .trailing, .bottom], 5)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue.opacity(0.6))
            Text("No Clients Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("Tap the '+' button to add your first client.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}



struct AddEditClientView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ClientViewModel
    @State var client: Client
    var isEditMode: Bool
    
    @State private var selectedImage: UIImage? = nil
    @State private var isShowingImagePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo Section
                ZStack {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        if let imageData = client.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 250) // Fixed height
                                .cornerRadius(12)
                                .clipped()
                        } else {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 250)
                                    .cornerRadius(12)
                                VStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 50)
                                        .foregroundColor(.gray)
                                    Text("Tap to select a photo")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                
                // Details Section
                VStack(spacing: 15) {
                    // Name Field
                    VStack(alignment: .leading) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter client name", text: $client.name)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Contact Number Field
                    VStack(alignment: .leading) {
                        Text("Contact Number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter contact number", text: $client.contactNumber)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Email Field
                    VStack(alignment: .leading) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter email", text: $client.email)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Address Field
                    VStack(alignment: .leading) {
                        Text("Address")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter address", text: $client.address)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Notes Field
                    VStack(alignment: .leading) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter notes", text: $client.notes)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Save Button
                Button(action: {
                    // Save the selected image
                    if let selectedImage = selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                        client.imageData = imageData
                    }
                    if isEditMode {
                        viewModel.updateClient(client)
                    } else {
                        viewModel.addClient(client)
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: client.name.isEmpty || client.contactNumber.isEmpty ? [Color.gray, Color.gray] : [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .padding()
                }
                .disabled(client.name.isEmpty || client.contactNumber.isEmpty)
            }
        }
        .navigationTitle(isEditMode ? "Edit Client" : "Add Client")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditMode {
                    Button(action: {
                        deleteClient()
                    }) {
                        Text("Delete")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onAppear {
            // Load existing data
            if let imageData = client.imageData, let uiImage = UIImage(data: imageData) {
                selectedImage = uiImage
            }
        }
        .onChange(of: selectedImage) { newImage in
            if let selectedImage = newImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                client.imageData = imageData
            }
        }
    }
    
    // Delete the client
    private func deleteClient() {
        if let index = viewModel.clients.firstIndex(where: { $0.id == client.id }) {
            viewModel.clients.remove(at: index)
            presentationMode.wrappedValue.dismiss()
        }
    }
}





// MARK: Equipment Tab
struct EquipmentTab: View {
    @EnvironmentObject var viewModel: EquipmentViewModel
    @State private var selectedItem: EquipmentItem?
    @State private var isEditMode = false
    @State private var isNavigationActive = false
    @State private var searchText = ""

    var filteredItems: [EquipmentItem] {
        if searchText.isEmpty {
            return viewModel.items
        } else {
            return viewModel.items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if viewModel.items.isEmpty && searchText.isEmpty {
                        emptyStateView
                    } else {
                        VStack {
                            // Search Bar and Add Button
                            HStack {
                                SearchBar(text: $searchText, placeholder: "Search Equipment")
                                Button(action: {
                                    isEditMode = false
                                    selectedItem = EquipmentItem(
                                        name: "",
                                        quantity: 1,
                                        notes: "",
                                        imageData: nil
                                    )
                                    isNavigationActive = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)

                            equipmentGridView
                        }
                    }
                }
                .navigationTitle("Equipment")
                .background(
                    NavigationLink(
                        destination: AddEditEquipmentItemView(
                            item: selectedItem ?? EquipmentItem(
                                name: "",
                                quantity: 1,
                                notes: "",
                                imageData: nil
                            ),
                            isEditMode: isEditMode
                        )
                        .environmentObject(viewModel),
                        isActive: $isNavigationActive
                    ) {
                        EmptyView()
                    }
                    .hidden()
                )
            }
        }
    }

    private var equipmentGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(filteredItems) { item in
                    Button(action: {
                        isEditMode = true
                        selectedItem = item
                        isNavigationActive = true
                    }) {
                        equipmentGridItem(item: item)
                    }
                }
                .onDelete(perform: viewModel.deleteItem)
            }
            .padding(.horizontal)
        }
    }

    private func equipmentGridItem(item: EquipmentItem) -> some View {
        VStack {
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 150)
                    .cornerRadius(12)
                    .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 150)
                        .cornerRadius(12)
                    Image(systemName: "wrench.and.screwdriver")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50)
                        .foregroundColor(.gray)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Quantity: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding([.leading, .trailing, .bottom], 5)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue.opacity(0.6))
            Text("No Equipment Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("Tap the '+' button to add your first equipment item.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}



struct AddEditEquipmentItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: EquipmentViewModel
    @State var item: EquipmentItem
    var isEditMode: Bool

    @State private var selectedImage: UIImage? = nil
    @State private var isShowingImagePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo Section
                ZStack {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 250)
                                .cornerRadius(12)
                                .clipped()
                        } else {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 250)
                                    .cornerRadius(12)
                                VStack {
                                    Image(systemName: "wrench.and.screwdriver")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 50)
                                        .foregroundColor(.gray)
                                    Text("Tap to select a photo")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()

                // Details Section
                VStack(spacing: 15) {
                    TextField("Name", text: $item.name)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)

                    Stepper("Quantity: \(item.quantity)", value: $item.quantity, in: 1...1000)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)

                    TextField("Notes", text: $item.notes)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .padding([.leading, .trailing])

                // Save Button
                Button(action: {
                    // Save the selected image data to the item
                    if let selectedImage = selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                        item.imageData = imageData
                    }
                    if isEditMode {
                        viewModel.updateItem(item)
                    } else {
                        viewModel.addItem(item)
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(item.name.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                        .padding()
                }
                .disabled(item.name.isEmpty)
            }
        }
        .navigationTitle(isEditMode ? "Edit Equipment" : "Add Equipment")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditMode {
                    Button(action: {
                        deleteEquipmentItem()
                    }) {
                        Text("Delete")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onAppear {
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                selectedImage = uiImage
            }
        }
        .onChange(of: selectedImage) { newImage in
            if let selectedImage = newImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                item.imageData = imageData
            }
        }
    }

    // Delete the equipment item
    private func deleteEquipmentItem() {
        if let index = viewModel.items.firstIndex(where: { $0.id == item.id }) {
            viewModel.items.remove(at: index)
            presentationMode.wrappedValue.dismiss()
        }
    }
}





// MARK: Insights Tab
struct InsightsTab: View {
    @EnvironmentObject var photoshootVM: PhotoshootViewModel
    @EnvironmentObject var clientVM: ClientViewModel
    @EnvironmentObject var equipmentVM: EquipmentViewModel
    
    var upcomingPhotoshoots: Int {
        let today = Date()
        return photoshootVM.photoshoots.filter { $0.date >= today }.count
    }
    
    var totalClients: Int {
        clientVM.clients.count
    }
    
    var totalEquipment: Int {
        equipmentVM.items.reduce(0) { $0 + $1.quantity }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Business Insights")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 20)
                    
                    // Cards Section
                    VStack(spacing: 20) {
                        InsightCard(
                            icon: "calendar",
                            iconColor: .blue,
                            title: "Upcoming Photoshoots",
                            value: "\(upcomingPhotoshoots)"
                        )
                        
                        InsightCard(
                            icon: "person.2",
                            iconColor: .green,
                            title: "Total Clients",
                            value: "\(totalClients)"
                        )
                        
                        InsightCard(
                            icon: "wrench.and.screwdriver",
                            iconColor: .orange,
                            title: "Total Equipment Items",
                            value: "\(totalEquipment)"
                        )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
            .navigationTitle("Insights")
        }
    }
}

struct InsightCard: View {
    var icon: String
    var iconColor: Color
    var title: String
    var value: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [iconColor.opacity(0.2), iconColor.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: iconColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            HStack(spacing: 15) {
                // Icon Section
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(iconColor)
                }
                
                // Text Section
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(height: 100)
        .padding(.horizontal, 5)
    }
}


// MARK: - App Entry Point
@main
struct PhotoShootManagerApp: App {
    @StateObject var photoshootVM = PhotoshootViewModel()
    @StateObject var clientVM = ClientViewModel()
    @StateObject var equipmentVM = EquipmentViewModel()

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(photoshootVM)
                .environmentObject(clientVM)
                .environmentObject(equipmentVM)
        }
    }
}
