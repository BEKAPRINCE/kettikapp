import Foundation
import Combine

// MARK: - Search ViewModel
final class SearchViewModel: ObservableObject {
    
    @Published var searchQuery: String = ""
    @Published var filteredRoutes: [Route] = []
    @Published var selectedFilter: TransportType? = nil
    @Published var isSearching: Bool = false
    
    private let transportService = TransportService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearch()
    }
    
    // MARK: - Setup search pipeline
    private func setupSearch() {
        $searchQuery
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .combineLatest($selectedFilter)
            .map { [weak self] (query, filter) -> [Route] in
                guard let self else { return [] }
                var results = self.transportService.search(query: query)
                if let filter {
                    results = results.filter { $0.type == filter }
                }
                return results
            }
            .assign(to: &$filteredRoutes)
        
        // Initial load
        filteredRoutes = transportService.getAllRoutes()
    }
    
    // MARK: - Actions
    func setFilter(_ type: TransportType?) {
        selectedFilter = (selectedFilter == type) ? nil : type
    }
    
    func clearSearch() {
        searchQuery = ""
        selectedFilter = nil
    }
    
    var hasActiveFilters: Bool {
        !searchQuery.isEmpty || selectedFilter != nil
    }
}
