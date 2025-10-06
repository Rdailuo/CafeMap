//
//  CafeMapApp.swift
//  CafeMap
//
//  All-in-one SwiftUI file: Location manager, search, map annotations (including "You"),
//  and robust directions opening using MKMapItem.forCurrentLocation() as the source.
//  Created: 2025-10-06 (updated)
//
import SwiftUI
import MapKit
import CoreLocation

// MARK: - Models
struct CoffeePlace: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    let searchCenter: CLLocationCoordinate2D
    
    var coordinate: CLLocationCoordinate2D {
        mapItem.placemark.coordinate
    }
    
    var name: String {
        mapItem.name ?? "Unknown Coffee Shop"
    }
    
    var address: String {
        let placemark = mapItem.placemark
        let address = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode
        ].compactMap { $0 }.joined(separator: ", ")
        return address.isEmpty ? "Address unavailable" : address
    }
    
    var distance: String {
        if let placeLocation = mapItem.placemark.location {
            let searchLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
            let distance = placeLocation.distance(from: searchLocation)
            let miles = distance / 1609.34
            return String(format: "%.1f miles away", miles)
        }
        return ""
    }
}

// MARK: - User Location Annotation
struct UserLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Main App View
struct ContentView: View {
    @State private var coffeePlaces: [CoffeePlace] = []
    @State private var selectedPlace: CoffeePlace?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var currentZipCode = ""
    @State private var showingZipCodeInput = true
    @State private var isSearching = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var searchCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var userLocation: UserLocation?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map with both coffee places and user location annotations
                Map(coordinateRegion: $region, interactionModes: .all, annotationItems: allAnnotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        if let coffeePlace = item.value as? CoffeePlace {
                            // Coffee shop annotation
                            Button(action: {
                                selectedPlace = coffeePlace
                            }) {
                                VStack {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .foregroundColor(.brown)
                                        .font(.title2)
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                    Text(coffeePlace.name)
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                        .padding(4)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(4)
                                }
                            }
                        } else if item.value is UserLocation {
                            // User location annotation
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                Text("YOU")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .padding(4)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack(spacing: 12) {
                        Text(currentZipCode.isEmpty ? "Enter a zip code to start" : "Zip Code: \(currentZipCode)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: { showingZipCodeInput = true }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text(currentZipCode.isEmpty ? "Search" : "Change")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    if isSearching {
                        ProgressView("Searching for coffee shops...")
                            .padding()
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
            }
            .navigationTitle("CafeMap")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingZipCodeInput) {
                ZipCodeInputView(isPresented: $showingZipCodeInput, onSearch: searchByZipCode)
            }
            .sheet(item: $selectedPlace) { place in
                CoffeeDetailView(place: place, userLocation: searchCenter)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // Combine coffee places and user location for map annotations
    private var allAnnotations: [AnyIdentifiable] {
        var annotations: [AnyIdentifiable] = coffeePlaces.map { AnyIdentifiable($0) }
        if let userLocation = userLocation {
            annotations.append(AnyIdentifiable(userLocation))
        }
        return annotations
    }
    
    func searchByZipCode(_ zipCode: String) {
        currentZipCode = zipCode
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(zipCode) { placemarks, error in
            if let location = placemarks?.first?.location?.coordinate {
                searchCenter = location
                userLocation = UserLocation(coordinate: location) // Set user location
                searchCoffeeShops(around: location)
            } else {
                errorMessage = "Invalid zip code. Please try again."
                showingError = true
            }
        }
    }
    
    func searchCoffeeShops(around coordinate: CLLocationCoordinate2D) {
        isSearching = true
        coffeePlaces = []
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "coffee"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 16093.4, // 10 miles in meters
            longitudinalMeters: 16093.4
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            
            if let error = error {
                errorMessage = "Search failed: \(error.localizedDescription)"
                showingError = true
                return
            }
            
            guard let response = response else {
                errorMessage = "No coffee shops found in this area."
                showingError = true
                return
            }
            
            coffeePlaces = response.mapItems.map { item in
                CoffeePlace(
                    mapItem: item,
                    searchCenter: coordinate
                )
            }
            
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}

// MARK: - Helper for mixed annotation types
struct AnyIdentifiable: Identifiable {
    let id: UUID
    let value: Any
    
    init<T: Identifiable>(_ value: T) where T.ID == UUID {
        self.id = value.id
        self.value = value
    }
}

extension AnyIdentifiable {
    var coordinate: CLLocationCoordinate2D {
        if let coffeePlace = value as? CoffeePlace {
            return coffeePlace.coordinate
        } else if let userLocation = value as? UserLocation {
            return userLocation.coordinate
        }
        return CLLocationCoordinate2D(latitude: 0, longitude: 0) // fallback
    }
}


// MARK: - Zip Code Input View
struct ZipCodeInputView: View {
    @Binding var isPresented: Bool
    @State private var zipCode = ""
    let onSearch: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Zip Code")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("Zip Code or Postal Code", text: $zipCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .font(.title3)
                    .textInputAutocapitalization(.characters) // Optional: Auto-capitalize for postal codes
                    .autocorrectionDisabled(true) // Disable autocorrect for codes
                
                Button(action: {
                    if !zipCode.isEmpty {
                        onSearch(zipCode)
                        isPresented = false
                    }
                }) {
                    Text("Search")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(zipCode.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(zipCode.isEmpty)
                .padding()
                
                // Optional: Add a hint for users
                Text("Enter US Zip Code or Canadian Postal Code")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
}

// MARK: - Coffee Detail View
struct CoffeeDetailView: View {
    let place: CoffeePlace
    let userLocation: CLLocationCoordinate2D  // This is now the searched zip code location
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.brown)
                    .padding()
                
                Text(place.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(place.address)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if !place.distance.isEmpty {
                    Text(place.distance)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Button(action: openDirections) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        Text("Get Directions")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    func openDirections() {
        let destinationPlacemark = MKPlacemark(coordinate: place.mapItem.placemark.coordinate)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        destinationMapItem.name = place.name
        
        // Create map item for user's searched location (start point)
        let startPlacemark = MKPlacemark(coordinate: userLocation)
        let startMapItem = MKMapItem(placemark: startPlacemark)
        startMapItem.name = "Your Location"
        
        // Open Maps with both start and destination
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ] as [String : Any]
        
        MKMapItem.openMaps(with: [startMapItem, destinationMapItem], launchOptions: launchOptions)
    }
}

// MARK: - App Entry Point
@main
struct CafeMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
