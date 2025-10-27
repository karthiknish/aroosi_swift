#if os(iOS)
import Foundation
import CoreLocation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
import Combine

@available(iOS 17, *)
@MainActor
class AdvancedSearchFiltersViewModel: ObservableObject {
    @Published var state = AdvancedSearchFiltersState()
    @Published var currentFilters: SearchFilters
    
    private let locationService: LocationService
    private let searchService: SearchService
    private let permissionManager: PermissionManager
    private var cancellables = Set<AnyCancellable>()
    
    init(initialFilters: SearchFilters,
         locationService: LocationService = DefaultLocationService(),
         searchService: SearchService = DefaultSearchService(),
         permissionManager: PermissionManager = .shared) {
        self.currentFilters = initialFilters
        self.locationService = locationService
        self.searchService = searchService
        self.permissionManager = permissionManager
    }
    
    func loadAvailableOptions() {
        Task {
            do {
                state.isLoadingInterests = true
                let interests = try await searchService.getAvailableInterests()
                state.availableInterests = interests
            } catch {
                state.errorMessage = "Failed to load interests: \(error.localizedDescription)"
            }
            state.isLoadingInterests = false
        }
    }
    
    func toggleLocationBasedSearch(_ enabled: Bool) {
        state.locationBasedSearchEnabled = enabled
        
        if enabled {
            Task {
                await requestLocationPermission()
            }
        } else {
            state.currentLocation = nil
        }
    }
    
    private func requestLocationPermission() async {
        let hasPermission = await permissionManager.handleLocationPermission()
        
        if hasPermission {
            do {
                state.isRequestingLocation = true
                let location = try await locationService.getCurrentLocation()
                state.currentLocation = location
            } catch {
                state.locationBasedSearchEnabled = false
                state.errorMessage = "Failed to get location: \(error.localizedDescription)"
            }
            state.isRequestingLocation = false
        } else {
            state.locationBasedSearchEnabled = false
            state.errorMessage = "Location permission is required for location-based search"
        }
    }
    
    func updateIncludeNearbyCities(_ include: Bool) {
        state.includeNearbyCities = include
    }
    
    func toggleInterest(_ interest: String, isSelected: Bool) {
        if isSelected {
            state.selectedInterests.insert(interest)
        } else {
            state.selectedInterests.remove(interest)
        }
        updateFiltersWithInterests()
    }
    
    func updateReligiousPreference(_ preference: String?) {
        state.religiousPreference = preference
        updateFiltersWithAdvancedOptions()
    }
    
    func updateFamilyValues(_ values: String?) {
        state.familyValues = values
        updateFiltersWithAdvancedOptions()
    }
    
    func updateFamilyApprovalRequired(_ required: Bool) {
        state.familyApprovalRequired = required
        updateFiltersWithAdvancedOptions()
    }
    
    func updateEducationLevel(_ level: String?) {
        state.educationLevel = level
        updateFiltersWithAdvancedOptions()
    }
    
    func updateOccupation(_ occupation: String?) {
        state.occupation = occupation
        updateFiltersWithAdvancedOptions()
    }
    
    func updateSmokerFriendly(_ friendly: Bool) {
        state.smokerFriendly = friendly
        updateFiltersWithAdvancedOptions()
    }
    
    func updateDrinksAlcohol(_ drinks: Bool) {
        state.drinksAlcohol = drinks
        updateFiltersWithAdvancedOptions()
    }
    
    func updateIncludeInactiveProfiles(_ include: Bool) {
        state.includeInactiveProfiles = include
        updateFiltersWithAdvancedOptions()
    }
    
    func updateOnlyVerifiedProfiles(_ onlyVerified: Bool) {
        state.onlyVerifiedProfiles = onlyVerified
        updateFiltersWithAdvancedOptions()
    }
    
    func updateFilter(key: SearchFilterKey, value: Any?) {
        switch key {
        case .query:
            currentFilters = currentFilters.updating(query: value as? String)
        case .city:
            currentFilters = currentFilters.updating(city: value as? String)
        case .minAge:
            currentFilters = currentFilters.updating(minAge: value as? Int, maxAge: currentFilters.maxAge)
        case .maxAge:
            currentFilters = currentFilters.updating(minAge: currentFilters.minAge, maxAge: value as? Int)
        case .preferredGender:
            currentFilters = currentFilters.updating(preferredGender: value as? String)
        case .pageSize:
            currentFilters = currentFilters.updating(pageSize: value as? Int)
        }
    }
    
    private func updateFiltersWithInterests() {
        // Add interests to query or create a separate interests filter
        let interestsString = Array(state.selectedInterests).joined(separator: ",")
        if !interestsString.isEmpty {
            currentFilters = currentFilters.updating(query: interestsString)
        }
    }
    
    private func updateFiltersWithAdvancedOptions() {
        // Create advanced query string
        var queryComponents: [String] = []
        
        if let religious = state.religiousPreference {
            queryComponents.append("religion:\(religious)")
        }
        
        if let familyValues = state.familyValues {
            queryComponents.append("family_values:\(familyValues)")
        }
        
        if state.familyApprovalRequired {
            queryComponents.append("family_approval:true")
        }
        
        if let education = state.educationLevel {
            queryComponents.append("education:\(education)")
        }
        
        if let occupation = state.occupation {
            queryComponents.append("occupation:\(occupation)")
        }
        
        if state.smokerFriendly {
            queryComponents.append("smoker:true")
        }
        
        if state.drinksAlcohol {
            queryComponents.append("alcohol:true")
        }
        
        if state.onlyVerifiedProfiles {
            queryComponents.append("verified:true")
        }
        
        if !queryComponents.isEmpty {
            let advancedQuery = queryComponents.joined(separator: " ")
            currentFilters = currentFilters.updating(query: advancedQuery)
        }
    }
    
    private func requestLocationPermission() {
        Task {
            do {
                state.isRequestingLocation = true
                let granted = try await locationService.requestPermission()
                
                if granted {
                    let location = try await locationService.getCurrentLocation()
                    state.currentLocation = location
                } else {
                    state.locationBasedSearchEnabled = false
                    state.errorMessage = "Location permission is required for location-based search"
                }
            } catch {
                state.locationBasedSearchEnabled = false
                state.errorMessage = "Failed to get location: \(error.localizedDescription)"
            }
            state.isRequestingLocation = false
        }
    }
}

// MARK: - State

@available(iOS 17, *)
class AdvancedSearchFiltersState: ObservableObject {
    @Published var isLoadingInterests = false
    @Published var isRequestingLocation = false
    @Published var isApplying = false
    @Published var errorMessage: String?
    @Published var availableInterests: [String] = []
    @Published var selectedInterests: Set<String> = []
    @Published var locationBasedSearchEnabled = false
    @Published var includeNearbyCities = false
    @Published var searchRadius: Int = 25
    @Published var currentLocation: CLLocation?
    @Published var religiousPreference: String?
    @Published var familyValues: String?
    @Published var familyApprovalRequired = false
    @Published var educationLevel: String?
    @Published var occupation: String?
    @Published var smokerFriendly = false
    @Published var drinksAlcohol = false
    @Published var includeInactiveProfiles = false
    @Published var onlyVerifiedProfiles = false
    @Published var showAgeRangePicker = false
    @Published var showRadiusPicker = false
}

// MARK: - Enums

enum SearchFilterKey {
    case query
    case city
    case minAge
    case maxAge
    case preferredGender
    case pageSize
}

// MARK: - Protocols

protocol LocationService {
    func requestPermission() async throws -> Bool
    func getCurrentLocation() async throws -> CLLocation
}

protocol SearchService {
    func getAvailableInterests() async throws -> [String]
}

// MARK: - Default Implementations

#if canImport(FirebaseFirestore)

class DefaultSearchService: SearchService {
    private let db = Firestore.firestore()
    private let logger = Logger.shared
    
    func getAvailableInterests() async throws -> [String] {
        logger.info("Fetching available interests from Firestore")
        
        do {
            let snapshot = try await db.collection("interests").getDocuments()
            let interests = snapshot.documents.compactMap { document -> String? in
                return document.data()["name"] as? String
            }
            
            logger.info("Successfully fetched \(interests.count) interests from Firestore")
            return interests.sorted()
            
        } catch {
            logger.error("Failed to fetch interests from Firestore: \(error.localizedDescription)")
            // Fallback to hardcoded interests if Firestore fails
            return getFallbackInterests()
        }
    }
    
    private func getFallbackInterests() -> [String] {
        return [
            "Travel", "Cooking", "Reading", "Music", "Movies", "Sports", "Fitness",
            "Photography", "Art", "Writing", "Dancing", "Gaming", "Technology",
            "Nature", "Animals", "Volunteering", "Fashion", "Food", "Wine",
            "Coffee", "Tea", "Yoga", "Meditation", "Spirituality", "Politics",
            "History", "Science", "Languages", "Culture", "Architecture",
            "Design", "Business", "Entrepreneurship", "Investing", "Finance",
            "Marketing", "Social Media", "Blogging", "Podcasts", "Books",
            "Theater", "Comedy", "Animation", "Comics", "Anime", "Manga",
            "Gardening", "DIY", "Crafts", "Knitting", "Sewing", "Woodworking",
            "Mechanics", "Cars", "Motorcycles", "Cycling", "Running", "Hiking",
            "Camping", "Fishing", "Hunting", "Bird Watching", "Astronomy",
            "Chess", "Board Games", "Card Games", "Video Games", "Esports",
            "Programming", "Artificial Intelligence", "Robotics", "Blockchain",
            "Cryptocurrency", "Data Science", "Machine Learning", "Cybersecurity"
        ]
    }
}

#else

class DefaultSearchService: SearchService {
    func getAvailableInterests() async throws -> [String] {
        // Fallback implementation when Firebase is not available
        return [
            "Travel", "Cooking", "Reading", "Music", "Movies", "Sports", "Fitness",
            "Photography", "Art", "Writing", "Dancing", "Gaming", "Technology",
            "Nature", "Animals", "Volunteering", "Fashion", "Food", "Wine",
            "Coffee", "Tea", "Yoga", "Meditation", "Spirituality", "Politics",
            "History", "Science", "Languages", "Culture", "Architecture",
            "Design", "Business", "Entrepreneurship", "Investing", "Finance",
            "Marketing", "Social Media", "Blogging", "Podcasts", "Books",
            "Theater", "Comedy", "Animation", "Comics", "Anime", "Manga",
            "Gardening", "DIY", "Crafts", "Knitting", "Sewing", "Woodworking",
            "Mechanics", "Cars", "Motorcycles", "Cycling", "Running", "Hiking",
            "Camping", "Fishing", "Hunting", "Bird Watching", "Astronomy",
            "Chess", "Board Games", "Card Games", "Video Games", "Esports",
            "Programming", "Artificial Intelligence", "Robotics", "Blockchain",
            "Cryptocurrency", "Data Science", "Machine Learning", "Cybersecurity"
        ]
    }
}

#endif

class DefaultLocationService: LocationService {
    private let locationManager = CLLocationManager()
    
    func requestPermission() async throws -> Bool {
        return await withCheckedContinuation { continuation in
            locationManager.requestWhenInUseAuthorization()
            
            // Check current status
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                continuation.resume(returning: true)
            case .denied, .restricted:
                continuation.resume(returning: false)
            case .notDetermined:
                // Set up delegate to handle the response
                // In a real implementation, you'd set up proper delegate handling
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    continuation.resume(returning: self.locationManager.authorizationStatus == .authorizedWhenInUse)
                }
            @unknown default:
                continuation.resume(returning: false)
            }
        }
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
            
            // In a real implementation, you'd set up proper delegate handling
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let location = locationManager.location {
                    continuation.resume(returning: location)
                } else {
                    continuation.resume(throwing: LocationError.locationUnavailable)
                }
            }
        }
    }
}

class DefaultSearchService: SearchService {
    func getAvailableInterests() async throws -> [String] {
        // Mock data - in real implementation, this would come from backend
        return [
            "Travel", "Cooking", "Reading", "Music", "Movies", "Sports", "Fitness",
            "Photography", "Art", "Writing", "Dancing", "Gaming", "Technology",
            "Nature", "Animals", "Volunteering", "Fashion", "Food", "Wine",
            "Coffee", "Tea", "Yoga", "Meditation", "Spirituality", "Politics",
            "History", "Science", "Languages", "Culture", "Architecture",
            "Design", "Business", "Entrepreneurship", "Investing", "Finance"
        ]
    }
}

// MARK: - Errors

enum LocationError: Error {
    case permissionDenied
    case locationUnavailable
    case timeout
    
    var localizedDescription: String {
        switch self {
        case .permissionDenied:
            return "Location permission was denied"
        case .locationUnavailable:
            return "Unable to determine current location"
        case .timeout:
            return "Location request timed out"
        }
    }
}

#endif
