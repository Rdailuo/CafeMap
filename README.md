# ☕ CafeMap - iOS Coffee Finder App

An iOS application that helps users discover nearby coffee shops within a 10-mile radius using zip code search. Built with SwiftUI and MapKit.

<div align="center">
|<img width="270" alt="IMG_8800" src="https://github.com/user-attachments/assets/45922208-fa11-43e1-b4ac-78df556884e4" /> | <img width="270" alt="IMG_8801" src="https://github.com/user-attachments/assets/17902cff-ab4e-4d9e-a9b2-e8a04f979344" /> | <img width="270" alt="IMG_8802" src="https://github.com/user-attachments/assets/e263a3d8-f24d-4d9e-963a-3bc9c945acdf" /> | 
</div>


➡️ **Watch Demo Video** [**Here**](https://youtube.com/shorts/7HD3TZegpew?feature=share)

## 📱 Features

- **Location Search**: Find coffee shops within 10 miles of any US zip code or Canadian postal code
- **Interactive Map**: Visual representation with custom annotations
- **Get Directions**: One-tap navigation to selected cafes via Apple Maps
- **User Location Marker**: Red "YOU" pin showing your searched location
- **Distance Calculations**: Shows exact distance from your location

## 🛠️ Technologies Used

- **SwiftUI** - Modern declarative UI framework
- **MapKit** - Apple's mapping and location services
- **Core Location** - Location and geographic services
- **MVVM Architecture** - Clean, maintainable code structure

## 🚀 Getting Started

### Prerequisites

- Xcode 14.0 or later
- iOS 15.0 or later
- macOS Monterey or later

### Installation
Download the Project
- Click the "Code" button and select "Download ZIP"
- Extract the ZIP file to your preferred location
- Open in Xcode
- Open the .xcodeproj file in Xcode
- Build and Run
- Select your target device or simulator (iPhone recommended)
- Press Cmd + R to build and run

### Usage
- Enter Location: Tap "Search" and enter a US Zip Code or Canadian Postal Code
- Browse Coffee Shops: View all nearby cafes on the interactive map
- Get Details: Tap any coffee cup icon to see shop details
- Get Directions: Tap "Get Directions" to open Apple Maps with navigation

## 🏗️ Project Structure
```text
CafeMap/
├── Models/
│   ├── CoffeePlace.swift
│   └── UserLocation.swift
├── Views/
│   ├── ContentView.swift
│   ├── ZipCodeInputView.swift
│   └── CoffeeDetailView.swift
├── Utilities/
│   └── AnyIdentifiable.swift
└── Resources/
    └── Assets.xcassets
```
## 🎯 Technical Highlights
Mixed Annotation Types: Custom map annotations for both user location and coffee shops

Apple Maps Integration: Seamless directions with proper start/end locations

Real-time Distance: Dynamic distance calculations for each coffee shop

Cross-platform Support: Handles both US zip codes and Canadian postal codes

## 🔑 Key Implementation Details

### Zip Code Geocoding
Converts user-input zip codes to geographic coordinates using Core Location's CLGeocoder.

```swift
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
```

### Local Search with MapKit
Uses MKLocalSearch to find coffee shops within a 10-mile radius of the geocoded location.
```swift
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
        
        (...)
  ```
### Distance Calculation
Calculates precise distance between user location and each coffee shop using Core Location.

```swift
var distance: String {
    if let placeLocation = mapItem.placemark.location {
        let searchLocation = CLLocation(latitude: searchCenter.latitude, 
                                      longitude: searchCenter.longitude)
        let distance = placeLocation.distance(from: searchLocation)
        let miles = distance / 1609.34
        return String(format: "%.1f miles away", miles)
    }
    return ""
}
```
## 📋 Features in Development

- [ ] Filter by rating
- [ ] Save favorite coffee shops
- [ ] Current location search option
- [ ] Share coffee shop locations
- [ ] Dark mode optimization

## 👤 Author

**Reyna Dai Luo**
- GitHub: [@Rdailuo](https://github.com/Rdailuo)
- LinkedIn: [reynadai](https://www.linkedin.com/in/reynadai/)
- Portfolio: [this-is-Reyna](https://www.notion.so/Hi-I-m-Reyna-Dai-1de9921211f1809a8e72ddcdd231df65?pvs=4
)

##  👨‍💻 Developer
Inspired by the need to find great coffee anywhere!
Built with ❤️ using SwiftUI and MapKit

