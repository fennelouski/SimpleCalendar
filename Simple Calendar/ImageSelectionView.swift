//
//  ImageSelectionView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

struct ImageSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @State private var searchResults: [ImageMetadata] = []
    @State private var isSearching = false
    @State private var selectedImageId: String?

    let event: CalendarEvent
    let onImageSelected: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Image for Event")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                HStack(spacing: 16) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("Done") {
                        if let selectedImageId = selectedImageId {
                            onImageSelected(selectedImageId)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImageId == nil)
                }
            }
            .padding()

            Divider()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search for images...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        performSearch()
                    }
                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)

            // Content
            if isSearching {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty && !searchQuery.isEmpty {
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No images found")
                        .foregroundColor(.secondary)
                    Button("Try a different search") {
                        searchQuery = ""
                    }
                    .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty {
                VStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Search for images to add to your event")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("Try searching for '\(suggestedSearchTerm)'")
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                        .onTapGesture {
                            searchQuery = suggestedSearchTerm
                            performSearch()
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 16)
                    ], spacing: 16) {
                        ForEach(searchResults, id: \.id) { metadata in
                            ImageThumbnailView(
                                metadata: metadata,
                                isSelected: selectedImageId == metadata.id
                            )
                            .onTapGesture {
                                selectedImageId = metadata.id
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            // Auto-search with suggested term if no query
            if searchQuery.isEmpty {
                searchQuery = suggestedSearchTerm
                performSearch()
            }
        }
    }

    private var suggestedSearchTerm: String {
        var terms: [String] = []

        // Use event title keywords
        let titleWords = event.title
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        terms.append(contentsOf: titleWords.prefix(2))

        // Add location if available
        if let location = event.location, !location.isEmpty {
            let locationWords = location
                .components(separatedBy: CharacterSet(charactersIn: ", "))
                .filter { !$0.isEmpty }
            terms.append(contentsOf: locationWords.prefix(1))
        }

        return terms.joined(separator: " ")
    }

    private func performSearch() {
        guard !searchQuery.isEmpty else { return }

        isSearching = true
        ImageManager.shared.searchImages(query: searchQuery) { results in
            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false

                // If no exact match was selected and we have results, select the first one
                if self.selectedImageId == nil && !results.isEmpty {
                    self.selectedImageId = results.first?.id
                }
            }
        }
    }
}

struct ImageThumbnailView: View {
    let metadata: ImageMetadata
    let isSelected: Bool

    @State private var thumbnailImage: PlatformImage?

    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                Image(platformImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(
                        ProgressView()
                    )
            }

            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 120, height: 120)
            }

            // Attribution overlay (if enabled in settings)
            if UserDefaults.standard.bool(forKey: "showUnsplashAttribution") {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Photo by \(metadata.author)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .padding(4)
                    }
                }
                .frame(width: 120, height: 120)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        guard let url = URL(string: metadata.thumbnailUrl) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = PlatformImage(data: data) else { return }

            DispatchQueue.main.async {
                self.thumbnailImage = image
            }
        }.resume()
    }
}
